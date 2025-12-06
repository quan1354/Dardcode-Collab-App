import 'package:flutter/material.dart';
import 'package:darkord/consts/app_constants.dart';
import 'package:darkord/api/api_service.dart';
import 'package:darkord/utils/token_utils.dart';
import 'package:darkord/widgets/common_widgets.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

class MessagingPage extends StatefulWidget {
  final String accessToken;
  final String friendId;
  final String friendUsername;
  final String? friendAvatarUrl;
  final String friendStatus;
  final ApiService apiService;

  const MessagingPage({
    super.key,
    required this.accessToken,
    required this.friendId,
    required this.friendUsername,
    this.friendAvatarUrl,
    required this.friendStatus,
    required this.apiService,
  });

  @override
  State<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Add these variables for chat history
  List<Map<String, dynamic>> _messages = [];
  bool _isLoadingHistory = false; // Changed to false - load in background
  bool _hasMoreMessages = true;
  String? _lastMessageId;

  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isDisposed = false;

  Timer? _typingDebounceTimer;
  bool _isUserTyping = false;

  @override
  void initState() {
    super.initState();

    // Fetch chat history when page loads
    _fetchChatHistory();

    _setupWebSocketListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    _logConnectionStatus();
  }

  Future<void> _fetchChatHistory() async {
    try {
      // Don't show loading indicator - load in background like WhatsApp

      // Get current user ID from token
      final currentUserId = _getUserIdFromToken(widget.accessToken);
      if (currentUserId == null) {
        throw Exception('Could not get current user ID from token');
      }

      // Fetch message history
      final response = await widget.apiService
          .getMessageHistory(currentUserId, widget.friendId);

      if (response['success'] == true) {
        final messageData = response['message'];
        final results = messageData['payload']['results'] as List<dynamic>;

        // Convert API response to message format
        final List<Map<String, dynamic>> historyMessages =
            results.map((message) {
          final senderId = message['sender_id'].toString();
          final isSentByMe = senderId == currentUserId;
          final messageData = message['message'] as Map<String, dynamic>;
          final messageText = messageData['text'] ?? '';
          final isEdited = messageData['edited'] ?? false;
          final createdAt = message['created_at'];

          return {
            'id': createdAt.toString(),
            'text': messageText,
            'isSentByMe': isSentByMe,
            'timestamp': DateTime.fromMillisecondsSinceEpoch(createdAt),
            'status': 'read', // Assuming historical messages are read
            'sender_id': senderId,
            'created_at': createdAt, // Store created_at for edit/delete operations
            'edited': isEdited, // Store edited flag from API
          };
        }).toList();

        // Sort by timestamp (oldest first)
        historyMessages
            .sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

        setState(() {
          _messages = historyMessages;
        });

        // Scroll to bottom after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        print('Loaded ${_messages.length} historical messages');
      }
    } catch (error) {
      print('Error fetching chat history: $error');
      // Don't show error for background loading
    }
  }

  // Helper method to extract user ID from token
  String? _getUserIdFromToken(String accessToken) {
    return TokenUtils.getUserIdFromToken(accessToken);
  }

  void _logConnectionStatus() {
    print('=== WebSocket Connection Status ===');
    print('isWebSocketConnected: ${widget.apiService.isWebSocketConnected}');
    print(
        'webSocketChannel: ${widget.apiService.currentWebSocketChannel != null}');
    print('==================================');
  }

  void _setupWebSocketListeners() {
    // Listen for messages specific to this conversation using the passed ApiService
    widget.apiService.addMessageHandler(_handleIncomingMessage);
  }

  @override
  void dispose() {
    // Remove the handler using the passed ApiService
    widget.apiService.removeMessageHandler(_handleIncomingMessage);

    _isDisposed = true;

    // Clean up timers
    _typingDebounceTimer?.cancel();
    widget.apiService.stopTyping();

    // Dispose controllers
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // Safe setState method that checks if widget is still mounted
  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  // Update all methods to use widget.ApiService instead of _ApiService

  void _handleIncomingMessage(dynamic message) {
    try {
      print('Received message: $message');

      // Parse the incoming message - handle both String and Map
      final Map<String, dynamic> messageData;
      if (message is String) {
        messageData = json.decode(message);
      } else if (message is Map<String, dynamic>) {
        messageData = message;
      } else {
        print('Unknown message type: ${message.runtimeType}');
        return;
      }

      // Check if this is a payload response (edit/delete actions)
      if (messageData['payload'] != null && messageData['payload']['action'] != null) {
        final payload = messageData['payload'] as Map<String, dynamic>;
        final action = payload['action'] as Map<String, dynamic>;
        final actionType = action['action'] as String?;

        if (actionType == 'edit_message') {
          _handleEditMessageEvent(payload);
          return;
        } else if (actionType == 'delete_message') {
          _handleDeleteMessageEvent(payload);
          return;
        }
      }

      // Handle different types of incoming messages
      // Add check to ensure this message is for the current conversation
      if (messageData['event'] != null) {
        // Check if this message is intended for the current friend
        final senderId = messageData['sender_id']?.toString();
        final receiverId = messageData['receiver_id']?.toString();

        // Only process if this message is from our current friend or to our current friend
        if (senderId == widget.friendId || receiverId == widget.friendId) {
          if (messageData['event'] is String &&
              messageData['event'] == 'typing') {
            // Handle typing indicator
            _handleTypingEvent(messageData);
          } else if (messageData['event'] is Map &&
              messageData['event']['message'] != null) {
            // Handle actual message
            _handleNewMessage(messageData);
          }
        }
      }
    } catch (e) {
      print('Error parsing incoming message: $e');
    }
  }

  /// Handle edit message event from WebSocket
  void _handleEditMessageEvent(Map<String, dynamic> payload) {
    try {
      final senderId = payload['sender_id']?.toString();
      final msgCreatedAt = payload['msg_created_at'] as int?;
      final messageObj = payload['message'] as Map<String, dynamic>?;

      if (msgCreatedAt == null || messageObj == null) {
        print('Invalid edit message payload');
        return;
      }

      final newText = messageObj['text'] as String?;
      final isEdited = messageObj['edited'] as bool? ?? true;

      if (newText == null) {
        print('No text in edit message payload');
        return;
      }

      // Find and update the message in the list
      _safeSetState(() {
        final messageIndex = _messages.indexWhere(
          (msg) => msg['created_at'] == msgCreatedAt,
        );

        if (messageIndex != -1) {
          _messages[messageIndex]['text'] = newText;
          _messages[messageIndex]['edited'] = isEdited;
          print('Message updated locally: $newText (edited: $isEdited)');
        } else {
          print('Message not found for edit: created_at=$msgCreatedAt');
        }
      });
    } catch (e) {
      print('Error handling edit message event: $e');
    }
  }

  /// Handle delete message event from WebSocket
  void _handleDeleteMessageEvent(Map<String, dynamic> payload) {
    try {
      final msgCreatedAt = payload['msg_created_at'] as int?;

      if (msgCreatedAt == null) {
        print('Invalid delete message payload');
        return;
      }

      // Find and remove the message from the list
      _safeSetState(() {
        _messages.removeWhere((msg) => msg['created_at'] == msgCreatedAt);
        print('Message deleted locally: created_at=$msgCreatedAt');
      });
    } catch (e) {
      print('Error handling delete message event: $e');
    }
  }

  void _handleTypingEvent(Map<String, dynamic> messageData) {
    // Show typing indicator for the friend
    print('${widget.friendUsername} is typing...');
  }

  void _handleNewMessage(Map<String, dynamic> messageData) {
    try {
      final currentUserId = _getUserIdFromToken(widget.accessToken);
      final senderId = messageData['sender_id']?.toString();
      final isSentByMe = senderId == currentUserId;

      // Only process if this message is relevant to current conversation
      if (senderId == widget.friendId || senderId == currentUserId) {
        final newMessage = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'text': messageData['event']['message'] ?? '',
          'isSentByMe': isSentByMe,
          'timestamp': DateTime.now(),
          'status': 'delivered',
          'sender_id': senderId,
        };

        _safeSetState(() {
          _messages.add(newMessage);
        });

        _scrollToBottom();
      }
    } catch (e) {
      print('Error handling new message: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && mounted) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onMessageFieldChanged(String text) {
    if (text.isNotEmpty && mounted) {
      // User is typing - trigger typing event with debouncing
      _triggerTypingEvent();
    } else if (text.isEmpty && _isUserTyping) {
      // User cleared the field - stop typing
      _stopTypingEvent();
    }
  }

  void _triggerTypingEvent() {
    // Cancel previous timer
    _typingDebounceTimer?.cancel();

    // Send typing event immediately if not already typing
    if (!_isUserTyping) {
      _sendTypingEvent();
      _isUserTyping = true;
    }

    // Set up timer to stop typing after 1 second of inactivity
    _typingDebounceTimer = Timer(const Duration(seconds: 1), () {
      _stopTypingEvent();
    });
  }

  void _sendTypingEvent() {
    try {
      // Check if WebSocket is actually connected before sending
      if (!widget.apiService.isWebSocketConnected) {
        print('WebSocket not connected, attempting to reconnect...');
        _reconnect();
        return;
      }

      widget.apiService.startTyping(widget.accessToken, widget.friendId);
      print('Typing indicator sent to ${widget.friendUsername}');
    } catch (e) {
      print('Error sending typing event: $e');
      // Attempt to reconnect on error
      _reconnect();
    }
  }

  void _stopTypingEvent() {
    _isUserTyping = false;
    _typingDebounceTimer?.cancel();
    widget.apiService.stopTyping();
    print('Typing indicator stopped for ${widget.friendUsername}');
  }

  void _sendMessage() {
    final text = _messageController.text.trim();

    // Use the global WebSocket connection status from ApiService
    if (text.isEmpty || !widget.apiService.isWebSocketConnected) return;

    // Stop typing when sending message
    _stopTypingEvent();

    // Create local message immediately for better UX
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final newMessage = {
      'id': createdAt.toString(),
      'text': text,
      'isSentByMe': true,
      'timestamp': DateTime.now(),
      'status': 'sending',
      'created_at': createdAt, // Store created_at for edit/delete operations
    };

    _safeSetState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      // Send via WebSocket using the passed ApiService
      widget.apiService.sendMessage(widget.accessToken, text, widget.friendId);

      // Update status to sent
      _safeSetState(() {
        _messages.last['status'] = 'sent';
      });
    } catch (e) {
      print('Error sending message: $e');
      _safeSetState(() {
        _messages.last['status'] = 'failed';
      });
      _showError('Failed to send message');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _reconnect() async {
    if (mounted) {
      try {
        print('Attempting to reconnect WebSocket...');
        await widget.apiService.connectToWebSocket(widget.accessToken);

        // Check connection status after reconnection attempt
        if (widget.apiService.isWebSocketConnected) {
          print('WebSocket reconnected successfully');
          if (mounted) {
            setState(() {});
          }
        } else {
          print('WebSocket reconnection failed');
        }
      } catch (e) {
        print('Reconnection failed: $e');
      }
    }
  }

  // Update connection status indicator to use global WebSocket status
  Widget _buildConnectionStatusIndicator() {
    // Use the global WebSocket connection status
    final isConnected = widget.apiService.isWebSocketConnected;

    if (!isConnected) {
      return GestureDetector(
        onTap: _reconnect,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 4),
            Text(
              'Offline',
              style: TextStyle(color: Colors.red, fontSize: 10),
            ),
          ],
        ),
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
          Text(
            'Online',
            style: TextStyle(color: Colors.green, fontSize: 10),
          ),
        ],
      );
    }
  }

  Widget _buildLoadingHistory() {
    return const LoadingIndicator(message: 'Loading chat history...');
  }

  // Update the build method to use global connection status
  @override
  Widget build(BuildContext context) {
    final isConnected = widget.apiService.isWebSocketConnected;

    return Scaffold(
      backgroundColor: AppConstants.mainBGColor,
      appBar: AppBar(
        backgroundColor: AppConstants.mainBGColor,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey,
              backgroundImage: widget.friendAvatarUrl != null
                  ? NetworkImage(widget.friendAvatarUrl!)
                  : null,
              child: widget.friendAvatarUrl == null
                  ? const Icon(Icons.person, size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.friendUsername,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.friendStatus,
                  style: TextStyle(
                    color: widget.friendStatus.toLowerCase() == 'online'
                        ? Colors.green[400]
                        : Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: isConnected
                ? () {
                    print('Start video call with ${widget.friendUsername}');
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: isConnected
                ? () {
                    print('Start voice call with ${widget.friendUsername}');
                  }
                : null,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'reconnect') {
                _reconnect();
              } else if (value == 'connection_info') {
                _showConnectionInfo();
              } else if (value == 'remove_friend') {
                _showRemoveFriendConfirmation();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'connection_info',
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      color: isConnected ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(isConnected ? 'Connected' : 'Disconnected'),
                  ],
                ),
              ),
              if (!isConnected)
                PopupMenuItem(
                  value: 'reconnect',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Reconnect'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'remove_friend',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Remove Friend', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: _buildMessageList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.add, color: Colors.white, size: 24),
                      onPressed: isConnected
                          ? () {
                              print('Add attachment');
                            }
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius * 2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 14.0,
                                  ),
                                ),
                                onChanged: _onMessageFieldChanged,
                                onSubmitted: (_) => _sendMessage(),
                                maxLines: 5,
                                minLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            isConnected ? Colors.blue[800] : Colors.grey[600],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send,
                            color: Colors.white, size: 24),
                        onPressed: isConnected ? _sendMessage : null,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... keep the rest of your existing methods (_buildMessageBubble, _buildDateSeparator, etc.)
  // but make sure to update any references from _ApiService to widget.ApiService

  Widget _buildStatusRow(String label, bool isConnected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white),
            ),
          ),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showConnectionInfo() {
    final isConnected = widget.apiService.isWebSocketConnected;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Connection Status',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('WebSocket Connection', isConnected),
            _buildFriendStatusRow('Friend Status', widget.friendStatus),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.blue)),
          ),
          if (!isConnected)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _reconnect();
              },
              child: Text('Reconnect', style: TextStyle(color: Colors.green)),
            ),
        ],
      ),
    );
  }

  Widget _buildFriendStatusRow(String label, String status) {
    final isOnline = status.toLowerCase() == 'online';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: isOnline ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMessageList() {
    List<Widget> messageWidgets = [];
    DateTime? currentDate;

    for (var message in _messages) {
      final timestamp = message['timestamp'] is DateTime
          ? message['timestamp'] as DateTime
          : DateTime.now();
      final messageDate =
          DateTime(timestamp.year, timestamp.month, timestamp.day);

      // Add date separator if date changes
      if (currentDate == null || currentDate != messageDate) {
        currentDate = messageDate;
        messageWidgets.add(_buildDateSeparator(currentDate));
      }

      messageWidgets.add(_buildMessageBubble(message));
    }

    return messageWidgets;
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isSentByMe = message['isSentByMe'] ?? false;
    final text = message['text'] ?? '';
    final timestamp = message['timestamp'] is DateTime
        ? message['timestamp'] as DateTime
        : DateTime.now();
    final status = message['status'] ?? 'sent';

    return GestureDetector(
      onLongPress: () => _showMessageMenu(context, message),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment:
              isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isSentByMe)
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey,
                backgroundImage: widget.friendAvatarUrl != null
                    ? NetworkImage(widget.friendAvatarUrl!)
                    : null,
                child: widget.friendAvatarUrl == null
                    ? const Icon(Icons.person, size: 16, color: Colors.white)
                    : null,
              ),
            Flexible(
              child: Container(
                margin: EdgeInsets.only(
                  left: isSentByMe ? 60.0 : 8.0,
                  right: isSentByMe ? 8.0 : 60.0,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: isSentByMe ? Colors.blue[800] : Colors.grey[800],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20.0),
                    topRight: const Radius.circular(20.0),
                    bottomLeft: isSentByMe
                        ? const Radius.circular(20.0)
                        : const Radius.circular(4.0),
                    bottomRight: isSentByMe
                        ? const Radius.circular(4.0)
                        : const Radius.circular(20.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message['edited'] == true) ...[
                          Text(
                            'edited',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _formatTime(timestamp),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        if (isSentByMe) ...[
                          const SizedBox(width: 4),
                          _buildMessageStatusIcon(status),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isSentByMe)
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[700],
                child: const Icon(Icons.person, size: 16, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  // Enhanced read receipts with WhatsApp-style icons
  Widget _buildMessageStatusIcon(String status) {
    switch (status) {
      case 'sending':
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey[400],
          ),
        );
      case 'sent':
        // Single grey check
        return Icon(
          Icons.check,
          size: 14,
          color: Colors.grey[400],
        );
      case 'delivered':
        // Double grey checks
        return Icon(
          Icons.done_all,
          size: 14,
          color: Colors.grey[400],
        );
      case 'read':
        // Double blue checks (WhatsApp style)
        return Icon(
          Icons.done_all,
          size: 14,
          color: Colors.blue[400],
        );
      case 'failed':
        return Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.red[400],
        );
      default:
        return Icon(
          Icons.check,
          size: 14,
          color: Colors.grey[400],
        );
    }
  }

  // Long press message menu (WhatsApp-style)
  void _showMessageMenu(BuildContext context, Map<String, dynamic> message) {
    final isSentByMe = message['isSentByMe'] ?? false;
    
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
            _buildMenuOption(
              icon: Icons.reply,
              label: 'Reply',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement reply functionality
                print('Reply to message: ${message['text']}');
              },
            ),
            _buildMenuOption(
              icon: Icons.copy,
              label: 'Copy',
              onTap: () {
                Navigator.pop(context);
                // TODO: Copy to clipboard
                print('Copy message: ${message['text']}');
              },
            ),
            if (isSentByMe) ...[
              _buildMenuOption(
                icon: Icons.edit,
                label: 'Edit',
                onTap: () {
                  Navigator.pop(context);
                  _showEditMessageDialog(message);
                },
              ),
              _buildMenuOption(
                icon: Icons.delete,
                label: 'Delete',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteMessageConfirmation(message);
                },
              ),
            ],
            _buildMenuOption(
              icon: Icons.star_border,
              label: 'Star',
              onTap: () {
                Navigator.pop(context);
                // TODO: Star message
                print('Star message: ${message['text']}');
              },
            ),
            _buildMenuOption(
              icon: Icons.info_outline,
              label: 'Info',
              onTap: () {
                Navigator.pop(context);
                _showMessageInfo(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white),
      title: Text(
        label,
        style: TextStyle(color: color ?? Colors.white),
      ),
      onTap: onTap,
    );
  }

  /// Show edit message dialog
  void _showEditMessageDialog(Map<String, dynamic> message) {
    final TextEditingController editController = TextEditingController(
      text: message['text'],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Edit Message',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter new message',
            hintStyle: TextStyle(color: Colors.grey[400]),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
          maxLines: 3,
          minLines: 1,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              editController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != message['text']) {
                Navigator.pop(context);
                _editMessage(message, newText);
              } else {
                Navigator.pop(context);
              }
              editController.dispose();
            },
            child: const Text('Save', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  /// Edit message API call
  Future<void> _editMessage(Map<String, dynamic> message, String newText) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Editing message...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Get current user ID from token
      final currentUserId = _getUserIdFromToken(widget.accessToken);
      if (currentUserId == null) {
        throw Exception('Could not get current user ID from token');
      }

      // Get message created_at timestamp
      final createdAt = message['created_at'] as int;

      // Call API to edit message
      final response = await widget.apiService.editUserMessage(
        currentUserId,
        widget.friendId,
        createdAt,
        newText,
      );

      if (response['success'] == true) {
        // Update message locally
        setState(() {
          message['text'] = newText;
          message['edited'] = true; // Mark as edited
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message edited successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to edit message');
      }
    } catch (error) {
      print('Error editing message: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to edit message: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show delete message confirmation dialog
  void _showDeleteMessageConfirmation(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Message',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this message? This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Delete message API call
  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleting message...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Get current user ID from token
      final currentUserId = _getUserIdFromToken(widget.accessToken);
      if (currentUserId == null) {
        throw Exception('Could not get current user ID from token');
      }

      // Get message created_at timestamp
      final createdAt = message['created_at'] as int;

      // Call API to delete message
      final response = await widget.apiService.deleteUserMessage(
        currentUserId,
        widget.friendId,
        createdAt,
      );

      if (response['success'] == true) {
        // Remove message locally
        setState(() {
          _messages.remove(message);
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to delete message');
      }
    } catch (error) {
      print('Error deleting message: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete message: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showMessageInfo(Map<String, dynamic> message) {
    final timestamp = message['timestamp'] as DateTime;
    final status = message['status'] ?? 'sent';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Message Info',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Sent', _formatFullDateTime(timestamp)),
            if (status == 'delivered' || status == 'read')
              _buildInfoRow('Delivered', _formatFullDateTime(timestamp)),
            if (status == 'read')
              _buildInfoRow('Read', _formatFullDateTime(timestamp)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
  // Remove friend confirmation dialog
  void _showRemoveFriendConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Remove Friend',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove ${widget.friendUsername} from your friends list? This will delete all chat history.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _removeFriend();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Remove friend API call
  Future<void> _removeFriend() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removing friend...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get current user ID from token
      final currentUserId = _getUserIdFromToken(widget.accessToken);
      if (currentUserId == null) {
        throw Exception('Could not get current user ID from token');
      }

      // Call API to remove friend
      final response = await widget.apiService.removeChatUser(
        currentUserId,
        widget.friendId,
      );

      if (response['success'] == true) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.friendUsername} has been removed from your friends list'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Navigate back to chat list with refresh
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate refresh needed
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to remove friend');
      }
    } catch (error) {
      print('Error removing friend: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove friend: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }


  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400]),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatFullDateTime(DateTime timestamp) {
    return '${timestamp.month}/${timestamp.day}/${timestamp.year} ${_formatTime(timestamp)}';
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        _formatDate(date),
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}
