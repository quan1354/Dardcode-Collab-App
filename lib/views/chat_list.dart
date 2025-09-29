// chat_list.dart
import 'package:flutter/material.dart';
import 'package:darkord/consts/color.dart';
import 'package:darkord/api/auth_api.dart';
import 'package:darkord/views/profile.dart';
import 'package:darkord/views/add_friend_page.dart'; // Add this import
import 'dart:convert';

class ChatList extends StatefulWidget {
  final String accessToken;
  final Map<String, dynamic>? loginPayload;

  const ChatList({
    super.key,
    required this.accessToken,
    this.loginPayload,
  });

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  String _currentStatus = 'online';
  Map<String, dynamic>? _userData;
  final authApi = AuthApi();

  @override
  void initState() {
    super.initState();
    if (widget.loginPayload != null) {
      _extractUserData(widget.loginPayload!);
    }
  }

  void _extractUserData(Map<String, dynamic> payload) {
    try {
      final String accessToken = payload['payload']['access_token'];
      final List<String> parts = accessToken.split('.');

      if (parts.length != 3) {
        print('Invalid JWT token');
        return;
      }

      final String payloadBase64 = parts[1];
      String paddedPayload = payloadBase64;
      while (paddedPayload.length % 4 != 0) {
        paddedPayload += '=';
      }

      final String decodedJson = utf8.decode(base64Url.decode(paddedPayload));
      final Map<String, dynamic> tokenData = json.decode(decodedJson);

      print('\nDecoded JWT Payload:');
      print('Subject (sub): ${tokenData['sub']}');
      print('Expiration (exp): ${tokenData['exp']}');
      print('Not Before (nbf): ${tokenData['nbf']}');
      print('JWT ID (jti): ${tokenData['jti']}');
      print('Family: ${tokenData['family']}');
      print('Scope: ${tokenData['scope']}');

      print(tokenData);

      authApi.fetchUser(accessToken, tokenData['sub']).then((user) {
        setState(() {
          _userData = {
            'user_id': user.userId,
            'username': user.username,
            'email_addr': user.emailAddr,
            'status': user.status,
            'about_me': user.aboutMe,
            'avatar_url': user.avatarUrl,
          };
          print(_userData);
        });
      }).catchError((error) {
        print('Error fetching user data: $error');
      });
    } catch (e) {
      print('Error decoding JWT: $e');
    }
  }

  void _navigateToAddFriend() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFriendPage(
          accessToken: widget.accessToken,
          userData: _userData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainBGColor,
      drawer: _buildUserDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddFriend,
        backgroundColor: Colors.blue[900], // Dark blue color
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 30),
      ),
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

  // ... rest of your existing _buildUserDrawer() and other methods remain the same
  Widget _buildUserDrawer() {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: Column(
        children: [
          Container(
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16.0, 48.0, 16.0, 18.0),
              color: Colors.grey[800],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                        child:
                            Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userData?['username'] ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'UID: ${_userData?['user_id']?.toString() ?? '1234'}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.email,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _userData?['email_addr'] ??
                                        _userData?['email'] ??
                                        'No email',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: DropdownButton<String>(
                      value: _currentStatus,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white),
                      alignment: AlignmentDirectional.bottomCenter,
                      items: [
                        DropdownMenuItem(
                          value: 'online',
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('Online'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'offline',
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('Offline'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _currentStatus = newValue!;
                        });
                      },
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text('Profile', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    userId: _userData?['user_id']?.toString() ?? '10000020',
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
            },
          ),
          const Divider(color: Colors.grey),
          Expanded(
            child: Container(),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
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
                const SizedBox(height: 8.0),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Logout',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
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