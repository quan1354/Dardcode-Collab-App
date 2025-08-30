// chat_list.dart
import 'package:flutter/material.dart';
import 'package:darkord/consts/color.dart';
import 'package:darkord/api/auth_api.dart';
import 'package:darkord/views/profile.dart';

class ChatList extends StatefulWidget {
  final String accessToken;
  final Map<String, dynamic>? loginPayload; // Add this to receive login data

  const ChatList({
    super.key,
    required this.accessToken,
    this.loginPayload,
  });

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    // Extract user data from login payload
    if (widget.loginPayload != null) {
      _extractUserData(widget.loginPayload!);
    }
  }

  void _extractUserData(Map<String, dynamic> payload) {
    try {
      // Adjust this based on your actual API response structure
      if (payload['payload'] != null &&
          payload['payload']['user_data'] != null) {
        _userData = payload['payload']['user_data'];
      } else if (payload['payload'] != null) {
        _userData = payload['payload'];
      } else {
        _userData = payload;
      }
    } catch (e) {
      print('Error extracting user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainBGColor,
      drawer: _buildUserDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            snap: false,
            elevation: 4,
            shadowColor: Color.lerp(Colors.transparent, Colors.black, 0.3),
            surfaceTintColor: Colors.transparent,
            backgroundColor: mainBGColor,
            title: const Text(
              'Messages',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ),
          // ... rest of your existing ChatList content
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Search messages...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ListTile(
                  leading: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(
                            userId: '10000020',
                            accessToken: widget.accessToken,
                          ),
                        ),
                      );
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                  title: const Text(
                    'Jing Quan',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Hello there!',
                    style: TextStyle(color: Colors.grey),
                  ),
                  trailing: const Text(
                    '1:30',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDrawer() {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.grey[800],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  _userData?['username'] ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userData?['email_addr'] ?? _userData?['email'] ?? 'No email',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text('Profile', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    userId: _userData?['user_id']?.toString() ?? '10000001',
                    accessToken: widget.accessToken,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title:
                const Text('Settings', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings page
            },
          ),
          const Divider(color: Colors.grey),

          // Spacer to push buttons to the bottom
          const Spacer(),

          // Red Logout Button
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Implement logout functionality
                //_logout();
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label:
                  const Text('Logout', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),

          // Yellow Reset Password Button
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Implement reset password functionality
                //_resetPassword();
              },
              icon: const Icon(Icons.lock_reset, color: Colors.black),
              label: const Text('Reset Password',
                  style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),

          // Add some bottom padding
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is String) {
      return date;
    }
    return 'Unknown date';
  }
}
