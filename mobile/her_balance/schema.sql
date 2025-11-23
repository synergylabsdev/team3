-- Enable UUID extension for unique identifiers
create extension if not exists "uuid-ossp";

-------------------------------------------------------------------------
-- ENUMS (Fixed Types defined in SoW)
-------------------------------------------------------------------------

-- The 4 key phases mentioned in the SoW
create type app_cycle_phase as enum (
  'root',    -- Days 1-5 (Menstruation/New Moon)
  'bloom',   -- Days 6-13 (Follicular/Waxing Moon)
  'shine',   -- Days 14-16 (Ovulation/Full Moon)
  'harvest'  -- Days 17-28 (Luteal/Waning Moon)
);

-- Meal slots for the planner
create type app_meal_type as enum ('breakfast', 'lunch', 'dinner', 'snack');

-- Role management (Simple boolean in profile is often enough for MVP, 
-- but this allows future expansion)
create type app_user_role as enum ('user', 'admin');

-------------------------------------------------------------------------
-- 1. PROFILES & SETTINGS
-- Links to auth.users. Stores preferences, subscription, and bio.
-------------------------------------------------------------------------
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  email text,
  
  -- Account & Role
  role app_user_role default 'user',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  -- Subscription (RevenueCat integration)
  is_premium boolean default false,
  subscription_status text, -- e.g., 'active', 'expired', 'trial'
  subscription_plan_id text, -- RevenueCat Plan ID

  -- Cycle Settings (Page 6)
  avg_cycle_length int default 28,
  avg_period_length int default 7,
  last_period_start date,
  lunar_sync_enabled boolean default false, -- Toggles between manual calc and ipgeolocation.io

  -- Preferences (Page 9)
  measurement_unit text default 'US', -- 'US' or 'metric'
  show_bible_verses boolean default false,
  
  -- Notifications (JSONB allows flexible toggle of categories without migration)
  -- Structure: { "phase_change": true, "meal_reminders": true, "log_reminders": true }
  notification_preferences jsonb default '{"phase_change": true, "meal_reminders": true, "log_reminders": true}'::jsonb
);

-- Enable RLS
alter table public.profiles enable row level security;

-------------------------------------------------------------------------
-- 2. CYCLE HISTORY
-- Stores historical period dates to calculate predictions.
-------------------------------------------------------------------------
create table public.cycles (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  
  start_date date not null,
  end_date date, -- Nullable until the period ends
  
  -- Cached calculation of length for analytics
  cycle_length_days int, 
  
  created_at timestamptz default now()
);

alter table public.cycles enable row level security;

-------------------------------------------------------------------------
-- 3. RECIPES
-- Handles both System (Admin) recipes and User imported recipes.
-------------------------------------------------------------------------
create table public.recipes (
  id uuid default uuid_generate_v4() primary key,
  
  -- Ownership: If created_by is NULL, it's a System Recipe (Admin). 
  -- If populated, it is a user's private import.
  created_by uuid references public.profiles(id) on delete cascade,
  
  title text not null,
  description text,
  image_url text, -- Stored in Supabase Storage CDN
  source_url text, -- Original URL (NYT Cooking, Pinterest, etc.)
  
  -- Content
  servings int default 1,
  prep_time_minutes int,
  instructions text, -- Rich text or HTML
  
  -- Classification
  -- Array because a recipe might be good for multiple phases
  phase_tags app_cycle_phase[], 
  
  -- Ingredients (JSONB)
  -- MVP decision: Storing as JSON allows flexibility for AI imports.
  -- Structure: [{ "name": "Quinoa", "amount": 1, "unit": "cup", "category": "Grains" }]
  ingredients jsonb not null default '[]'::jsonb,

  -- Nutrition (Edamam Data)
  -- Structure: { "calories": 500, "protein": 20, "carbs": 50, "fat": 15, "fiber": 5 }
  nutrition_summary jsonb default '{}'::jsonb,

  -- AI Metadata (Page 8)
  ai_confidence_score float, -- e.g., 0.85
  ai_suggestions text, -- e.g., "Add flaxseed for Shine phase"
  
  is_public boolean default false, -- Admin recipes are public
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.recipes enable row level security;

-- Recipe Favorites (Many-to-Many)
create table public.favorite_recipes (
  user_id uuid references public.profiles(id) on delete cascade,
  recipe_id uuid references public.recipes(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, recipe_id)
);

alter table public.favorite_recipes enable row level security;

-------------------------------------------------------------------------
-- 4. MEAL PLANNING
-- Connecting recipes to calendar slots.
-------------------------------------------------------------------------
create table public.meal_plans (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  recipe_id uuid references public.recipes(id) on delete cascade not null,
  
  planned_date date not null,
  meal_type app_meal_type not null,
  
  is_completed boolean default false
);

alter table public.meal_plans enable row level security;

-------------------------------------------------------------------------
-- 5. GROCERY LIST
-- Aggregated ingredients.
-------------------------------------------------------------------------
create table public.grocery_items (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  
  name text not null, -- e.g., "Onions"
  quantity float, -- e.g., 3.0 (Deduped logic happens in app code before insert)
  unit text,
  category text, -- e.g., "Produce"
  
  is_checked boolean default false,
  created_at timestamptz default now()
);

alter table public.grocery_items enable row level security;

-------------------------------------------------------------------------
-- 6. DAILY LOGS & TRACKING
-- Steps, Workouts, Symptoms, and Phase History.
-------------------------------------------------------------------------
create table public.daily_logs (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  log_date date not null,
  
  -- Phase Tracking
  -- We store the phase *for that day* so analytics remain accurate 
  -- even if logic changes later.
  recorded_phase app_cycle_phase, 
  
  -- Activity (Page 8)
  step_count int default 0,
  workout_completed boolean default false,
  workout_notes text,
  
  -- Symptoms (Page 7)
  -- Storing as array of text strings for simplicity given the checkboxes.
  -- Valid values: 'Bloating', 'Insomnia', 'Cramps', etc.
  symptoms text[], 
  
  -- Daily Nutrition Totals (Aggregated from logged meals)
  total_calories float,
  total_protein float,
  total_fat float,
  total_carbs float,
  
  unique(user_id, log_date)
);

alter table public.daily_logs enable row level security;

-------------------------------------------------------------------------
-- 7. INSPIRATIONAL CONTENT (Admin Managed)
-- Bible verses and wellness tips.
-------------------------------------------------------------------------
create table public.inspirational_content (
  id uuid default uuid_generate_v4() primary key,
  
  content_text text not null,
  source_reference text, -- e.g., "Psalm 139:14"
  
  content_type text check (content_type in ('bible_verse', 'wellness_tip')),
  
  -- Targeted Phase (Optional - content can be specific to Root, etc.)
  target_phase app_cycle_phase,
  
  is_active boolean default true,
  created_at timestamptz default now()
);

-- RLS: Public read, Admin write
alter table public.inspirational_content enable row level security;

-------------------------------------------------------------------------
-- RLS POLICIES (Security)
-------------------------------------------------------------------------

-- PROFILES
create policy "Users can view own profile" on profiles 
  for select using (auth.uid() = id);
create policy "Users can update own profile" on profiles 
  for update using (auth.uid() = id);

-- RECIPES
create policy "Users can view public recipes" on recipes 
  for select using (is_public = true);
create policy "Users can view own private recipes" on recipes 
  for select using (auth.uid() = created_by);
create policy "Users can create/edit own recipes" on recipes 
  for all using (auth.uid() = created_by);
-- (Admin write access would be handled by a service role or specific admin policy)

-- MEAL PLANS, GROCERIES, CYCLES, DAILY LOGS, FAVORITES
-- Generic policy pattern for user-owned data
create policy "Users manage own meal plans" on meal_plans 
  for all using (auth.uid() = user_id);

create policy "Users manage own grocery items" on grocery_items 
  for all using (auth.uid() = user_id);

create policy "Users manage own cycles" on cycles 
  for all using (auth.uid() = user_id);

create policy "Users manage own logs" on daily_logs 
  for all using (auth.uid() = user_id);

create policy "Users manage own favorites" on favorite_recipes 
  for all using (auth.uid() = user_id);

-- INSPIRATIONAL CONTENT
create policy "Everyone can read active content" on inspirational_content
  for select using (is_active = true);

-------------------------------------------------------------------------
-- TRIGGERS & FUNCTIONS
-------------------------------------------------------------------------

-- 1. Auto-create profile on User Signup
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 2. Auto-update 'updated_at' columns
create or replace function update_updated_at_column()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger update_profiles_updated_at
before update on public.profiles
for each row execute procedure update_updated_at_column();

create trigger update_recipes_updated_at
before update on public.recipes
for each row execute procedure update_updated_at_column();