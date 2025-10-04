// // chat_provider.dart (enhanced version)
// import 'package:flutter/material.dart';
// import 'package:darkord/models/user.dart';

// class ChatProvider with ChangeNotifier {
//   List<User> _chatList = [];
  
//   List<User> get chatList => _chatList;
  
//   int get chatCount => _chatList.length;
  
//   bool hasUser(String userId) {
//     return _chatList.any((user) => user.userId == userId);
//   }
  
//   void addUsersToChatList(List<User> users) {
//     bool hasChanges = false;
    
//     for (final user in users) {
//       if (!hasUser(user.userId!)) {
//         _chatList.add(user);
//         hasChanges = true;
//       }
//     }
    
//     if (hasChanges) {
//       notifyListeners();
//     }
//   }
  
//   void addUserToChatList(User user) {
//     if (!hasUser(user.userId!)) {
//       _chatList.add(user);
//       notifyListeners();
//     }
//   }
  
//   void removeFromChatList(String userId) {
//     final initialLength = _chatList.length;
//     _chatList.removeWhere((user) => user.userId == userId);
    
//     if (_chatList.length != initialLength) {
//       notifyListeners();
//     }
//   }
  
//   void clearChatList() {
//     if (_chatList.isNotEmpty) {
//       _chatList.clear();
//       notifyListeners();
//     }
//   }
  
//   User? getUserById(String userId) {
//     try {
//       return _chatList.firstWhere((user) => user.userId == userId);
//     } catch (e) {
//       return null;
//     }
//   }
// }