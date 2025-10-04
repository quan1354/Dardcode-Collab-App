// add_friend_page.dart
import 'package:flutter/material.dart';
import 'package:darkord/consts/color.dart';
import 'package:darkord/models/user.dart';
import 'package:provider/provider.dart';
import 'package:darkord/api/auth_api.dart'; // Change this import

class AddFriendPage extends StatefulWidget {
  final String accessToken;
  final Map<String, dynamic>? userData;

  const AddFriendPage({
    super.key,
    required this.accessToken,
    this.userData,
  });

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  String _currentStatus = 'online';
  final Set<int> _selectedIndices = {}; // Track selected nearby people indices
  final AuthApi _authApi = AuthApi();
  
  // Replace sample data with actual API data
  List<User> _nearbyUsers = [];
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

  // TODO: Fetch nearby users using the API
  Future<void> _fetchNearbyUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final users = await _authApi.fetchNearbyUsers(widget.accessToken);
      
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
    final String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      print('Searching for: $query');
      // You can implement search filtering here
      // For now, we'll just refetch all users
      _fetchNearbyUsers();
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

  // TODO: After click add selected persons, no need send request, direct add to chat_list.dart
  void _addSelectedPersons() {
    if (_selectedIndices.isNotEmpty) {
      final selectedUsers = _selectedIndices.map((index) => _nearbyUsers[index]).toList();
      print('Adding ${selectedUsers.length} persons: ${selectedUsers.map((u) => u.username).toList()}');
      
      // TODO: Implement your add friends logic here
      // You can call an API to send friend requests to all selected users
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend requests sent to ${selectedUsers.length} users'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear selection after adding
      setState(() {
        _selectedIndices.clear();
      });
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
                            onSubmitted: (_) => _searchUsers(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.grey),
                          onPressed: _searchUsers,
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
              if (!_isLoading && _errorMessage.isEmpty && _nearbyUsers.isNotEmpty)
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
                          '(${_nearbyUsers.length})',
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
              if (!_isLoading && _errorMessage.isEmpty && _nearbyUsers.isEmpty)
                SliverFillRemaining(
                  child: const Center(
                    child: Text(
                      'No nearby users found',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

              // Discover Nearby People Section
              if (!_isLoading && _errorMessage.isEmpty && _nearbyUsers.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final user = _nearbyUsers[index];
                        final isSelected = _selectedIndices.contains(index);

                        return _buildNearbyPersonItem(
                          user: user,
                          isSelected: isSelected,
                          onTap: () => _toggleSelection(index),
                        );
                      },
                      childCount: _nearbyUsers.length,
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