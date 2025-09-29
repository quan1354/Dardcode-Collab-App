// add_friend_page.dart
import 'package:flutter/material.dart';
import 'package:darkord/consts/color.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.userData != null && widget.userData!['status'] != null) {
      _currentStatus = widget.userData!['status'];
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchUsers() {
    final String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      print('Searching for: $query');
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

  void _addSelectedPersons() {
    if (_selectedIndices.isNotEmpty) {
      print('Adding ${_selectedIndices.length} persons');
      // Implement your add friends logic here
      // You can call an API to send friend requests to all selected users
    }
  }

  // Sample data for nearby people
  final List<Map<String, dynamic>> _nearbyPeople = [
    {
      'name': 'Alex Johnson',
      'mutualFriends': 5,
      'distance': '0.5 km away',
    },
    {
      'name': 'Sarah Miller',
      'mutualFriends': 3,
      'distance': '0.8 km away',
    },
    {
      'name': 'Mike Chen',
      'mutualFriends': 8,
      'distance': '1.2 km away',
    },
    {
      'name': 'Emma Wilson',
      'mutualFriends': 2,
      'distance': '0.3 km away',
    },
    {
      'name': 'David Brown',
      'mutualFriends': 6,
      'distance': '1.5 km away',
    },
  ];

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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
                sliver: SliverToBoxAdapter(
                  child: const Text(
                    'Discover Nearby People',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Discover Nearby People Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final person = _nearbyPeople[index];
                      final isSelected = _selectedIndices.contains(index);

                      return _buildNearbyPersonItem(
                        name: person['name'],
                        mutualFriends: person['mutualFriends'],
                        distance: person['distance'],
                        isSelected: isSelected,
                        onTap: () => _toggleSelection(index),
                      );
                    },
                    childCount: _nearbyPeople.length,
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

  Widget _buildNearbyPersonItem({
    required String name,
    required int mutualFriends,
    required String distance,
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
                const CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 25,
                  child: Icon(Icons.person, color: Colors.white),
                ),

                const SizedBox(width: 12),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$mutualFriends mutual friends',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        distance,
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