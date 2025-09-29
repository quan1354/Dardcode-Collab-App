import 'package:flutter/material.dart';
import 'package:darkord/consts/color.dart';
import 'package:darkord/models/user.dart';
import 'package:darkord/api/auth_api.dart';
import 'package:provider/provider.dart';
import 'package:darkord/api/auth_provider.dart'; // You'll need to create this

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String accessToken;
  

  const UserProfilePage(
      {super.key, required this.userId, required this.accessToken});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<User> _futureUser;
  final authApi = AuthApi();

  @override
  void initState() {
    super.initState();
    _futureUser = _fetchUserData();
    print(_futureUser);
  }

  Future<User> _fetchUserData() async {
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
                            : null, // Set to null when no avatar
                        color: user.avatarUrl == null
                            ? Colors.grey
                            : null, // Background color for fallback
                      ),
                      child: user.avatarUrl == null
                          ? const Icon(Icons.person,
                              size: 70, color: Colors.white)
                          : null,
                    ),
                    // Status indicator
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: user.status == 'online'
                            ? Colors.green
                            : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: mainBGColor,
                          width: 3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Username
                Text(
                  user.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Edit Profile button
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement edit profile functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Edit Profile'),
                      const SizedBox(width: 4),
                      Icon(Icons.edit, 
                          size: 16, 
                          color: const Color.fromARGB(255, 54, 188, 255)), // Green pencil icon
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // const Icon(Icons.info, color: Colors.grey),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About Me',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Text(
                            //   user.aboutMe,
                            //   style: const TextStyle(
                            //     color: Colors.white,
                            //     fontSize: 16,
                            //   ),
                            // ),
                            Text(
                              'å¸ææ¨å¤©å¤©é½ä¼æ³æ~~',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, 
                            color: Colors.grey, size: 16),
                        onPressed: () {
                          // TODO: Implement edit about me functionality
                        },
                      ),
                    ],
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