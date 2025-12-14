import 'package:flutter/material.dart';
import 'package:darkord/consts/app_constants.dart';
import 'package:darkord/api/api_service.dart';
import 'package:darkord/views/profile.dart';
import 'package:darkord/views/add_friend_page.dart';
import 'package:darkord/views/messaging_page.dart';
import 'package:darkord/views/login.dart';
import 'package:darkord/utils/token_utils.dart';
import 'package:darkord/widgets/common_widgets.dart';
import 'dart:convert';
class ChatList extends StatefulWidget {
  final String accessToken;
  final Map<String, dynamic>? loginPayload;
  final ApiService apiService;
  const ChatList({
    super.key,
    required this.accessToken,
    this.loginPayload,
    required this.apiService,
  });
  @override
  State<ChatList> createState() => _ChatListState();
}
class _ChatListState extends State<ChatList> {
  String _currentStatus = 'online';
  Map<String, dynamic>? _userData;
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
    _fetchUserDataWithToken(widget.accessToken);
    widget.apiService.debugConnectionStatus();
    widget.apiService.addMessageHandler(_handleWebSocketMessage);
  }
  @override
  void dispose() {
    _searchController.dispose();
    widget.apiService.removeMessageHandler(_handleWebSocketMessage);
    super.dispose();
  }
// ===================== COMMON FUNCTIONS =====================
  void _fetchUserDataWithToken(String accessToken) async {
    try {
      // Decode token to get user ID using utility
      final userId = TokenUtils.getUserIdFromToken(accessToken);
      if (userId == null) {
        throw Exception('Could not extract user ID from token');
      }
      final user = await widget.apiService.fetchUsers(accessToken, userId);
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
      _fetchCurrentUserFriends(accessToken, user.userId.toString());
    } catch (error) {
      print('Error fetching user data with token: $error');
      setState(() {
        _isLoadingFriends = false;
      });
    }
  }
  void _handleWebSocketMessage(dynamic message) {
    // Handle global WebSocket messages
    print('Global message: $message');
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
  void _navigateToAddFriend() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFriendPage(
            accessToken: widget.accessToken,
            userData: _userData,
            currentFriends: _friendsList, // Pass current friends list
            apiService: widget.apiService),
      ),
    ).then((_) {
      // Refresh friends list when returning from AddFriendPage
      if (_userData != null && _userData!['user_id'] != null) {
        print('Refreshing friends list after returning from AddFriendPage');
        _fetchCurrentUserFriends(
            widget.accessToken, _userData!['user_id'].toString());
      }
    });
  }
// ===================== LOAD CURRENT USER FRIENDS =====================
  void _fetchCurrentUserFriends(String accessToken, String userId) async {
    try {
      setState(() {
        _isLoadingFriends = true;
      });
      print('Fetching friends for user: $userId with token: $accessToken');
      final friendsResponse =
          await widget.apiService.fetchChatUsers(accessToken, userId);
      print('Fetch Users Response: $friendsResponse');
      List<dynamic> results = [];
      // Fixed: Handle different response structures
      if (friendsResponse['data']['payload']['results'] is List) {
        results = friendsResponse['data']['payload']['results'];
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
      final batchUserDetails = await widget.apiService
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
          final userDetails =
              await widget.apiService.fetchUsers(accessToken, userId);
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
// ==================== WIDGETS PARTS =====================
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LoadingIndicator(message: 'Loading chats...'),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _isLoadingFriends = false;
              });
            },
            child: const Text(
              'Take too long? Tap here',
              style: TextStyle(color: Colors.blue, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.chat_bubble_outline,
      title: 'No chats yet',
      subtitle: 'Add friends to start chatting',
    );
  }
  Widget _buildSearchEmptyState() {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No results for "$_searchQuery"',
      subtitle: 'Try searching with different keywords',
      action: ElevatedButton(
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
    );
  }
  Widget _buildCommunityPage() {
    return Scaffold(
      backgroundColor: AppConstants.mainBGColor,
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
  Widget _buildSettingsPage() {
    return Scaffold(
      backgroundColor: AppConstants.mainBGColor,
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
          backgroundColor: AppConstants.mainBGColor,
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
              onPressed: () {},
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
              height: AppConstants.buttonHeight,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius:
                    BorderRadius.circular(AppConstants.defaultBorderRadius),
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
                        _buildStatusMenuItem('online', Colors.green, 'Online'),
                        _buildStatusMenuItem('idle', Colors.orange, 'Idle'),
                        _buildStatusMenuItem(
                            'do_not_disturb', Colors.red, 'Do Not Disturb'),
                        _buildStatusMenuItem(
                            'invisible', Colors.grey, 'Invisible'),
                      ],
                      onChanged: (String? newValue) async {
                        if (newValue != null && newValue != _currentStatus) {
                          await _updateUserStatus(newValue);
                        }
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
              ).then((_) {
                // Refresh user data when returning from profile page
                print('Refreshing user data after returning from profile');
                _fetchUserDataWithToken(widget.accessToken);
              });
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
                  onPressed: () async {
                    print('Logging out user');
                    try {
                      // Add 'await' and make the callback 'async'
                      final response = await widget.apiService
                          .logoutUser(widget.accessToken);
                      if (response['success'] == true) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => LoginForm()),
                          (route) => false,
                        );
                      } else {
                        // Optional: Handle unsuccessful logout
                        print('Logout failed: ${response['message']}');
                      }
                    } catch (e) {
                      // Handle any errors that occur during logout
                      print('Error during logout: $e');
                      // Optional: Show error message to user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Logout failed: $e')),
                      );
                    }
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
  Widget _buildChatListItem(Map<String, dynamic> friend) {
    final friendUserId = friend['user_id'].toString();
    final userDetails = _userDetailsCache[friendUserId];
    final username = userDetails?['username'] ?? 'User $friendUserId';
    final avatarUrl = userDetails?['avatar_url'];
    final status = userDetails?['status'];
    final unreadCount = friend['unread_count'] ?? 0;
    final isOnline = status?.toLowerCase() == 'online';
    final isPinned = friend['is_pinned'] ?? false;
    return ListTile(
      tileColor: isPinned ? Colors.grey[850] : null,
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
          ).then((_) {
            // Refresh friend details when returning from their profile
            print('Refreshing friend details after viewing profile');
            if (_userData != null && _userData!['user_id'] != null) {
              _fetchCurrentUserFriends(
                widget.accessToken,
                _userData!['user_id'].toString(),
              );
            }
          });
        },
        child: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            // Status indicator with Discord-style icons - Quick Win 4
            if (status != null && status.toLowerCase() != 'invisible')
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppConstants.mainBGColor,
                      width: 2,
                    ),
                  ),
                  child: _buildStatusIcon(status, _getStatusColor(status), size: 14),
                ),
              ),
          ],
        ),
      ),
      title: Row(
        children: [
          // Pin icon for pinned chats - Quick Win 8
          if (isPinned)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.push_pin,
                size: 14,
                color: Colors.grey[400],
              ),
            ),
          Expanded(
            child: Text(
              username,
              style: TextStyle(
                color: Colors.white,
                fontWeight:
                    unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      subtitle: _buildSubtitle(friend, isOnline, status),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatLastChatTime(friend['last_chat_at']),
            style: TextStyle(
              color: unreadCount > 0 ? Colors.green[400] : Colors.grey,
              fontSize: 12,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          // Unread message counter - Quick Win 1
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () async {
        // Navigate to messaging page with all required parameters
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagingPage(
              accessToken: widget.accessToken,
              friendId: friendUserId,
              friendUsername: username,
              friendAvatarUrl: avatarUrl,
              friendStatus: status ?? 'invisible',
              apiService: widget.apiService,
            ),
          ),
        );
        // Refresh chat list when returning from messaging page
        if (_userData != null && _userData!['user_id'] != null) {
          print('Refreshing chat list after returning from messaging');
          _fetchCurrentUserFriends(
            widget.accessToken,
            _userData!['user_id'].toString(),
          );
        }
      },
      onLongPress: () => _showChatOptions(friend, friendUserId, username),
    );
  }
  // Build subtitle with typing indicator or last message - Quick Win 3 & 5
  Widget _buildSubtitle(
      Map<String, dynamic> friend, bool isOnline, String? status) {
    final isTyping = friend['is_typing'] ?? false;
    // Handle different last_message structures
    String? lastMessage;
    final lastMessageData = friend['last_message'];
    if (lastMessageData != null) {
      final messageContent = lastMessageData['message'];
      if (messageContent is Map<String, dynamic>) {
        // If message is an object with 'text' field
        lastMessage = messageContent['text'];
      } else if (messageContent is String) {
        // If message is a direct string (e.g., "deleted")
        lastMessage = messageContent;
      }
    }
    final unreadCount = friend['unread_count'] ?? 0;
    final lastSeen = friend['last_seen'];
    if (isTyping) {
      return Row(
        children: [
          Text(
            'typing',
            style: TextStyle(
              color: Colors.green[400],
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 4),
          _buildTypingDots(),
        ],
      );
    }
    if (!isOnline && lastSeen != null) {
      final lastSeenText = _formatLastSeen(lastSeen);
      if (lastSeenText.isNotEmpty) {
        return Text(
          lastSeenText,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
    }
    return Text(
      _getLastMessage(lastMessage),
      style: TextStyle(
        color: unreadCount > 0 ? Colors.white70 : Colors.grey,
        fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
  // Animated typing dots - Quick Win 3
  Widget _buildTypingDots() {
    return Row(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.green[400],
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
  // Format last seen time - Quick Win 5
  String _formatLastSeen(dynamic lastSeen) {
    if (lastSeen == null) return '';
    try {
      DateTime lastSeenTime;
      if (lastSeen is int) {
        lastSeenTime = DateTime.fromMillisecondsSinceEpoch(lastSeen);
      } else if (lastSeen is String) {
        lastSeenTime = DateTime.parse(lastSeen);
      } else {
        return '';
      }
      final now = DateTime.now();
      final difference = now.difference(lastSeenTime);
      if (difference.inMinutes < 1) {
        return 'last seen just now';
      } else if (difference.inMinutes < 60) {
        return 'last seen ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'last seen ${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'last seen yesterday';
      } else if (difference.inDays < 7) {
        return 'last seen ${difference.inDays}d ago';
      } else {
        return 'last seen ${lastSeenTime.month}/${lastSeenTime.day}/${lastSeenTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
  // Long press chat options (pin/unpin, delete, etc.) - Quick Win 8
  void _showChatOptions(
      Map<String, dynamic> friend, String friendUserId, String username) {
    final isPinned = friend['is_pinned'] ?? false;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: Colors.white,
              ),
              title: Text(
                isPinned ? 'Unpin Chat' : 'Pin Chat',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _togglePinChat(friend);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Chat',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteChat(friend, username);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive, color: Colors.white),
              title: const Text(
                'Archive Chat',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Archive feature coming soon'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  void _togglePinChat(Map<String, dynamic> friend) {
    setState(() {
      friend['is_pinned'] = !(friend['is_pinned'] ?? false);
      // Re-sort the list to move pinned chats to top
      _friendsList.sort((a, b) {
        final aPinned = a['is_pinned'] ?? false;
        final bPinned = b['is_pinned'] ?? false;
        if (aPinned && !bPinned) return -1;
        if (!aPinned && bPinned) return 1;
        return 0;
      });
      _filteredFriendsList = List.from(_friendsList);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          friend['is_pinned'] == true ? 'Chat pinned' : 'Chat unpinned',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  void _deleteChat(Map<String, dynamic> friend, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Chat',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this chat with $username?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _friendsList.remove(friend);
                _filteredFriendsList = List.from(_friendsList);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  // Build status dropdown menu item with Discord-style icons
  DropdownMenuItem<String> _buildStatusMenuItem(
      String value, Color color, String label) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          _buildStatusIcon(value, color, size: 12),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  // Build status icon widget (Discord-style)
  Widget _buildStatusIcon(String status, Color color, {double size = 12}) {
    switch (status.toLowerCase()) {
      case 'online':
        // Green circle for online
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      case 'idle':
        // Hollow circle with ring effect for idle
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer orange circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            // Inner hollow part (creates ring effect)
            Container(
              width: size * 0.65,
              height: size * 0.65,
              decoration: BoxDecoration(
                color: Colors.grey[900] ?? AppConstants.mainBGColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      case 'do_not_disturb':
      case 'dnd':
        // Circle with minus sign for do not disturb
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: size * 0.6,
              height: size * 0.15,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
            ),
          ],
        );
      case 'invisible':
        // Grey circle for invisible
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: size * 0.15),
          ),
        );
      default:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
    }
  }
  // Update user status via API
  Future<void> _updateUserStatus(String newStatus) async {
    try {
      // Get current user ID
      final userId = _userData?['user_id']?.toString();
      if (userId == null) {
        throw Exception('User ID not found');
      }
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Updating status...'),
          duration: Duration(seconds: 1),
        ),
      );
      // Call API to update status
      final response = await widget.apiService.updateUser(
        userId,
        status: newStatus,
      );
      if (response['success'] == true) {
        // Update local state
        setState(() {
          _currentStatus = newStatus;
          if (_userData != null) {
            _userData!['status'] = newStatus;
          }
        });
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${_getStatusLabel(newStatus)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to update status');
      }
    } catch (error) {
      print('Error updating status: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Colors.green;
      case 'idle':
        return Colors.orange;
      case 'do_not_disturb':
      case 'dnd':
        return Colors.red;
      case 'invisible':
      case 'offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Get human-readable status label
  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return 'Online';
      case 'idle':
        return 'Idle';
      case 'do_not_disturb':
      case 'dnd':
        return 'Do Not Disturb';
      case 'invisible':
        return 'Invisible';
      default:
        return status;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.mainBGColor,
      drawer: _buildUserDrawer(),
      body: _buildCurrentPage(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}

