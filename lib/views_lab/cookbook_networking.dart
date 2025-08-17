// import 'package:http/http.dart' as http;
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'dart:io';

// // Future is a core Dart class for working with async operations.
// // connect to servers using WebSockets. WebSockets allow for two-way communication with a server without polling.

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
//   // late Future<Album> _futureAlbum;
//   Future<Album>? _futureAlbum;
//   final TextEditingController _controller = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     // futureAlbum = fetchAlbum();
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
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const title = 'WebSocket Demo';
//     return const MaterialApp(title: title, home: MyHomePage(title: title));
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
//   // ##
//   final _channel = WebSocketChannel.connect(
//     Uri.parse('wss://echo.websocket.events'),
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
//       // ##
//       _channel.sink.add(_controller.text);
//     }
//   }

//   @override
//   void dispose() {
//     // ##
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
//   // ##
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

