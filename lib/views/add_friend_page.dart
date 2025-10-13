// add_friend_page.dart
import 'package:flutter/material.dart';
import 'package:darkord/consts/color.dart';
import 'package:darkord/models/user.dart';
import 'package:darkord/views/chat_list.dart';
import 'package:darkord/api/auth_api.dart';

class AddFriendPage extends StatefulWidget {
  final String accessToken;
  final Map<String, dynamic>? userData;
  final List<dynamic>? currentFriends; // Add this parameter

  const AddFriendPage({
    super.key,
    required this.accessToken,
    this.userData,
    this.currentFriends, // Add this parameter
  });

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  String _currentStatus = 'online';
  final Set<int> _selectedIndices = {};
  final AuthApi _authApi = AuthApi();

  List<User> _nearbyUsers = [];
  List<User> _filteredNearbyUsers = []; // Add filtered list
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.userData != null && widget.userData!['status'] != null) {
      _currentStatus = widget.userData!['status'];
    }
    _fetchNearbyUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Method to filter out already friends
  void _filterOutFriends(List<User> allUsers) {
    if (widget.currentFriends == null || widget.currentFriends!.isEmpty) {
      setState(() {
        _filteredNearbyUsers = allUsers;
      });
      return;
    }

    // Extract friend user IDs from current friends list
    final friendUserIds = widget.currentFriends!.map((friend) {
      return friend['user_id'].toString();
    }).toSet();

    print('Current friend IDs: $friendUserIds');
    print('Total nearby users before filtering: ${allUsers.length}');

    // Filter out users who are already friends
    final filteredUsers = allUsers.where((user) {
      final isAlreadyFriend = friendUserIds.contains(user.userId.toString());
      if (isAlreadyFriend) {
        print('Filtering out already friend: ${user.username} (${user.userId})');
      }
      return !isAlreadyFriend;
    }).toList();

    print('Total nearby users after filtering: ${filteredUsers.length}');

    setState(() {
      _filteredNearbyUsers = filteredUsers;
    });
  }

  Future<void> _fetchNearbyUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final users = await _authApi.findNearbyUsers(widget.accessToken);

      // Filter out already friends
      _filterOutFriends(users);
      
      setState(() {
        _nearbyUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load nearby users: $e';
      });
      print('Error fetching nearby users: $e');
    }
  }

  void _searchUsers() {
    final String query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      print('Searching for: $query');
      
      // Filter the already filtered list by search query
      final searchResults = _filteredNearbyUsers.where((user) {
        final username = user.username?.toLowerCase() ?? '';
        final email = user.emailAddr?.toLowerCase() ?? '';
        final userId = user.userId?.toString() ?? '';
        
        return username.contains(query) || 
               email.contains(query) || 
               userId.contains(query);
      }).toList();

      setState(() {
        _filteredNearbyUsers = searchResults;
      });
    } else {
      // If search is empty, reset to original filtered list
      _filterOutFriends(_nearbyUsers);
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _addSelectedPersons() async {
    if (_selectedIndices.isNotEmpty) {
      final selectedUsers =
          _selectedIndices.map((index) => _filteredNearbyUsers[index]).toList();
      final selectedUserIds =
          selectedUsers.map((user) => user.userId.toString()).toList();

      try {
        setState(() {
          _isLoading = true;
        });

        // Make the actual API call with selected user IDs
        await _authApi.addUsers(widget.accessToken,
            widget.userData!['user_id'].toString(), selectedUserIds);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Friend requests sent to ${selectedUsers.length} users'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to chat_list.dart page after success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatList(
              accessToken: widget.accessToken,
            ),
          ),
        );
      } catch (error) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send friend requests: $error'),
            backgroundColor: Colors.red,
          ),
        );
        print('Error adding friends: $error');
      } finally {
        setState(() {
          _isLoading = false;
          _selectedIndices.clear();
        });
      }
    }
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.blue,
          ),
          SizedBox(height: 16),
          Text(
            'Loading nearby users...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchNearbyUsers,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyPersonItem({
    required User user,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Colors.blue,
                  width: 2,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Selection background overlay
            if (isSelected)
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

            Row(
              children: [
                // Selection indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),

                const SizedBox(width: 12),

                // Avatar
                CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 25,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),

                const SizedBox(width: 12),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username ?? 'Unknown User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (user.emailAddr != null)
                        Text(
                          user.emailAddr!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      if (user.status != null)
                        Text(
                          'Status: ${user.status!}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.group_off,
            color: Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No new users found',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.currentFriends != null && widget.currentFriends!.isNotEmpty
                ? 'All nearby users are already your friends'
                : 'No users found nearby',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainBGColor,
      appBar: AppBar(
        backgroundColor: mainBGColor,
        elevation: 0,
        title: const Text(
          'Add Friends',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (!_isLoading && _errorMessage.isEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchNearbyUsers,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Search Section
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
                              hintText: 'Search by username or UID...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onChanged: (_) => _searchUsers(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.grey),
                          onPressed: _searchUsers,
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _searchUsers();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Quick Actions Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.qr_code,
                              title: 'Scan QR Code',
                              color: Colors.blue,
                              onTap: () {
                                // Navigate to QR scanner
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.contacts,
                              title: 'Contacts',
                              color: Colors.green,
                              onTap: () {
                                // Navigate to contacts
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Discover Nearby People Title
              if (!_isLoading &&
                  _errorMessage.isEmpty &&
                  _filteredNearbyUsers.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        const Text(
                          'Discover Nearby People',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${_filteredNearbyUsers.length})',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Loading State
              if (_isLoading)
                SliverFillRemaining(
                  child: _buildLoadingIndicator(),
                ),

              // Error State
              if (_errorMessage.isNotEmpty && !_isLoading)
                SliverFillRemaining(
                  child: _buildErrorWidget(),
                ),

              // Empty State
              if (!_isLoading && _errorMessage.isEmpty && _filteredNearbyUsers.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                ),

              // Discover Nearby People Section
              if (!_isLoading &&
                  _errorMessage.isEmpty &&
                  _filteredNearbyUsers.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final user = _filteredNearbyUsers[index];
                        final isSelected = _selectedIndices.contains(index);

                        return _buildNearbyPersonItem(
                          user: user,
                          isSelected: isSelected,
                          onTap: () => _toggleSelection(index),
                        );
                      },
                      childCount: _filteredNearbyUsers.length,
                    ),
                  ),
                ),

              // Add some bottom padding to account for the floating button
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),

          // Bottom Add Button
          if (_selectedIndices.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildAddButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    final selectedCount = _selectedIndices.length;
    return ElevatedButton.icon(
      onPressed: _addSelectedPersons,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        'Add $selectedCount ${selectedCount == 1 ? 'person' : 'persons'}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        shadowColor: Colors.blue.withOpacity(0.3),
      ),
    );
  }
}