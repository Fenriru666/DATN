import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:datn/core/providers/theme_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/features/customer/screens/account/address_book_screen.dart';
import 'package:datn/core/services/translation_service.dart';
import 'package:datn/features/auth/screens/root_dispatcher.dart';
import 'package:datn/l10n/generated/app_localizations.dart';
import 'package:datn/features/auth/services/auth_service.dart';
import 'package:datn/core/models/user_model.dart';
import 'package:datn/core/utils/tier_calculator.dart';
import 'package:datn/features/customer/screens/account/rewards_screen.dart';
import 'package:datn/features/customer/screens/account/referral_screen.dart';
import 'package:datn/features/customer/screens/account/saved_places_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final user = Supabase.instance.client.auth.currentUser;

  @override
  Widget build(BuildContext context) {
    final isDarkGlobally = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 30,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFE724C),
                            width: 3,
                          ),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://ui-avatars.com/api/?name=User&background=0D8ABC&color=fff',
                            ), // Placeholder
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showEditProfileDialog,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFE724C),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.userMetadata?['name'] ?? 'User Name',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDarkGlobally ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'user@example.com',
                    style: TextStyle(
                      color: isDarkGlobally ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Loyalty Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FutureBuilder<UserModel?>(
                future: AuthService().getCurrentUser(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final userModel = snapshot.data!;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RewardsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getTierColors(userModel.tier),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getTierColors(
                              userModel.tier,
                            ).first.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${userModel.tier} Member',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    userModel.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${userModel.loyaltyPoints} Points',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Nhấn để xem Cửa hàng Đổi thưởng',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Settings List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _SettingSection(
                    title: AppLocalizations.of(context)!.sectionGeneral,
                    children: [
                      _SettingItem(
                        icon: Icons.person_outline,
                        label: AppLocalizations.of(
                          context,
                        )!.profilePersonalInfo,
                        onTap: _showEditProfileDialog,
                      ),
                      _SettingItem(
                        icon: Icons.credit_card,
                        label: AppLocalizations.of(
                          context,
                        )!.profilePaymentMethods,
                        onTap: () {},
                      ),
                      _SettingItem(
                        icon: Icons.location_on_outlined,
                        label: AppLocalizations.of(
                          context,
                        )!.profileSavedAddresses,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddressBookScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingItem(
                        icon: Icons.home_work_outlined,
                        label: AppLocalizations.of(context)!.profileFavoritePlaces,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SavedPlacesScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingItem(
                        icon: Icons.notifications_none,
                        label: AppLocalizations.of(
                          context,
                        )!.profileNotifications,
                        onTap: () {},
                      ),
                      _SettingItem(
                        icon: Icons.language,
                        label: AppLocalizations.of(context)!.profileLanguage,
                        onTap: _showLanguageDialog,
                      ),
                      _SettingItem(
                        icon: Icons.card_giftcard,
                        label: AppLocalizations.of(context)!.profileInviteFriends,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReferralScreen(),
                            ),
                          );
                        },
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final themeMode = ref.watch(themeProvider);
                          final isDark = themeMode == ThemeMode.dark;
                          return SwitchListTile(
                            value: isDark,
                            onChanged: (val) {
                              ref.read(themeProvider.notifier).toggleTheme(val);
                            },
                            title: Text(
                              AppLocalizations.of(context)!.profileDarkMode,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.dark_mode,
                                color: isDark ? Colors.white70 : Colors.grey[700],
                                size: 20,
                              ),
                            ),
                            activeThumbColor: const Color(0xFFFE724C),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SettingSection(
                    title: AppLocalizations.of(context)!.sectionSupport,
                    children: [
                      _SettingItem(
                        icon: Icons.help_outline,
                        label: AppLocalizations.of(context)!.profileHelpCenter,
                        onTap: () {},
                      ),
                      _SettingItem(
                        icon: Icons.info_outline,
                        label: AppLocalizations.of(context)!.profileAboutUs,
                        onTap: () {},
                      ),
                      _SettingItem(
                        icon: Icons.star_border,
                        label: AppLocalizations.of(context)!.profileRateApp,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showLogoutConfirmation(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).cardColor,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.profileLogOut,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: user?.userMetadata?['name'] as String?);
    // Determine phone from firestore would be ideal, but for now just name

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.dialogEditProfileTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.dialogDisplayNameLabel,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.dialogCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (user != null) {
                  // Update Supabase Auth metadata
                  await Supabase.instance.client.auth.updateUser(
                    UserAttributes(data: {'name': nameController.text})
                  );
                  // Update Supabase Database
                  await Supabase.instance.client
                      .from('users')
                      .update({'name': nameController.text})
                      .eq('id', user!.id);
                }

                if (mounted) {
                  setState(() {}); // Refresh UI
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              } catch (e) {
                // Handle error
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE724C),
            ),
            child: Text(
              AppLocalizations.of(context)!.dialogSave,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.dialogLogOutTitle),
        content: Text(AppLocalizations.of(context)!.dialogLogOutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.dialogCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                // Restart app flow from RootDispatcher using the screen's context
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RootDispatcher()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              AppLocalizations.of(context)!.profileLogOut,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.profileLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<String>(
              groupValue: TranslationService().locale.languageCode,
              onChanged: (value) {
                if (value != null) {
                  TranslationService().changeLanguage(value);
                  Navigator.pop(context);
                }
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text("English"),
                    value: 'en',
                    // groupValue and onChanged are handled by RadioGroup
                  ),
                  RadioListTile<String>(
                    title: const Text("Tiếng Việt"),
                    value: 'vi',
                    // groupValue and onChanged are handled by RadioGroup
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getTierColors(String tier) {
    switch (tier) {
      case TierCalculator.platinum:
        return [
          const Color(0xFF3E4153),
          const Color(0xFF191A23),
        ]; // Dark Metallic
      case TierCalculator.gold:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)]; // Gold
      case TierCalculator.silver:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)]; // Silver
      case TierCalculator.bronze:
      default:
        return [const Color(0xFFCD7F32), const Color(0xFFA0522D)]; // Bronze
    }
  }
}

class _SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final widget = entry.value;
              return Column(
                children: [
                  widget,
                  if (index != children.length - 1)
                    const Divider(height: 1, indent: 60),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkItem = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkItem ? Colors.grey[800] : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDarkItem ? Colors.grey[300] : Colors.grey[700], size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
