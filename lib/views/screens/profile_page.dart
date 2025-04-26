import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutterbookstore/services/auth_service.dart';
import 'package:flutterbookstore/views/screens/login_page.dart';
import 'package:flutterbookstore/views/screens/edit_profile_page.dart';
import 'package:flutterbookstore/views/widgets/main_app_bar_widget.dart';
import 'package:flutterbookstore/views/widgets/menu_tile_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final authService = AuthService();

    setState(() {
      _isLoading = true;
    });

    if (authService.isAuthenticated) {
      final user = await authService.getCurrentUser();
      print("Retrieved user data: $user");
      setState(() {
        _isAuthenticated = true;
        _userData = user;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });

      // Redirect to login after a short delay
      Future.delayed(Duration(milliseconds: 300), () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const LoginPage()));
      });
    }
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();
    await authService.logout();

    setState(() {
      _isAuthenticated = false;
      _userData = null;
      _isLoading = false;
    });

    // Redirect to login
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const MainAppBar(cartValue: 0, chatValue: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        appBar: const MainAppBar(cartValue: 0, chatValue: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 100,
                color: AppColor.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Please sign in to view your profile',
                style: TextStyle(
                  color: AppColor.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // User is authenticated, show profile
    return Scaffold(
      appBar: const MainAppBar(cartValue: 2, chatValue: 2),
      body: ListView(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        children: [
          // Section 1 - Profile Picture - Username - Name
          Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: AppColor.primary,
              gradient: LinearGradient(
                colors: [AppColor.primary, AppColor.primarySoft],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Profile Picture
                Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.grey[300],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      EditProfilePage(userData: _userData),
                            ),
                          );

                          if (result == true) {
                            // Refresh profile data
                            _checkAuthentication();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: AppColor.primary,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Fullname
                Container(
                  margin: const EdgeInsets.only(bottom: 4, top: 14),
                  child: Text(
                    _getFullName(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Email
                Text(
                  _getEmail(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Section 2 - Account Menu
          Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.only(top: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 16),
                  child: Text(
                    'ACCOUNT',
                    style: TextStyle(
                      color: AppColor.secondary.withOpacity(0.5),
                      letterSpacing: 6 / 100,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                MenuTileWidget(
                  onTap: () {},
                  margin: const EdgeInsets.only(top: 10),
                  icon: Icon(
                    Icons.history,
                    color: AppColor.secondary.withOpacity(0.5),
                  ),
                  title: 'Last Seen',
                  subtitle: 'Books you viewed recently',
                ),
                MenuTileWidget(
                  onTap: () {},
                  icon: Icon(
                    Icons.favorite_border,
                    color: AppColor.secondary.withOpacity(0.5),
                  ),
                  title: 'Wishlist',
                  subtitle: 'Books you saved to buy later',
                ),
                MenuTileWidget(
                  onTap: () {},
                  icon: Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColor.secondary.withOpacity(0.5),
                  ),
                  title: 'Orders',
                  subtitle: 'Your order history and status',
                ),
                MenuTileWidget(
                  onTap: () {},
                  icon: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColor.secondary.withOpacity(0.5),
                  ),
                  title: 'Wallet',
                  subtitle: 'Your wallet balance and transactions',
                ),
                MenuTileWidget(
                  onTap: () {},
                  icon: Icon(
                    Icons.location_on_outlined,
                    color: AppColor.secondary.withOpacity(0.5),
                  ),
                  title: 'Addresses',
                  subtitle: 'Your shipping and billing addresses',
                ),
              ],
            ),
          ),

          // Section 3 - Settings
          Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.only(top: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 16),
                  child: Text(
                    'SETTINGS',
                    style: TextStyle(
                      color: AppColor.secondary.withOpacity(0.5),
                      letterSpacing: 6 / 100,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                MenuTileWidget(
                  onTap: () {},
                  margin: const EdgeInsets.only(top: 10),
                  icon: Icon(
                    Icons.language,
                    color: AppColor.secondary.withOpacity(0.5),
                  ),
                  title: 'Languages',
                  subtitle: 'Change app language and preferences',
                ),
                MenuTileWidget(
                  onTap: _handleLogout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  iconBackground: Colors.red[100],
                  title: 'Log Out',
                  titleColor: Colors.red,
                  subtitle: '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get the full name from different possible data structures
  String _getFullName() {
    if (_userData == null) return 'Book Reader';

    // Check if the data might be nested inside a data or user property
    final Map<String, dynamic> userData = _getNestedUserData();

    // Try different possible field name combinations
    final firstName =
        userData['firstName'] ??
        userData['FirstName'] ??
        userData['first_name'] ??
        '';

    final lastName =
        userData['lastName'] ??
        userData['LastName'] ??
        userData['last_name'] ??
        '';

    // If we have a name field directly, use that
    final name = userData['name'] ?? '';

    if (name.isNotEmpty) {
      return name;
    }

    // Otherwise combine first and last name
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }

    return 'Book Reader';
  }

  // Helper method to get the email
  String _getEmail() {
    if (_userData == null) return 'reader@example.com';

    // Check if the data might be nested inside a data or user property
    final Map<String, dynamic> userData = _getNestedUserData();

    return userData['email'] ??
        userData['Email'] ??
        userData['username'] ??
        userData['Username'] ??
        'reader@example.com';
  }

  // Helper method to extract possibly nested user data
  Map<String, dynamic> _getNestedUserData() {
    // If user data is directly available at the root level
    if (_userData == null) return {};

    // If data is nested within 'data' property (common in API responses)
    if (_userData!.containsKey('data') &&
        _userData!['data'] is Map<String, dynamic>) {
      return _userData!['data'] as Map<String, dynamic>;
    }

    // If data is nested within 'user' property
    if (_userData!.containsKey('user') &&
        _userData!['user'] is Map<String, dynamic>) {
      return _userData!['user'] as Map<String, dynamic>;
    }

    // Return the original userData if no nesting found
    return _userData!;
  }
}
