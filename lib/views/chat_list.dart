// chat_list.dart
import 'package:flutter/material.dart';
import 'package:darkord/consts/color.dart';
import 'package:darkord/api/auth_api.dart';
import 'package:darkord/views/profile.dart';
import 'package:darkord/views/add_friend_page.dart';
import 'dart:convert';
import 'package:darkord/views/messaging_page.dart';

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
  List<dynamic> _friendsList = [];
  List<dynamic> _filteredFriendsList = [];
  bool _isLoadingFriends = true;
  Map<String, dynamic> _userDetailsCache = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentIndex = 0; // For bottom navigation

  // Bottom navigation pages
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    if (widget.loginPayload != null) {
      _extractChat(widget.loginPayload!);
    } else if (widget.accessToken.isNotEmpty) {
      // If we already have access token, fetch user data directly
      _fetchUserDataWithToken(widget.accessToken);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchUserDataWithToken(String accessToken) async {
    try {
      // Decode token to get user ID
      final List<String> parts = accessToken.split('.');
      final String payloadBase64 = parts[1];
      String paddedPayload = payloadBase64;
      while (paddedPayload.length % 4 != 0) {
        paddedPayload += '=';
      }
      final String decodedJson = utf8.decode(base64Url.decode(paddedPayload));
      final Map<String, dynamic> tokenData = json.decode(decodedJson);

      final user = await authApi.fetchUsers(accessToken, tokenData['sub']);
      setState(() {
        _userData = {
          'user_id': user.userId,
          'username': user.username,
          'email_addr': user.emailAddr,
          'status': user.status,
          'about_me': user.aboutMe,
          'avatar_url': user.avatarUrl,
        };
      });

      // Fetch friends after user data is loaded
      _fetchFriends(accessToken, user.userId.toString());
    } catch (error) {
      print('Error fetching user data with token: $error');
      setState(() {
        _isLoadingFriends = false;
      });
    }
  }

  void _extractChat(Map<String, dynamic> payload) {
    try {
      final String accessToken = payload['payload']['access_token'];
      final List<String> parts = accessToken.split('.');

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

      authApi.fetchUsers(accessToken, tokenData['sub']).then((user) {
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

        // Fetch friends after user data is loaded
        _fetchFriends(accessToken, user.userId.toString());
      }).catchError((error) {
        print('Error fetching user data: $error');
      });
    } catch (e) {
      print('Error decoding JWT: $e');
    }
  }

  void _fetchFriends(String accessToken, String userId) async {
    try {
      setState(() {
        _isLoadingFriends = true;
      });

      print('Fetching friends for user: $userId with token: $accessToken');

      final friendsResponse = await authApi.fetchChatUsers(accessToken, userId);
      print('Fetch Users Response: $friendsResponse');

      List<dynamic> results = [];

      // Fixed: Handle different response structures
      if (friendsResponse['data'] != null &&
          friendsResponse['data']['payload'] != null &&
          friendsResponse['data']['payload']['results'] is List) {
        results = friendsResponse['data']['payload']['results'];
      }
      // Alternative path: check if response has payload directly
      else if (friendsResponse['payload'] != null &&
          friendsResponse['payload']['results'] is List) {
        results = friendsResponse['payload']['results'];
      }
      // Another alternative: check if response has results directly
      else if (friendsResponse['results'] is List) {
        results = friendsResponse['results'];
      } else {
        print('No results found in response structure');
        print('Available keys: ${friendsResponse.keys}');
        results = [];
      }

      print('Extracted results: $results');
      print('Results length: ${results.length}');

      // Extract all friend user IDs for batch fetching
      final friendUserIds = results
          .map<String>((friend) => friend['user_id'].toString())
          .where((id) => id.isNotEmpty)
          .toList();

      print('Friend user IDs to fetch: $friendUserIds');

      if (friendUserIds.isNotEmpty) {
        // Fetch all user details in a single batch request
        await _fetchUserDetailsBatch(accessToken, friendUserIds);
      }

      setState(() {
        _friendsList = results;
        _filteredFriendsList = results; // Initialize filtered list
        _isLoadingFriends = false;
      });
    } catch (error) {
      print('Error fetching friends: $error');
      setState(() {
        _isLoadingFriends = false;
      });
    }
  }

  Future<void> _fetchUserDetailsBatch(
      String accessToken, List<String> userIds) async {
    try {
      if (userIds.isEmpty) return;

      // Join all user IDs with commas for the batch request
      final userIdsString = userIds.join(',');
      print('Batch fetching user details for IDs: $userIdsString');

      final batchUserDetails = await authApi
          .fetchUsers(accessToken, userIdsString, returnList: true);

      // Process the batch response and update cache
      for (var userData in batchUserDetails) {
        final userId = userData['identity']['user_id'].toString();
        setState(() {
          _userDetailsCache[userId] = {
            'username': userData['identity']['username'] ?? 'Unknown User',
            'avatar_url': userData['identity']['avatar_url'],
            'status': userData['status']['status'],
          };
        });
        print(
            'Cached user details for $userId: ${userData['identity']['username']}');
      }
    } catch (e) {
      print('Error in batch user details fetch: $e');
      // Fallback: try individual requests if batch fails
      await _fetchUserDetailsIndividualFallback(accessToken, userIds);
    }
  }

  Future<void> _fetchUserDetailsIndividualFallback(
      String accessToken, List<String> userIds) async {
    // Fallback to individual requests if batch fails
    for (var userId in userIds) {
      if (!_userDetailsCache.containsKey(userId)) {
        try {
          final userDetails = await authApi.fetchUsers(accessToken, userId);
          setState(() {
            _userDetailsCache[userId] = {
              'username': userDetails.username ?? 'Unknown User',
              'avatar_url': userDetails.avatarUrl,
              'status': userDetails.status,
            };
          });
          print('Fetched user details for $userId: ${userDetails.username}');
        } catch (e) {
          print('Error fetching user details for $userId: $e');
          setState(() {
            _userDetailsCache[userId] = {
              'username': 'User $userId',
              'avatar_url': null,
              'status': null,
            };
          });
        }
      }
    }
  }

  void _filterChats(String query) {
    setState(() {
      _searchQuery = query.toLowerCase().trim();

      if (_searchQuery.isEmpty) {
        _filteredFriendsList = _friendsList;
      } else {
        _filteredFriendsList = _friendsList.where((friend) {
          final friendUserId = friend['user_id'].toString();
          final userDetails = _userDetailsCache[friendUserId];
          final username = userDetails?['username']?.toLowerCase() ?? '';
          final lastMessage =
              _getLastMessage(friend['last_message']).toLowerCase();

          // Search by username or last message
          return username.contains(_searchQuery) ||
              lastMessage.contains(_searchQuery) ||
              friendUserId.contains(_searchQuery);
        }).toList();
      }
    });
  }

  String _formatLastChatTime(dynamic lastChatAt) {
    if (lastChatAt == null || lastChatAt == 0) {
      return '00:00';
    }

    try {
      // Handle the timestamp (assuming it's in milliseconds)
      final timestamp = int.tryParse(lastChatAt.toString());
      if (timestamp == null || timestamp <= 0) {
        return '00:00';
      }

      // Check if it's the invalid timestamp you mentioned
      if (timestamp == 9999999999999) {
        return '00:00';
      }

      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      // If same day, show time, otherwise show date
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.month}/${date.day}';
      }
    } catch (e) {
      print('Error formatting time: $e');
      return '00:00';
    }
  }

  String _getLastMessage(dynamic lastMessage) {
    if (lastMessage == null || lastMessage.toString().isEmpty) {
      return 'No messages yet';
    }
    return lastMessage.toString();
  }

  Widget _buildChatListItem(Map<String, dynamic> friend) {
    print(_userDetailsCache);
    final friendUserId = friend['user_id'].toString();
    final userDetails = _userDetailsCache[friendUserId];
    final username = userDetails?['username'] ?? 'User $friendUserId';
    final avatarUrl = userDetails?['avatar_url'];
    final status = userDetails?['status'];
    final lastMessage = _getLastMessage(friend['last_message']);
    final lastChatTime = _formatLastChatTime(friend['last_chat_at']);

    return ListTile(
      leading: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(
                userId: friendUserId,
                accessToken: widget.accessToken,
              ),
            ),
          );
        },
        child: CircleAvatar(
          backgroundColor: Colors.grey,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
      ),
      title: Text(
        username,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        lastMessage,
        style: const TextStyle(color: Colors.grey),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        lastChatTime,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      onTap: () {
        // Navigate to messaging page when clicking on a friend
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagingPage(
              accessToken: widget.accessToken,
              friendId: friendUserId,
              friendUsername: username,
              friendAvatarUrl: avatarUrl,
              friendStatus: status,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.blue,
          ),
          SizedBox(height: 16),
          Text(
            'Loading chats...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _isLoadingFriends = false; // Manual fallback
              });
            },
            child: Text(
              'Take too long? Tap here',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            color: Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No chats yet',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add friends to start chatting',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            color: Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No results for "$_searchQuery"',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              _filterChats('');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddFriend() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFriendPage(
          accessToken: widget.accessToken,
          userData: _userData,
          currentFriends: _friendsList, // Pass current friends list
        ),
      ),
    ).then((_) {
      // Refresh friends list when returning from AddFriendPage
      if (_userData != null && _userData!['user_id'] != null) {
        print('Refreshing friends list after returning from AddFriendPage');
        _fetchFriends(widget.accessToken, _userData!['user_id'].toString());
      }
    });
  }

  // Community Page (Placeholder)
  Widget _buildCommunityPage() {
    return Scaffold(
      backgroundColor: mainBGColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              color: Colors.grey,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Community',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Community features coming soon',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Settings Page (Placeholder)
  Widget _buildSettingsPage() {
    return Scaffold(
      backgroundColor: mainBGColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              color: Colors.grey,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Settings page coming soon',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Main Messages Page
  Widget _buildMessagesPage() {
    return CustomScrollView(
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
          actions: [
            IconButton(
              icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
              onPressed: (){},
              tooltip: 'Chatbot',
            ),
            // Add Friend button moved to top bar
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white),
              onPressed: _navigateToAddFriend,
              tooltip: 'Add Friend',
            ),
          ],
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        hintText: 'Search messages...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      ),
                      onChanged: _filterChats,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _filterChats('');
                      },
                    ),
                ],
              ),
            ),
          ),
        ),

        // Friends List Section
        if (_isLoadingFriends)
          SliverFillRemaining(
            child: _buildLoadingIndicator(),
          )
        else if (_friendsList.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(),
          )
        else if (_filteredFriendsList.isEmpty && _searchQuery.isNotEmpty)
          SliverFillRemaining(
            child: _buildSearchEmptyState(),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final friend = _filteredFriendsList[index];
                return _buildChatListItem(friend);
              },
              childCount: _filteredFriendsList.length,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainBGColor,
      drawer: _buildUserDrawer(),
      // Remove floating action button since it's moved to app bar
      body: _buildCurrentPage(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildMessagesPage();
      case 1:
        return _buildCommunityPage();
      case 2:
        return _buildSettingsPage();
      default:
        return _buildMessagesPage();
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.blue[400],
        unselectedItemColor: Colors.grey[500],
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        // Add these properties to remove the splash/ripple effect
        enableFeedback: false, // Disables haptic feedback
        // Use custom icon widgets to remove splash effect
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.chat,
                color: _currentIndex == 0 ? Colors.blue[400] : Colors.grey[500],
              ),
            ),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.people,
                color: _currentIndex == 1 ? Colors.blue[400] : Colors.grey[500],
              ),
            ),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.settings,
                color: _currentIndex == 2 ? Colors.blue[400] : Colors.grey[500],
              ),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

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
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                        backgroundImage: _userData?['avatar_url'] != null
                            ? NetworkImage(_userData!['avatar_url'])
                            : null,
                        child: _userData?['avatar_url'] == null
                            ? const Icon(Icons.person,
                                size: 40, color: Colors.white)
                            : null,
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
              setState(() {
                _currentIndex = 2; // Navigate to settings page
              });
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
