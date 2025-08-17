import 'package:flutter/material.dart';
import 'package:darkord/consts/color.dart';

class ChatList extends StatelessWidget {
  const ChatList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainBGColor,
      body: CustomScrollView(
        slivers: [
          // Static navigation bar with scroll-activated shadow
          SliverAppBar(
            pinned: true,
            floating: false,
            snap: false,
            elevation: 4, // This enables the shadow when scrolled
            shadowColor: Color.lerp(
              Colors.transparent,
              Colors.black,
              0.3, // Equivalent to 30% opacity
            ), // Custom shadow color
            surfaceTintColor: Colors.transparent, // Removes the tint effect
            backgroundColor: mainBGColor,
            title: const Text(
              'Messages',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Search bar
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

          // Chat list with single dummy user
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Only show one user with the specified details
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: const Text(
                    'ii887522',
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
                  onTap: () {
                    // Handle chat tap
                  },
                );
              },
              childCount: 1, // Only one item in the list
            ),
          ),
        ],
      ),
    );
  }
}