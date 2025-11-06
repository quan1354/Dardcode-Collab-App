import 'package:flutter/material.dart';
import 'package:darkord/models/user.dart';

/// Provider for managing chat-related state
class ChatProvider with ChangeNotifier {
  List<User> _chatList = [];
  
  List<User> get chatList => _chatList;
  
  int get chatCount => _chatList.length;
  
  /// Check if user exists in chat list
  bool hasUser(String userId) {
    return _chatList.any((user) => user.userId == userId);
  }
  
  /// Add multiple users to chat list
  void addUsersToChatList(List<User> users) {
    bool hasChanges = false;
    
    for (final user in users) {
      if (!hasUser(user.userId)) {
        _chatList.add(user);
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      notifyListeners();
    }
  }
  
  /// Add single user to chat list
  void addUserToChatList(User user) {
    if (!hasUser(user.userId)) {
      _chatList.add(user);
      notifyListeners();
    }
  }
  
  /// Remove user from chat list
  void removeFromChatList(String userId) {
    final initialLength = _chatList.length;
    _chatList.removeWhere((user) => user.userId == userId);
    
    if (_chatList.length != initialLength) {
      notifyListeners();
    }
  }
  
  /// Clear all chats
  void clearChatList() {
    if (_chatList.isNotEmpty) {
      _chatList.clear();
      notifyListeners();
    }
  }
  
  /// Get user by ID
  User? getUserById(String userId) {
    try {
      return _chatList.firstWhere((user) => user.userId == userId);
    } catch (e) {
      return null;
    }
  }
}