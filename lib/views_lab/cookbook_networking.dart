import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';

// Future is a core Dart class for working with async operations.
// Single-value asynchronous operation
// Represents a value that will be available at some point
// Can complete with a value or an error
// One-time emission - once it delivers the value, it's done

// What is a factory ?
// A factory constructor is a special constructor that:
// Doesn't always create a new instance
// Can return an existing instance or a subclass instance
// Can contain logic before returning an object
// Is useful for JSON parsing, caching, etc.

// connect to servers using WebSockets. WebSockets allow for two-way communication with a server without polling.

// Future<Album> fetchAlbum() async {
//   final response = await http.get(
//     Uri.parse('https://jsonplaceholder.typicode.com/albums/1'),
//     // Send authorization headers to the backend.
//     // headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
//   );

//   if (response.statusCode == 200) {
//     // If the server did return a 200 OK response,
//     // then parse the JSON.
//     return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
//   } else {
//     // If the server did not return a 200 OK response,
//     // then throw an exception.
//     throw Exception('Failed to load album');
//   }
// }

// Future<Album> createAlbum(String title) async {
//   final response = await http.post(
//     Uri.parse('https://jsonplaceholder.typicode.com/albums'),
//     headers: <String, String>{
//       'Content-Type': 'application/json; charset=UTF-8',
//     },
//     body: jsonEncode(<String, String>{'title': title}),
//   );

//   if (response.statusCode == 201) {
//     // If the server did return a 201 CREATED response,
//     // then parse the JSON.
//     return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
//   } else {
//     // If the server did not return a 201 CREATED response,
//     // then throw an exception.
//     throw Exception('Failed to create album.');
//   }
// }

// class Album {
//   final int userId;
//   final int id;
//   final String title;

//   const Album({required this.userId, required this.id, required this.title});

//   factory Album.fromJson(Map<String, dynamic> json) {
//     return switch (json) {
//       {'userId': int userId, 'id': int id, 'title': String title} => Album(
//           userId: userId,
//           id: id,
//           title: title,
//         ),
//       _ => throw const FormatException('Failed to load album.'),
//     };
//   }
// }

// void main() => runApp(const MyApp());

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   //late Future<Album> _futureAlbum;
//   Future<Album>? _futureAlbum;
//   final TextEditingController _controller = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _futureAlbum = fetchAlbum();
//   }

//   FutureBuilder<Album> buildFutureBuilder() {
//     return FutureBuilder<Album>(
//       future: _futureAlbum,
//       builder: (context, snapshot) {
//         if (snapshot.hasData) {
//           return Text(snapshot.data!.title);
//         } else if (snapshot.hasError) {
//           return Text('${snapshot.error}');
//         }

//         return const CircularProgressIndicator();
//       },
//     );
//   }

//  Column buildColumn() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: <Widget>[
//         TextField(
//           controller: _controller,
//           decoration: const InputDecoration(hintText: 'Enter Title'),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             setState(() {
//               _futureAlbum = createAlbum(_controller.text);
//             });
//           },
//           child: const Text('Create Data'),
//         ),
//       ],
//     );
//   }
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Fetch Data Example',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: Scaffold(
//         appBar: AppBar(title: const Text('Fetch Data Example')),
//         body: Column(
//           mainAxisAlignment:
//               MainAxisAlignment.center, // Center the content vertically
//           children: [
//             // FutureBuilder<Album>(
//             //   future: futureAlbum,
//             //   builder: (context, snapshot) {
//             //     if (snapshot.connectionState == ConnectionState.waiting) {
//             //       return const CircularProgressIndicator();
//             //     } else if (snapshot.hasError) {
//             //       return Text('Error: ${snapshot.error}');
//             //     } else if (snapshot.hasData) {
//             //       return Text(snapshot.data!
//             //           .title); // No need for .toString() since title is already a String
//             //     } else {
//             //       return const Text('No data found');
//             //     }
//             //   },
//             // ),
//             Container(
//               alignment: Alignment.center,
//               padding: const EdgeInsets.all(8),
//               child:
//                   (_futureAlbum == null) ? buildColumn() : buildFutureBuilder(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// ======================== CHAPTER 2: Web Socket ===========================================
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WebSocketTest(),
    );
  }
}

String? _accessToken;

Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    print('Logging in with email: $email');
    final url = Uri.parse('https://d3v904dal0xey8.cloudfront.net/user/login');
    final url_mfa =
        Uri.parse('https://d3v904dal0xey8.cloudfront.net/user/login/mfa');

    // Step 1: Initial login to get session token
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
    print('Login response: $responseData');

    if (response.statusCode != 200) {
      throw Exception(responseData['message'] ?? 'Login failed');
    }

    final sessionToken = responseData['payload']['session_token'];
    print('Session token received');

    // Step 2: MFA verification to get access token
    final responseMfa = await http.post(
      url_mfa,
      headers: {
        'Authorization': sessionToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'mfa_code': '123456'}),
    );

    final mfaData = jsonDecode(responseMfa.body) as Map<String, dynamic>;
    print('MFA response: $mfaData');

    if (responseMfa.statusCode != 200) {
      throw Exception(mfaData['message'] ?? 'MFA verification failed');
    }

    _accessToken = mfaData['payload']['access_token'];
    print('Access token: $_accessToken');

    return mfaData;
  } catch (e) {
    throw Exception('Login error: ${e.toString()}');
  }
}

Future<String> getWebSocketToken() async {
  try {
    if (_accessToken == null) {
      throw Exception('No access token available. Please login first.');
    }

    print(
        'Fetching WebSocket token with access token: ${_accessToken!.substring(0, 20)}...');

    final response = await http.post(
      Uri.parse('https://d3v904dal0xey8.cloudfront.net/chat/ws_token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _accessToken!,
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

class WebSocketTest extends StatefulWidget {
  @override
  _WebSocketTestState createState() => _WebSocketTestState();
}

class _WebSocketTestState extends State<WebSocketTest> {
  WebSocketChannel? _channel;
  List<String> _messages = [];
  TextEditingController _controller = TextEditingController();
  bool _isConnected = false;
  String? _wsToken;
  bool _isLoadingToken = false;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _loginAndConnect();
  }

  // Login first, then get WebSocket token and connect
  Future<void> _loginAndConnect() async {
    setState(() {
      _isLoggingIn = true;
      _messages.add('Logging in...');
    });

    try {
      // Login with provided credentials
      await login('helicapter@gmail.com', 'qweqwe123');

      setState(() {
        _messages.add('Login successful');
        _isLoggingIn = false;
      });

      // Now fetch WebSocket token and connect
      _fetchWsTokenAndConnect();
    } catch (e) {
      setState(() {
        _messages.add('Login failed: $e');
        _isLoggingIn = false;
        _isLoadingToken = false;
      });
    }
  }

  // Fetch WebSocket token from API and then connect
  Future<void> _fetchWsTokenAndConnect() async {
    setState(() {
      _isLoadingToken = true;
      _messages.add('Fetching WebSocket token...');
    });

    try {
      final token = await getWebSocketToken();

      setState(() {
        _wsToken = token;
        _messages.add('WebSocket token received successfully');
      });

      _connectWebSocket(token);
    } catch (e) {
      setState(() {
        _messages.add('Error fetching WebSocket token: $e');
        _isLoadingToken = false;
      });
    }
  }

  void _connectWebSocket(String token) {
    try {
      final channel = IOWebSocketChannel.connect(
        'wss://srqaesich3.execute-api.us-east-1.amazonaws.com/stage?token=$token',
      );

      setState(() {
        _channel = channel;
        _isConnected = true;
        _isLoadingToken = false;
        _messages.add('Connected to WebSocket with token');
      });

      // Listen for incoming messages
      channel.stream.listen(
        (message) {
          setState(() {
            _messages.add('Received: $message');
          });
        },
        onError: (error) {
          setState(() {
            _messages.add('Error: $error');
            _isConnected = false;
            _isLoadingToken = false;
          });
        },
        onDone: () {
          setState(() {
            _messages.add('WebSocket connection closed');
            _isConnected = false;
            _isLoadingToken = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _messages.add('Connection failed: $e');
        _isConnected = false;
        _isLoadingToken = false;
      });
    }
  }

  void _sendMessage() {
    if (_channel != null && _controller.text.isNotEmpty) {
      final messageData = {
        "action": "send_message",
        "event": {
          "message": _controller.text,
        },
        "other_user_id": "10000038",
      };

      final jsonMessage = jsonEncode(messageData);
      _channel!.sink.add(jsonMessage);

      setState(() {
        _messages.add('Sent: ${_controller.text}');
        _messages.add('JSON: $jsonMessage');
      });
      _controller.clear();
    }
  }

  void _sendTypingEvent() {
    if (_channel != null) {
      final typingData = {
        "action": "send_message",
        "event": "typing",
        "other_user_id": "10000038",
      };

      final jsonMessage = jsonEncode(typingData);
      _channel!.sink.add(jsonMessage);

      setState(() {
        _messages.add('Sent: Typing event');
        _messages.add('JSON: $jsonMessage');
      });
    }
  }

  void _disconnect() {
    _channel?.sink.close();
    setState(() {
      _isConnected = false;
      _messages.add('Disconnected from WebSocket');
    });
  }

  void _reconnect() {
    _disconnect();
    _loginAndConnect();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebSocket Test'),
        backgroundColor: _isConnected
            ? Colors.green
            : _isLoadingToken || _isLoggingIn
                ? Colors.orange
                : Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Connection Status
            Row(
              children: [
                Text(
                  'Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? Colors.green
                        : _isLoadingToken || _isLoggingIn
                            ? Colors.orange
                            : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                if (_isLoggingIn)
                  Text('Logging in...')
                else if (_isLoadingToken)
                  Text('Fetching Token...')
                else
                  Text(_isConnected ? 'Connected' : 'Disconnected'),
                Spacer(),
                ElevatedButton(
                  onPressed:
                      (_isLoadingToken || _isLoggingIn) ? null : _reconnect,
                  child: Text('Reconnect'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      (_isLoadingToken || _isLoggingIn) ? null : _disconnect,
                  child: Text('Disconnect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Access Token Info
            if (_accessToken != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Access Token: ${_accessToken!.substring(0, 20)}...',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            SizedBox(height: 8),

            // WebSocket Token Info
            if (_wsToken != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'WebSocket Token: ${_wsToken!.substring(0, 20)}...',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            SizedBox(height: 16),

            // Message Input and Buttons
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter message to send',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: _isConnected && !_isLoadingToken && !_isLoggingIn,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isConnected && !_isLoadingToken && !_isLoggingIn
                      ? _sendMessage
                      : null,
                  child: Text('Send'),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Typing Event Button
            ElevatedButton(
              onPressed: _isConnected && !_isLoadingToken && !_isLoggingIn
                  ? _sendTypingEvent
                  : null,
              child: Text('Send Typing Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),
            SizedBox(height: 16),

            // Loading Indicators
            if (_isLoggingIn)
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Logging in...'),
                  SizedBox(height: 16),
                ],
              ),
            if (_isLoadingToken)
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Fetching WebSocket token...'),
                  SizedBox(height: 16),
                ],
              ),

            // Messages Display
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        _messages[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: _messages[index].contains('Error')
                              ? Colors.red
                              : _messages[index].contains('Connected') ||
                                      _messages[index].contains('successful')
                                  ? Colors.green
                                  : null,
                        ),
                      ),
                      tileColor: index % 2 == 0 ? Colors.grey[100] : null,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const title = 'WebSocket Demo';
//     return const MaterialApp(
//       title: title,
//       home: MyHomePage(title: title),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   final TextEditingController _controller = TextEditingController();
//   final _channel = WebSocketChannel.connect(
//     Uri.parse('wss://srqaesich3.execute-api.us-east-1.amazonaws.com/stage'),
//   );

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.title)),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Form(
//               child: TextFormField(
//                 controller: _controller,
//                 decoration: const InputDecoration(labelText: 'Send a message'),
//               ),
//             ),
//             const SizedBox(height: 24),
//             StreamBuilder(
//               stream: _channel.stream,
//               builder: (context, snapshot) {
//                 return Text(snapshot.hasData ? '${snapshot.data}' : '');
//               },
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _sendMessage,
//         tooltip: 'Send message',
//         child: const Icon(Icons.send),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }

//   void _sendMessage() {
//     if (_controller.text.isNotEmpty) {
//       _channel.sink.add(_controller.text);
//     }
//   }

//   @override
//   void dispose() {
//     _channel.sink.close();
//     _controller.dispose();
//     super.dispose();
//   }
// }

// ====================== CHAPTER 3: PARSE JASON IN BACKGROUND ========================
// import 'dart:async';
// import 'dart:convert';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// // providing an http.Client to the function in this example.makes function easier to test and use in different environments.
// Future<List<Photo>> fetchPhotos(http.Client client) async {
//   final response = await client.get(
//     Uri.parse('https://jsonplaceholder.typicode.com/photos'),
//   );

//   // Use the compute function to run parsePhotos in a separate isolate.
//   return compute(parsePhotos, response.body);
// }

// // A function that converts a response body into a List<Photo>.
// List<Photo> parsePhotos(String responseBody) {
//   final parsed =
//       (jsonDecode(responseBody) as List).cast<Map<String, dynamic>>();

//   return parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
// }

// class Photo {
//   final int albumId;
//   final int id;
//   final String title;
//   final String url;
//   final String thumbnailUrl;

//   const Photo({
//     required this.albumId,
//     required this.id,
//     required this.title,
//     required this.url,
//     required this.thumbnailUrl,
//   });

//   factory Photo.fromJson(Map<String, dynamic> json) {
//     return Photo(
//       albumId: json['albumId'] as int,
//       id: json['id'] as int,
//       title: json['title'] as String,
//       url: json['url'] as String,
//       thumbnailUrl: json['thumbnailUrl'] as String,
//     );
//   }
// }

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const appTitle = 'Isolate Demo';

//     return const MaterialApp(
//       title: appTitle,
//       home: MyHomePage(title: appTitle),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   late Future<List<Photo>> futurePhotos;

//   @override
//   void initState() {
//     super.initState();
//     futurePhotos = fetchPhotos(http.Client());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.title)),
//        // ##
//       body: FutureBuilder<List<Photo>>(
//         future: futurePhotos,
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return const Center(child: Text('An error has occurred!'));
//           } else if (snapshot.hasData) {
//             return PhotosList(photos: snapshot.data!);
//           } else {
//             return const Center(child: CircularProgressIndicator());
//           }
//         },
//       ),
//     );
//   }
// }

// class PhotosList extends StatelessWidget {
//   const PhotosList({super.key, required this.photos});

//   final List<Photo> photos;

//   @override
//   Widget build(BuildContext context) {
//     return GridView.builder(
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//       ),
//       itemCount: photos.length,
//       itemBuilder: (context, index) {
//         return Image.network(photos[index].thumbnailUrl);
//       },
//     );
//   }
// }
