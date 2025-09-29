import 'package:flutter/material.dart';

// CHAPTER 1: Drawer Demo
// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   static const appTitle = 'Drawer Demo';

//   @override
//   Widget build(BuildContext context) {
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
//   int _selectedIndex = 0;
//   static const TextStyle optionStyle = TextStyle(
//     fontSize: 30,
//     fontWeight: FontWeight.bold,
//   );
//   static const List<Widget> _widgetOptions = <Widget>[
//     Text('Index 0: Home', style: optionStyle),
//     Text('Index 1: Business', style: optionStyle),
//     Text('Index 2: School', style: optionStyle),
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//         leading: Builder(
//           builder: (context) {
//             return IconButton(
//               icon: const Icon(Icons.menu),
//               onPressed: () {
//                 Scaffold.of(context).openDrawer();
//               },
//             );
//           },
//         ),
//       ),
//       body: Center(child: _widgetOptions[_selectedIndex]),
//       drawer: Drawer(
//         // Add a ListView to the drawer. This ensures the user can scroll
//         // through the options in the drawer if there isn't enough vertical
//         // space to fit everything.
//         child: ListView(
//           // Important: Remove any padding from the ListView.
//           padding: EdgeInsets.zero,
//           children: [
//             const DrawerHeader(
//               decoration: BoxDecoration(color: Colors.blue),
//               child: Text('Drawer Header'),
//             ),
//             ListTile(
//               title: const Text('Home'),
//               selected: _selectedIndex == 0,
//               onTap: () {
//                 // Update the state of the app
//                 _onItemTapped(0);
//                 // Then close the drawer
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               title: const Text('Business'),
//               selected: _selectedIndex == 1,
//               onTap: () {
//                 // Update the state of the app
//                 _onItemTapped(1);
//                 // Then close the drawer
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               title: const Text('School'),
//               selected: _selectedIndex == 2,
//               onTap: () {
//                 // Update the state of the app
//                 _onItemTapped(2);
//                 // Then close the drawer
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


//CHAPTER 2: SNACKBAR 
// import 'package:flutter/material.dart';

// void main() => runApp(const SnackBarDemo());

// class SnackBarDemo extends StatelessWidget {
//   const SnackBarDemo({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'SnackBar Demo',
//       home: Scaffold(
//         appBar: AppBar(title: const Text('SnackBar Demo')),
//         body: const SnackBarPage(),
//       ),
//     );
//   }
// }

// class SnackBarPage extends StatelessWidget {
//   const SnackBarPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: ElevatedButton(
//         onPressed: () {
//           final snackBar = SnackBar(
//             content: const Text('Yay! A SnackBar!'),
//             action: SnackBarAction(
//               label: 'Undo',
//               onPressed: () {
//                 // Some code to undo the change.
//               },
//             ),
//           );

//           // Find the ScaffoldMessenger in the widget tree
//           // and use it to show a SnackBar.
//           ScaffoldMessenger.of(context).showSnackBar(snackBar);
//         },
//         child: const Text('Show SnackBar'),
//       ),
//     );
//   }
// }

// CHAPTER 3: ROTATE ORIENTATION
// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const appTitle = 'Orientation Demo';

//     return const MaterialApp(
//       title: appTitle,
//       home: OrientationList(title: appTitle),
//     );
//   }
// }

// class OrientationList extends StatelessWidget {
//   final String title;

//   const OrientationList({super.key, required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(title)),
//       body: OrientationBuilder(
//         builder: (context, orientation) {
//           return GridView.count(
//             // Create a grid with 2 columns in portrait mode, or
//             // 3 columns in landscape mode.
//             crossAxisCount: orientation == Orientation.portrait ? 2 : 3,
//             // Generate 100 widgets that display their index in the list.
//             children: List.generate(100, (index) {
//               return Center(
//                 child: Text(
//                   'Item $index',
//                   style: TextTheme.of(context).displayLarge,
//                 ),
//               );
//             }),
//           );
//         },
//       ),
//     );
//   }
// }

// CHAPTER 4: Use Themes to share colors and font styles
// import 'package:flutter/material.dart';
// // Include the Google Fonts package to provide more text format options
// // https://pub.dev/packages/google_fonts
// import 'package:google_fonts/google_fonts.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const appName = 'Custom Themes';

//     return MaterialApp(
//       title: appName,
//       theme: ThemeData(
//         // Define the default brightness and colors.
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.purple,
//           // TRY THIS: Change to "Brightness.light"
//           //           and see that all colors change
//           //           to better contrast a light background.
//           brightness: Brightness.dark,
//         ),

//         // Define the default `TextTheme`. Use this to specify the default
//         // text styling for headlines, titles, bodies of text, and more.
//         textTheme: TextTheme(
//           displayLarge: const TextStyle(
//             fontSize: 72,
//             fontWeight: FontWeight.bold,
//           ),
//           // TRY THIS: Change one of the GoogleFonts
//           //           to "lato", "poppins", or "lora".
//           //           The title uses "titleLarge"
//           //           and the middle text uses "bodyMedium".
//           titleLarge: GoogleFonts.oswald(
//             fontSize: 30,
//             fontStyle: FontStyle.italic,
//           ),
//           bodyMedium: GoogleFonts.merriweather(),
//           displaySmall: GoogleFonts.pacifico(),
//         ),
//       ),
//       home: const MyHomePage(title: appName),
//     );
//   }
// }

// class MyHomePage extends StatelessWidget {
//   final String title;

//   const MyHomePage({super.key, required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           title,
//           style: Theme.of(context).textTheme.titleLarge!.copyWith(
//             color: Theme.of(context).colorScheme.onSecondary,
//           ),
//         ),
//         backgroundColor: Theme.of(context).colorScheme.secondary,
//       ),
//       body: Center(
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//           color: Theme.of(context).colorScheme.primary,
//           child: Text(
//             'Text with a background color',
//             // TRY THIS: Change the Text value
//             //           or change the Theme.of(context).textTheme
//             //           to "displayLarge" or "displaySmall".
//             style: Theme.of(context).textTheme.bodyMedium!.copyWith(
//               color: Theme.of(context).colorScheme.onPrimary,
//             ),
//           ),
//         ),
//       ),
//       floatingActionButton: Theme(
//         data: Theme.of(context).copyWith(
//           // TRY THIS: Change the seedColor to "Colors.red" or
//           //           "Colors.blue".
//           colorScheme: ColorScheme.fromSeed(
//             seedColor: Colors.pink,
//             brightness: Brightness.dark,
//           ),
//         ),
//         child: FloatingActionButton(
//           onPressed: () {},
//           child: const Icon(Icons.add),
//         ),
//       ),
//     );
//   }
// }

// CHAPTER 5: WORK WITH TABS
// import 'package:flutter/material.dart';

// void main() {
//   runApp(const TabBarDemo());
// }

// class TabBarDemo extends StatelessWidget {
//   const TabBarDemo({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: DefaultTabController(
//         length: 3,
//         child: Scaffold(
//           appBar: AppBar(
//             bottom: const TabBar(
//               tabs: [
//                 Tab(icon: Icon(Icons.directions_car)),
//                 Tab(icon: Icon(Icons.directions_transit)),
//                 Tab(icon: Icon(Icons.directions_bike)),
//               ],
//             ),
//             title: const Text('Tabs Demo'),
//           ),
//           body: const TabBarView(
//             children: [
//               Icon(Icons.directions_car),
//               Icon(Icons.directions_transit),
//               Icon(Icons.directions_bike),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }