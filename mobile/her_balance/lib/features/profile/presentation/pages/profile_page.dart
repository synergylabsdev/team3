import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/supabase_client.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/profile.dart';
import 'edit_profile_page.dart';
import '../../../auth/presentation/pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileRepository = ProfileRepository();
  Profile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _profileRepository.getCurrentUserProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseClient.auth.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        print('Error logging out: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Error logging out')));
        }
      }
    }
  }

  Future<void> _toggleBibleVerses(bool value) async {
    try {
      await _profileRepository.updateProfile({'show_bible_verses': value});
      setState(() {
        if (_profile != null) {
          _profile = Profile(
            id: _profile!.id,
            email: _profile!.email,
            role: _profile!.role,
            createdAt: _profile!.createdAt,
            updatedAt: _profile!.updatedAt,
            isPremium: _profile!.isPremium,
            subscriptionStatus: _profile!.subscriptionStatus,
            subscriptionPlanId: _profile!.subscriptionPlanId,
            avgCycleLength: _profile!.avgCycleLength,
            avgPeriodLength: _profile!.avgPeriodLength,
            lastPeriodStart: _profile!.lastPeriodStart,
            lunarSyncEnabled: _profile!.lunarSyncEnabled,
            measurementUnit: _profile!.measurementUnit,
            showBibleVerses: value,
            notificationPreferences: _profile!.notificationPreferences,
            dailyStepGoal: _profile!.dailyStepGoal,
            name: _profile!.name,
          );
        }
      });
    } catch (e) {
      print('Error updating bible verses setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final userName =
        _profile?.name ?? _profile?.email?.split('@').first ?? 'User';
    final userEmail = _profile?.email ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Profile Picture
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withOpacity(0.2),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name and Email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Edit Icon
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfilePage(),
                          ),
                        ).then((_) => _loadProfile());
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // First Menu Section
              _buildMenuSection(
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'My Cycle',
                    onTap: () {
                      // TODO: Navigate to cycle settings
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.credit_card_outlined,
                    title: 'My Subscription',
                    onTap: () {
                      // TODO: Navigate to subscription
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.trending_up_outlined,
                    title: 'My Nutrition Goals',
                    onTap: () {
                      // TODO: Navigate to nutrition goals
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Measurement Units',
                    onTap: () {
                      // TODO: Navigate to measurement units
                    },
                    showBottomBorder: false,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Second Menu Section
              _buildMenuSection(
                children: [
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Request a Feature',
                    onTap: () {
                      // TODO: Navigate to feature request
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    title: 'FAQ',
                    onTap: () {
                      // TODO: Navigate to FAQ
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    title: 'Terms of Use',
                    onTap: () {
                      // TODO: Navigate to terms
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Privacy Policy',
                    onTap: () {
                      // TODO: Navigate to privacy policy
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.email_outlined,
                    title: 'Newsletter',
                    onTap: () {
                      // TODO: Navigate to newsletter
                    },
                  ),
                  _buildMenuItemWithToggle(
                    icon: Icons.help_outline,
                    title: 'Weekly Bible verse',
                    value: _profile?.showBibleVerses ?? false,
                    onChanged: _toggleBibleVerses,
                  ),
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    textColor: Colors.red,
                    onTap: _handleLogout,
                    showBottomBorder: false,
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    bool showBottomBorder = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: showBottomBorder
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.backgroundColor, width: 1),
                ),
              )
            : null,
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppTheme.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: textColor ?? AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppTheme.inactiveColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemWithToggle({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.backgroundColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppTheme.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}
