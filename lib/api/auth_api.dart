import 'dart:convert';
import 'package:darkord/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:async';

class AuthApi {
  static final AuthApi _instance = AuthApi._internal();
  factory AuthApi() => _instance;
  AuthApi._internal(); // Private constructor

  static const String _baseUrl = 'https://d3v904dal0xey8.cloudfront.net';
  String? _accessToken;
  String? _refreshToken;
  String? _sessionToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get sessionToken => _sessionToken;

  // WebSocket management
  WebSocketChannel? _webSocketChannel;
  WebSocketChannel? get webSocketChannel => _webSocketChannel;
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isConnected = false;

  // Message handlers for global message distribution
  final List<Function(dynamic)> _messageHandlers = [];
  final List<Function()> _connectionHandlers = [];
  final List<Function()> _disconnectionHandlers = [];

  set sessionToken(String? token) {
    _sessionToken = token;
    print('Session token ${token != null ? 'set' : 'cleared'}');
  }

  set accessToken(String? token) {
    _accessToken = token;
    print('Access token ${token != null ? 'set' : 'cleared'}');
  }

  set refreshToken(String? token) {
    _refreshToken = token;
    print('Refresh token ${token != null ? 'set' : 'cleared'}');
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    _sessionToken = null;
    print('All tokens cleared');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print(email);
      print(password);
      final url = Uri.parse('$_baseUrl/user/login');
      final url_mfa = Uri.parse('$_baseUrl/user/login/mfa');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email_addr': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(responseData['message'] ?? 'Login failed');
      }

      // ✅ Store session token using setter
      final sessionToken = responseData['payload']['session_token'];
      this.sessionToken = sessionToken;

      final responseMfa = await http.post(
        url_mfa,
        headers: {
          'Authorization': sessionToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'mfa_code': '123456'}),
      );

      final mfaData = jsonDecode(responseMfa.body) as Map<String, dynamic>;

      // ✅ Store access and refresh tokens using setters
      accessToken = mfaData['payload']['access_token'];
      refreshToken = mfaData['payload']['refresh_token'];

      print('login mfaData: $mfaData');

      // Connect WebSocket automatically after successful login
      await connectToWebSocket(accessToken!);

      return mfaData;
    } catch (e) {
      // Clear tokens on login failure
      clearTokens();
      throw Exception('Login error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> signUpUser(
      String username, String emailAddr, String password) async {
    try {
      final signUpUrl = Uri.parse('$_baseUrl/user');
      final signUpOtpUrl = Uri.parse('$_baseUrl/user/otp');
      final signUpMfaUrl = Uri.parse('$_baseUrl/user/mfa');

      final headers = {
        'Content-Type': 'application/json',
      };

      // Step 1: Initial sign up request
      final signUpResponse = await http.post(
        signUpUrl,
        headers: headers,
        body: jsonEncode({
          'username': username,
          'email_addr': emailAddr,
          'password': password,
        }),
      );

      final signUpData =
          jsonDecode(signUpResponse.body) as Map<String, dynamic>;
      print('Initial Sign Up Response: $signUpData');

      if (signUpResponse.statusCode != 200) {
        throw Exception('Sign up failed: ${signUpData['message']}');
      }

      // Extract OTP from response
      final otp = signUpData['payload']?['otp'] as String?;
      if (otp == null) {
        throw Exception('OTP not received in response');
      }

      // Extract session token
      final sessionToken = signUpData['payload']?['session_token'] as String?;
      if (sessionToken == null) {
        throw Exception('Session token not received');
      }

      // Step 2: Verify OTP
      final otpResponse = await http.post(
        signUpOtpUrl,
        headers: {'Authorization': signUpData['payload']?['session_token']},
        body: jsonEncode({'otp': otp}),
      );

      final otpData = jsonDecode(otpResponse.body) as Map<String, dynamic>;
      print('OTP Verification Response: $otpData');

      if (otpResponse.statusCode != 200) {
        throw Exception('OTP verification failed: ${otpData['message']}');
      }

      // Step 3: Complete MFA verification
      final mfaCode = otpData['payload']?['mfa_secret'];
      print(mfaCode);
      final mfaResponse = await http.post(
        signUpMfaUrl,
        headers: {'Authorization': otpData['payload']?['session_token']},
        body: jsonEncode({'mfa_code': mfaCode}),
      );

      final mfaData = jsonDecode(mfaResponse.body) as Map<String, dynamic>;
      print('MFA Verification Response: $mfaData');

      if (mfaResponse.statusCode != 200) {
        throw Exception('MFA verification failed: ${mfaData['message']}');
      }
      print(mfaData);

      // Extract reset token
      final resetToken = signUpData['payload']?['resend_otp_token'] as String?;
      if (resetToken == null) {
        throw Exception('Reset token not received');
      }

      return {
        'success': true,
        'otp': otp,
        'session_token': sessionToken,
        'reset_token': resetToken,
        'message': 'Sign up initiated successfully'
      };
    } catch (e) {
      throw Exception('Sign up error: $e');
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
      String sessionToken, String otp) async {
    try {
      final otpUrl = Uri.parse('$_baseUrl/user/otp');

      final response = await http.post(
        otpUrl,
        headers: {
          'Authorization': sessionToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'otp': otp}),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('OTP Verification Response: $responseData');

      if (response.statusCode != 200) {
        throw Exception('OTP verification failed: ${responseData['message']}');
      }

      return {
        'success': true,
        'session_token': responseData['payload']?['session_token'],
        'mfa_secret': responseData['payload']?['mfa_secret'],
        'message': 'OTP verified successfully'
      };
    } catch (e) {
      throw Exception('OTP verification error: $e');
    }
  }

  Future<Map<String, dynamic>> verifyMfa(
      String sessionToken, String mfaCode) async {
    try {
      final mfaUrl = Uri.parse('$_baseUrl/user/mfa');

      final response = await http.post(
        mfaUrl,
        headers: {
          'Authorization': sessionToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'mfa_code': mfaCode}),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('MFA Verification Response: $responseData');

      if (response.statusCode != 200) {
        throw Exception('MFA verification failed: ${responseData['message']}');
      }

      return {
        'success': true,
        'message': 'Registration completed successfully',
        'user_data': responseData
      };
    } catch (e) {
      throw Exception('MFA verification error: $e');
    }
  }

  Future<Map<String, dynamic>> resendOtp(String sessionToken) async {
    try {
      final resendOtpUrl = Uri.parse('$_baseUrl/user/otp/resend');

      final response = await http.post(
        resendOtpUrl,
        headers: {
          'Authorization': sessionToken,
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Resend OTP Response: $responseData');

      if (response.statusCode != 200) {
        throw Exception('Resend OTP failed: ${responseData['message']}');
      }

      return {'success': true, 'message': 'OTP resent successfully'};
    } catch (e) {
      throw Exception('Resend OTP error: $e');
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String emailAddr, String password) async {
    try {
      final requestResetUrl = Uri.parse('$_baseUrl/user/password/request');
      final verifyOtpUrl = Uri.parse('$_baseUrl/user/password/request/otp');
      final confirmResetUrl = Uri.parse('$_baseUrl/user/password');

      final headers = {
        'Content-Type': 'application/json',
      };

      // 1. Initiate password reset request
      final resetRequest = await http.put(
        requestResetUrl,
        headers: headers,
        body: jsonEncode({'email_addr': emailAddr}),
      );

      final resetRequestData =
          jsonDecode(resetRequest.body) as Map<String, dynamic>;
      print('Reset Request Response: $resetRequestData');

      if (resetRequest.statusCode != 200) {
        throw Exception(
            'Reset request failed: ${resetRequestData['message'] ?? 'Unknown error'}');
      }

      // Get session token and OTP
      final sessionToken =
          resetRequestData['payload']?['session_token'] as String?;
      final otp = resetRequestData['payload']?['otp'] as String?;

      if (sessionToken == null || otp == null) {
        throw Exception('Missing session token or OTP in response');
      }

      // 2. Verify OTP
      final verifyResponse = await http.put(
        verifyOtpUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': sessionToken,
        },
        body: jsonEncode({'otp': otp}),
      );

      final verifyData =
          jsonDecode(verifyResponse.body) as Map<String, dynamic>;
      print('OTP Verification Response: $verifyData');

      if (verifyResponse.statusCode != 200) {
        throw Exception(
            'OTP verification failed: ${verifyData['message'] ?? 'Unknown error'}');
      }

      // Get the updated session token for password reset
      final resetSessionToken =
          verifyData['payload']?['session_token'] as String?;
      if (resetSessionToken == null) {
        throw Exception('Missing session token for password reset');
      }

      // 3. Confirm password reset
      final resetResponse = await http.put(
        confirmResetUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': resetSessionToken,
        },
        body: jsonEncode({'password': password}),
      );

      final resetData = jsonDecode(resetResponse.body) as Map<String, dynamic>;
      print('Password Reset Response: $resetData');

      if (resetResponse.statusCode != 200) {
        throw Exception(
            'Password reset failed: ${resetData['message'] ?? 'Unknown error'}');
      }

      return {
        'success': true,
        'message': 'Password reset successfully',
        'data': resetData
      };
    } catch (e) {
      print('Reset Password Error: $e');
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> verifyPasswordResetOtp(
      String sessionToken, String otp) async {
    try {
      final verifyOtpUrl = Uri.parse('$_baseUrl/user/password/request/otp');

      final response = await http.put(
        verifyOtpUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': sessionToken,
        },
        body: jsonEncode({'otp': otp}),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Password Reset OTP Verification Response: $responseData');

      if (response.statusCode != 200) {
        throw Exception('OTP verification failed: ${responseData['message']}');
      }

      return {
        'success': true,
        'session_token': responseData['payload']?['session_token'],
        'message': 'OTP verified successfully'
      };
    } catch (e) {
      throw Exception('OTP verification error: $e');
    }
  }

  Future<Map<String, dynamic>> initiatePasswordReset(String emailAddr) async {
    try {
      final requestResetUrl = Uri.parse('$_baseUrl/user/password/request');

      final response = await http.put(
        requestResetUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email_addr': emailAddr}),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Initiate Password Reset Response: $responseData');

      if (response.statusCode != 200) {
        throw Exception(
            'Password reset initiation failed: ${responseData['message']}');
      }

      return {
        'success': true,
        'session_token': responseData['payload']?['session_token'],
        'otp': responseData['payload']?['otp'],
        'reset_token': responseData['payload']?['resend_otp_token'],
        'message': 'Password reset initiated successfully'
      };
    } catch (e) {
      throw Exception('Password reset initiation error: $e');
    }
  }

  Future<List<User>> findNearbyUsers() async {
    return await retryWithTokenRefresh(() async {
      final uri = Uri.parse('$_baseUrl/user/list');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': accessToken!,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        if (responseData['payload'] != null &&
            responseData['payload']['results'] != null) {
          final usersData = responseData['payload']['results'] as List;
          return usersData.map((userJson) => User.fromJson(userJson)).toList();
        } else {
          throw Exception('No user data found');
        }
      } else {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    });
  }

  Future<Map<String, dynamic>> addUsers(
      String accessToken, String user_id, List<String> other_user_ids) async {
    try {
      final addUsersUrl = Uri.parse('$_baseUrl/chat/$user_id/list');

      final response = await http.post(
        addUsersUrl,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'other_user_ids': other_user_ids}),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Add Users Response: $responseData');

      if (response.statusCode != 200) {
        throw Exception('Add Users failed: ${responseData['message']}');
      }

      return {'success': true, 'message': 'Add Users successfully'};
    } catch (e) {
      throw Exception('Add Users error: $e');
    }
  }

  Future<dynamic> fetchUsers(String accessToken, String userIds,
      {bool returnList = false}) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/list').replace(queryParameters: {
        'user_ids': userIds,
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': accessToken,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print(responseData);

        if (responseData['payload'] != null &&
            responseData['payload']['results'] != null &&
            (responseData['payload']['results'] as List).isNotEmpty) {
          final results = responseData['payload']['results'] as List<dynamic>;

          if (returnList) {
            // Return the entire list for batch operations
            return results;
          } else {
            // Return single user (for backward compatibility)
            return User.fromJson(results[0]);
          }
        } else {
          throw Exception('No user data found');
        }
      } else {
        throw Exception('Failed to fetch user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  Future<Map<String, dynamic>> fetchChatUsers(
      String accessToken, String user_id) async {
    try {
      final fetchUsersUrl = Uri.parse('$_baseUrl/chat/$user_id/list');

      final response = await http.get(
        fetchUsersUrl,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Fetch Users successfully: $responseData');

      if (response.statusCode != 200) {
        throw Exception('Fetch Users failed: ${responseData['message']}');
      }

      // Return both success and the actual data
      return {
        'success': true,
        'message': 'Fetch Users successfully',
        'data': responseData // Include the actual data
      };
    } catch (e) {
      throw Exception('Fetch Users error: $e');
    }
  }

  Future<Map<String, dynamic>> getMessageHistory(
       user_id, other_user_id) async {
    try {


      final addUsersUrl =
          Uri.parse('$_baseUrl/chat/$user_id/$other_user_id/messages');

      final response = await http.get(
        addUsersUrl,
        headers: {
          'Authorization': accessToken!,
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Get Messages History Response: $responseData');

      if (response.statusCode != 200) {
        throw Exception(
            'Get Messages History Response failed: ${responseData['message']}');
      }

      return {'success': true, 'message': responseData};
    } catch (e) {
      throw Exception('WebSocket token error: ${e.toString()}');
    }
  }

  Future<String> getWebSocketToken(accessToken) async {
    try {
      if (accessToken == null) {
        throw Exception('No access token available. Please login first.');
      }

      print(
          'Fetching WebSocket token with access token: ${accessToken!.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse('https://d3v904dal0xey8.cloudfront.net/chat/ws_token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': accessToken!,
        },
      );

      final responseData = jsonDecode(response.body);
      print('WebSocket token response: $responseData');

      if (response.statusCode != 200) {
        throw Exception(
            responseData['message'] ?? 'Failed to get WebSocket token');
      }

      final wsToken = responseData['payload']['ws_token'];
      print('WebSocket token received: ${wsToken.substring(0, 20)}...');

      return wsToken;
    } catch (e) {
      throw Exception('WebSocket token error: ${e.toString()}');
    }
  }

  void checkConnectionHealth() {
    if (_webSocketChannel != null && _isConnected) {
      print('WebSocket connection is healthy');
    } else {
      print(
          'WebSocket connection issues: channel=${_webSocketChannel != null}, connected=$_isConnected');
    }
  }

  /// Handle incoming WebSocket messages and distribute to handlers
  void _handleIncomingMessage(dynamic message) {
    try {
      print('Received WebSocket message: $message');
      final decodedMessage = json.decode(message);

      // Notify all registered message handlers
      for (final handler in _messageHandlers) {
        handler(decodedMessage);
      }
    } catch (e) {
      print('Error processing incoming message: $e');
    }
  }

  Future<WebSocketChannel> connectToWebSocket(String accessToken) async {
    try {
      if (_webSocketChannel != null) {
        _webSocketChannel!.sink.close();
        _webSocketChannel = null;
      }

      _isConnected = false; // Reset connection status

      // Get WebSocket token first
      final wsToken = await getWebSocketToken(accessToken);

      // Connect to WebSocket
      final channel = IOWebSocketChannel.connect(
        'wss://srqaesich3.execute-api.us-east-1.amazonaws.com/stage?token=$wsToken',
      );

      _webSocketChannel = channel;

      // Set up listeners first
      channel.stream.listen(
        _handleIncomingMessage,
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          _notifyDisconnectionHandlers();
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          _notifyDisconnectionHandlers();
        },
      );

      // Set connected status after successful connection
      _isConnected = true;
      _notifyConnectionHandlers();

      print('WebSocket connected successfully');
      return channel;
    } catch (e) {
      _isConnected = false;
      print('WebSocket connection failed: $e');
      rethrow;
    }
  }

  /// Send message via WebSocket
  void sendMessage(String accessToken, String message, String otherUserId) {
    if (_webSocketChannel == null || !_isConnected) {
      throw Exception('WebSocket not connected');
    }

    final messageData = {
      "action": "send_message",
      "event": {
        "message": message,
      },
      "other_user_id": otherUserId,
    };

    final jsonMessage = jsonEncode(messageData);
    _webSocketChannel!.sink.add(jsonMessage);
  }

  /// Typing indicators
  void startTyping(String accessToken, String otherUserId) {
    if (_webSocketChannel == null || !_isConnected) {
      throw Exception('WebSocket not connected');
    }

    // Cancel any existing timer
    _typingTimer?.cancel();

    // Send typing event immediately if not already typing
    if (!_isTyping) {
      _sendTypingEvent(otherUserId);
      _isTyping = true;
    }

    // Set up timer to stop typing after 2 seconds of inactivity
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _stopTyping(otherUserId);
    });
  }

  void _sendTypingEvent(String otherUserId) {
    final typingData = {
      "action": "send_message",
      "event": "typing",
      "other_user_id": otherUserId,
    };

    final jsonMessage = jsonEncode(typingData);
    _webSocketChannel!.sink.add(jsonMessage);
    print('Typing event sent to $otherUserId');
  }

  void _stopTyping(String otherUserId) {
    _isTyping = false;
    _typingTimer?.cancel();
    print('Typing stopped for $otherUserId');
  }

  void stopTyping() {
    _isTyping = false;
    _typingTimer?.cancel();
  }

  /// Disconnect WebSocket (call on logout)
  void disconnectWebSocket() {
    _typingTimer?.cancel();
    _isTyping = false;
    _isConnected = false;
    _webSocketChannel?.sink.close();
    _webSocketChannel = null;

    // Clear all handlers
    _messageHandlers.clear();
    _connectionHandlers.clear();
    _disconnectionHandlers.clear();

    print('WebSocket disconnected and cleaned up');
  }

  // ==================== MESSAGE HANDLER MANAGEMENT ====================

  /// Register a message handler (for MessagingPage, ChatList, etc.)
  void addMessageHandler(Function(dynamic) handler) {
    if (!_messageHandlers.contains(handler)) {
      _messageHandlers.add(handler);
    }
  }

  /// Remove a message handler
  void removeMessageHandler(Function(dynamic) handler) {
    _messageHandlers.remove(handler);
  }

  /// Register connection handler
  void addConnectionHandler(Function() handler) {
    if (!_connectionHandlers.contains(handler)) {
      _connectionHandlers.add(handler);
    }
  }

  /// Register disconnection handler
  void addDisconnectionHandler(Function() handler) {
    if (!_disconnectionHandlers.contains(handler)) {
      _disconnectionHandlers.add(handler);
    }
  }

  void _notifyConnectionHandlers() {
    for (final handler in _connectionHandlers) {
      handler();
    }
  }

  void _notifyDisconnectionHandlers() {
    for (final handler in _disconnectionHandlers) {
      handler();
    }
  }

  /// Check if user is authenticated (has access token)
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  /// Check if refresh token is available
  bool get canRefreshToken =>
      _refreshToken != null && _refreshToken!.isNotEmpty;

  Future<Map<String, dynamic>> logoutUser(String accessToken) async {
    try {
      final logoutUserUrl = Uri.parse('$_baseUrl/user/logout');

      final response = await http.post(
        logoutUserUrl,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('LogOut Response: $responseData');

      if (response.statusCode != 200) {
        throw Exception('LogOut failed: ${responseData['message']}');
      }

      // Disconnect WebSocket on logout
      disconnectWebSocket();

      // ✅ Clear all tokens using the clear method
      clearTokens();

      return {'success': true, 'message': 'LogOut successfully'};
    } catch (e) {
      throw Exception('LogOut error: $e');
    }
  }

  /// Get all tokens as a map for easy storage/retrieval
  Map<String, String?> get tokens => {
        'accessToken': _accessToken,
        'refreshToken': _refreshToken,
        'sessionToken': _sessionToken,
      };

  /// Set all tokens from a map
  void setTokens(Map<String, String?> tokens) {
    _accessToken = tokens['accessToken'];
    _refreshToken = tokens['refreshToken'];
    _sessionToken = tokens['sessionToken'];
    print('All tokens set from storage');
  }

  /// Print token status for debugging
  void printTokenStatus() {
    print('=== Token Status ===');
    print(
        'Access Token: ${accessToken != null ? 'Present (${accessToken!.substring(0, 20)}...)' : 'Missing'}');
    print(
        'Refresh Token: ${refreshToken != null ? 'Present (${refreshToken!.substring(0, 20)}...)' : 'Missing'}');
    print(
        'Session Token: ${sessionToken != null ? 'Present (${sessionToken!.substring(0, 20)}...)' : 'Missing'}');
    print('Authenticated: $isAuthenticated');
    print('Can Refresh: $canRefreshToken');
    print('====================');
  }

  Map<String, dynamic>? decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token format');
      }

      final payload = parts[1];
      // Add padding if needed
      var normalizedPayload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));

      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding JWT: $e');
      return null;
    }
  }

  /// Extract user_id from access token
  String? get userIdFromToken {
    if (_accessToken == null) return null;

    final decoded = decodeJwt(_accessToken!);
    return decoded?['sub'] as String?; // 'sub' usually contains user_id in JWT
  }

  Future<Map<String, dynamic>> refreshtoken() async {
    try {
      if (!canRefreshToken) {
        throw Exception('No refresh token available');
      }

      // Extract user_id from current access token
      final userId = userIdFromToken;
      if (userId == null) {
        throw Exception('Could not extract user_id from access token');
      }

      final refreshUrl = Uri.parse('$_baseUrl/user/token');

      print('Refreshing token for user: $userId');
      print('Using refresh token: ${refreshToken!.substring(0, 20)}...');

      final response = await http.post(
        refreshUrl,
        headers: {
          'Authorization': refreshToken!,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId, // Now including the user_id from the token
        }),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Refresh Token Response: $responseData');

      if (response.statusCode != 200) {
        throw Exception('Refresh Token failed: ${responseData['message']}');
      }

      // ✅ Update tokens with new ones from response
      if (responseData['payload'] != null) {
        accessToken = responseData['payload']['access_token'];
        refreshToken = responseData['payload']['refresh_token'];

        print('Tokens refreshed successfully');
        printTokenStatus();
      }

      return {
        'success': true,
        'message': 'Token refreshed successfully',
        'access_token': accessToken,
        'refresh_token': refreshToken
      };
    } catch (e) {
      print('Token refresh error: $e');
      // Clear tokens if refresh fails
      clearTokens();
      throw Exception('Token refresh failed: ${e.toString()}');
    }
  }

  /// Helper method to refresh token and retry failed API calls
  Future<T> retryWithTokenRefresh<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } catch (e) {
      // Check if it's an authentication error (401)
      if (e.toString().contains('401') && canRefreshToken) {
        print('Authentication error detected, attempting token refresh...');

        try {
          // Refresh the token
          await refreshtoken();

          // Retry the original API call with new token
          print('Retrying API call with refreshed token...');
          return await apiCall();
        } catch (refreshError) {
          print('Token refresh failed: $refreshError');
          clearTokens();
          rethrow;
        }
      }
      rethrow;
    }
  }

  // ==================== GETTERS ====================
  bool get isWebSocketConnected {
    return _isConnected && _webSocketChannel != null;
  }

  WebSocketChannel? get currentWebSocketChannel => _webSocketChannel;

  // Add to AuthApi class
  void debugConnectionStatus() {
    print('=== WebSocket Connection Debug ===');
    print('_isConnected: $_isConnected');
    print('_webSocketChannel: ${_webSocketChannel != null}');
  }
}
