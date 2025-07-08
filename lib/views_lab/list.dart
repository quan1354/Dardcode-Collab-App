<<<<<<< HEAD
// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const title = 'Grid List';

//     return MaterialApp(
//       title: title,
//       home: Scaffold(
//         appBar: AppBar(title: const Text(title)),
//         // body: GridView.count(
//         //   // Create a grid with 2 columns.
//         //   // If you change the scrollDirection to horizontal,
//         //   // this produces 2 rows.
//         //   crossAxisCount: 2,
//         //   // Generate 100 widgets that display their index in the list.
//         //   children: List.generate(100, (index) {
//         //     return Center(
//         //       child: Text(
//         //         'Item $index',
//         //         style: TextTheme.of(context).headlineSmall,
//         //       ),
//         //     );
//         //   }),
//         // ),
//         // body: Container(
//         //   margin: const EdgeInsets.symmetric(vertical: 20),
//         //   height: 200,
//         //   child: ListView(
//         //     // This next line does the trick.
//         //     scrollDirection: Axis.horizontal,
//         //     children: <Widget>[
//         //       Container(width: 160, color: Colors.red),
//         //       Container(width: 160, color: Colors.blue),
//         //       Container(width: 160, color: Colors.green),
//         //       Container(width: 160, color: Colors.yellow),
//         //       Container(width: 160, color: Colors.orange),
//         //     ],
//         //   ),
//         // ),
//       ),
//     );
//   }
// }

// CHAPTER 2: Create lists with different types of items
// import 'package:flutter/material.dart';

// void main() {
//   runApp(
//     MyApp(
//       items: List<ListItem>.generate(
//         1000,
//         (i) => i % 6 == 0
//             ? HeadingItem('Heading $i')
//             : MessageItem('Sender $i', 'Message body $i'),
//       ),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   final List<ListItem> items;

//   const MyApp({super.key, required this.items});

//   @override
//   Widget build(BuildContext context) {
//     const title = 'Mixed List';

//     return MaterialApp(
//       title: title,
//       home: Scaffold(
//         appBar: AppBar(title: const Text(title)),
//         body: ListView.builder(
//           // Let the ListView know how many items it needs to build.
//           itemCount: items.length,
//           // Provide a builder function. This is where the magic happens.
//           // Convert each item into a widget based on the type of item it is.
//           itemBuilder: (context, index) {
//             final item = items[index];

//             return ListTile(
//               title: item.buildTitle(context),
//               subtitle: item.buildSubtitle(context),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// /// The base class for the different types of items the list can contain.
// abstract class ListItem {
//   /// The title line to show in a list item.
//   Widget buildTitle(BuildContext context);

//   /// The subtitle line, if any, to show in a list item.
//   Widget buildSubtitle(BuildContext context);
// }

// /// A ListItem that contains data to display a heading.
// class HeadingItem implements ListItem {
//   final String heading;

//   HeadingItem(this.heading);

//   @override
//   Widget buildTitle(BuildContext context) {
//     return Text(heading, style: Theme.of(context).textTheme.headlineSmall);
//   }

//   @override
//   Widget buildSubtitle(BuildContext context) => const SizedBox.shrink();
// }

// /// A ListItem that contains data to display a message.
// class MessageItem implements ListItem {
//   final String sender;
//   final String body;

//   MessageItem(this.sender, this.body);

//   @override
//   Widget buildTitle(BuildContext context) => Text(sender);

//   @override
//   Widget buildSubtitle(BuildContext context) => Text(body);
// }

// CHAPTER 3: Create a list with a floating navigation bar
// import 'package:flutter/cupertino.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const title = 'Floating Navigation Bar';

//     return CupertinoApp(
//       title: title,
//       home: CupertinoPageScaffold(
//         // No navigation bar provided to CupertinoPageScaffold,
//         // only a body with a CustomScrollView.
//         child: CustomScrollView(
//           slivers: [
//             // Add the navigation bar to the CustomScrollView.
//             const CupertinoSliverNavigationBar(
//               // Provide a standard title.
//               largeTitle: Text(title),
//             ),
//             // Next, create a SliverList
//             SliverList.builder(
//               // The builder function returns a CupertinoListTile with a title
//               // that displays the index of the current item.
//               itemBuilder: (context, index) =>
//                   CupertinoListTile(title: Text('Item #$index')),
//               // Builds 50 CupertinoListTile
//               itemCount: 50,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// CHAPTER 4: Create a basic list - ListView
// import 'package:flutter/material.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const title = 'Basic List';

//     return MaterialApp(
//       title: title,
//       home: Scaffold(
//         appBar: AppBar(title: const Text(title)),
//         body: ListView(
//           children: const <Widget>[
//             ListTile(leading: Icon(Icons.map), title: Text('Map')),
//             ListTile(leading: Icon(Icons.photo_album), title: Text('Album')),
//             ListTile(leading: Icon(Icons.phone), title: Text('Phone')),
//           ],
//         ),
//       ),
//     );
//   }
// }

// CHAPTER 5: Create a long list with ListView.builder
// import 'package:flutter/material.dart';

// void main() {
//   runApp(
//     MyApp(
//       items: List<String>.generate(10000, (i) => 'Item $i'),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   final List<String> items;

//   const MyApp({super.key, required this.items});

//   @override
//   Widget build(BuildContext context) {
//     const title = 'Long List';

//     return MaterialApp(
//       title: title,
//       home: Scaffold(
//         appBar: AppBar(title: const Text(title)),
//         body: ListView.builder(
//           itemCount: items.length,
//           prototypeItem: ListTile(title: Text(items.first)),
//           itemBuilder: (context, index) {
//             return ListTile(title: Text(items[index]));
//           },
//         ),
//       ),
//     );
//   }
// }

// CHAPTER 6: Create a list with items spaced evenly
// import 'package:flutter/material.dart';

// void main() => runApp(const SpacedItemsList());

// class SpacedItemsList extends StatelessWidget {
//   const SpacedItemsList({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const items = 4;

//     return MaterialApp(
//       title: 'Flutter Demo',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         cardTheme: CardThemeData(color: Colors.blue.shade50),
//       ),
//       home: Scaffold(
//         body: LayoutBuilder(
//           builder: (context, constraints) {
//             return SingleChildScrollView(
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: List.generate(
//                     items,
//                     (index) => ItemWidget(text: 'Item $index'),
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class ItemWidget extends StatelessWidget {
//   const ItemWidget({super.key, required this.text});

//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: SizedBox(height: 100, child: Center(child: Text(text))),
//     );
//   }
// }
=======
aaa
>>>>>>> 0cd7e6c61dc12e74d14a067353f0df5fcee6386d
