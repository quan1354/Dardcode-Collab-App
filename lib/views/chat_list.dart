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

          // Chat list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    'User ${index + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Last message ${index + 1}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Text(
                    '${index + 1}:${index + 1}0',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    // Handle chat tap
                  },
                );
              },
              childCount: 20,
            ),
          ),
        ],
      ),
    );
  }
}