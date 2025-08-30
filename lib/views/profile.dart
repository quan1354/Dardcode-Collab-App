import 'package:flutter/material.dart';
import 'package:darkord/consts/color.dart';
import 'package:darkord/models/user.dart';
import 'package:darkord/api/auth_api.dart';
import 'package:provider/provider.dart';
import 'package:darkord/api/auth_provider.dart'; // You'll need to create this

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String accessToken;

  const UserProfilePage({super.key, required this.userId, required this.accessToken});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<User> _futureUser;

  @override
  void initState() {
    super.initState();
    _futureUser = _fetchUserData();
  }

  Future<User> _fetchUserData() async {
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final accessToken = authProvider.accessToken;
    // print('Access Token: $accessToken');
    
    // if (widget.accessToken == null) {
    //   throw Exception('No access token available. Please login first.');
    // }
    
    // You'll need to make fetchUser available through AuthProvider or access AuthApi
    final authApi = AuthApi(); // This should be the same instance
    return await authApi.fetchUser(widget.accessToken, widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainBGColor,
      appBar: AppBar(
        backgroundColor: mainBGColor,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<User>(
        future: _futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'No user data found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile picture with status indicator
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[800]!,
                          width: 2,
                        ),
                        image: user.avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(user.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : const DecorationImage(
                                image: AssetImage('assets/default_avatar.png'),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    // Status indicator
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: user.status == 'online' ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: mainBGColor,
                          width: 3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Username
                Text(
                  user.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                // Email section
                _buildProfileSection(
                  icon: Icons.email,
                  title: 'Email',
                  value: user.emailAddr,
                  showCopy: true,
                ),
                const SizedBox(height: 16),
                // User ID section
                _buildProfileSection(
                  icon: Icons.person,
                  title: 'User ID',
                  value: 'ID: ${user.userId}',
                  showCopy: false,
                ),
                const SizedBox(height: 32),
                // About me section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'About Me',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.aboutMe,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection({
    required IconData icon,
    required String title,
    required String value,
    required bool showCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (showCopy)
            IconButton(
              icon: const Icon(Icons.content_copy, color: Colors.grey),
              onPressed: () {
                // Copy to clipboard functionality
              },
            ),
        ],
      ),
    );
  }
}