// CHAPTER 1: LAYOUTS
// We can make all the widgets as variables.
// final stars = Row(
//   mainAxisSize: MainAxisSize.min,
//   children: [
//     Icon(Icons.star, color: Colors.green[500]),
//     Icon(Icons.star, color: Colors.green[500]),
//     Icon(Icons.star, color: Colors.green[500]),
//     const Icon(Icons.star, color: Colors.black),
//     const Icon(Icons.star, color: Colors.black),
//   ],
// );

// final ratings = Container(
//   padding: const EdgeInsets.all(20),
//   child: Row(
//     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//     children: [
//       stars,
//       const Text(
//         '170 Reviews',
//         style: TextStyle(
//           color: Colors.black,
//           fontWeight: FontWeight.w800,
//           fontFamily: 'Roboto',
//           letterSpacing: 0.5,
//           fontSize: 20,
//         ),
//       ),
//     ],
//   ),
// );

// const descTextStyle = TextStyle(
//   color: Colors.black,
//   fontWeight: FontWeight.w800,
//   fontFamily: 'Roboto',
//   letterSpacing: 0.5,
//   fontSize: 18,
//   height: 2,
// );

// // DefaultTextStyle.merge() allows you to create a default text
// // style that is inherited by its child and all subsequent children.
// final iconList = DefaultTextStyle.merge(
//   style: descTextStyle,
//   child: Container(
//     padding: const EdgeInsets.all(20),
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         Column(
//           children: [
//             Icon(Icons.kitchen, color: Colors.green[500]),
//             const Text('PREP:'),
//             const Text('25 min'),
//           ],
//         ),
//         Column(
//           children: [
//             Icon(Icons.timer, color: Colors.green[500]),
//             const Text('COOK:'),
//             const Text('1 hr'),
//           ],
//         ),
//         Column(
//           children: [
//             Icon(Icons.restaurant, color: Colors.green[500]),
//             const Text('FEEDS:'),
//             const Text('4-6'),
//           ],
//         ),
//       ],
//     ),
//   ),
// );

// final leftColumn = Container(
//   padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
//   child: Column(children: [titleText, subTitle, ratings, iconList]),
// );

// SESSION: GRID VIEW
// Widget _buildGrid() => GridView.extent(
//   maxCrossAxisExtent: 150,
//   padding: const EdgeInsets.all(4),
//   mainAxisSpacing: 4,
//   crossAxisSpacing: 4,
//   children: _buildGridTileList(30),
// );

// The images are saved with names pic0.jpg, pic1.jpg...pic29.jpg.
// The List.generate() constructor allows an easy way to create
// a list when objects have a predictable naming pattern.
// List<Widget> _buildGridTileList(int count) =>
//     List.generate(count, (i) => Image.asset('images/pic$i.jpg'));

// CHAPTER 2: BUILD A LAYOUT
// import 'package:flutter/material.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const String appTitle = 'Flutter layout demo';
//     return MaterialApp(
//       title: appTitle,
//       home: Scaffold(
//         appBar: AppBar(title: const Text(appTitle)),
//         body: const SingleChildScrollView(
//           child: Column(
//             children: [
//               ImageSection(image: 'Assets/lake.jpg'),
//               TitleSection(
//                 name: 'Oeschinen Lake Campground',
//                 location: 'Kandersteg, Switzerland',
//               ),
//               ButtonSection(),
//               TextSection(
//                 description:
//                     'Lake Oeschinen lies at the foot of the Blüemlisalp in the '
//                     'Bernese Alps. Situated 1,578 meters above sea level, it '
//                     'is one of the larger Alpine Lakes. A gondola ride from '
//                     'Kandersteg, followed by a half-hour walk through pastures '
//                     'and pine forest, leads you to the lake, which warms to 20 '
//                     'degrees Celsius in the summer. Activities enjoyed here '
//                     'include rowing, and riding the summer toboggan run.',
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class TitleSection extends StatelessWidget {
//   const TitleSection({super.key, required this.name, required this.location});

//   final String name;
//   final String location;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(32),
//       child: Row(
//         children: [
//           Expanded(
//             /*1*/
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 /*2*/
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 8),
//                   child: Text(
//                     name,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 Text(location, style: TextStyle(color: Colors.grey[500])),
//               ],
//             ),
//           ),
//           /*3*/
//           Icon(Icons.star, color: Colors.red[500]),
//           const Text('41'),
//         ],
//       ),
//     );
//   }
// }

// class ButtonSection extends StatelessWidget {
//   const ButtonSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final Color color = Theme.of(context).primaryColor;
//     return SizedBox(
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           ButtonWithText(color: color, icon: Icons.call, label: 'CALL'),
//           ButtonWithText(color: color, icon: Icons.near_me, label: 'ROUTE'),
//           ButtonWithText(color: color, icon: Icons.share, label: 'SHARE'),
//         ],
//       ),
//     );
//   }
// }

// class ButtonWithText extends StatelessWidget {
//   const ButtonWithText({
//     super.key,
//     required this.color,
//     required this.icon,
//     required this.label,
//   });

//   final Color color;
//   final IconData icon;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(icon, color: color),
//         Padding(
//           padding: const EdgeInsets.only(top: 8),
//           child: Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w400,
//               color: color,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class TextSection extends StatelessWidget {
//   const TextSection({super.key, required this.description});

//   final String description;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(32),
//       child: Text(description, softWrap: true),
//     );
//   }
// }

// // #docregion image-asset
// class ImageSection extends StatelessWidget {
//   const ImageSection({super.key, required this.image});

//   final String image;

//   @override
//   Widget build(BuildContext context) {
//     // #docregion image-asset
//     return Image.asset(image, width: 600, height: 240, fit: BoxFit.cover);
//     // #enddocregion image-asset
//   }
// }
// // #enddocregion image-section

// // #docregion favorite-widget
// class FavoriteWidget extends StatefulWidget {
//   const FavoriteWidget({super.key});

//   @override
//   State<FavoriteWidget> createState() => _FavoriteWidgetState();
// }
// // #enddocregion favorite-widget

// // #docregion favorite-state, favorite-state-fields, favorite-state-build
// class _FavoriteWidgetState extends State<FavoriteWidget> {
//   // #enddocregion favorite-state-build
//   bool _isFavorited = true;
//   int _favoriteCount = 41;
//   // #enddocregion favorite-state-fields

//   // #docregion toggle-favorite
//   void _toggleFavorite() {
//     setState(() {
//       if (_isFavorited) {
//         _favoriteCount -= 1;
//         _isFavorited = false;
//       } else {
//         _favoriteCount += 1;
//         _isFavorited = true;
//       }
//     });
//   }
//   // #enddocregion toggle-favorite

//   // #docregion favorite-state-build
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           padding: const EdgeInsets.all(0),
//           child: IconButton(
//             padding: const EdgeInsets.all(0),
//             alignment: Alignment.center,
//             icon: (_isFavorited
//                 ? const Icon(Icons.star)
//                 : const Icon(Icons.star_border)),
//             color: Colors.red[500],
//             onPressed: _toggleFavorite,
//           ),
//         ),
//         SizedBox(width: 18, child: SizedBox(child: Text('$_favoriteCount'))),
//       ],
//     );
//   }

//   // #docregion favorite-state-fields
// }


// CHAPTER 3: LIST AND GRID VIEWS
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

// import 'package:flutter/material.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const title = 'Horizontal List';

//     return MaterialApp(
//       title: title,
//       home: Scaffold(
//         appBar: AppBar(title: const Text(title)),
//         body: Container(
//           margin: const EdgeInsets.symmetric(vertical: 20),
//           height: 200,
//           child: ListView(
//             // This next line does the trick.
//             scrollDirection: Axis.horizontal,
//             children: <Widget>[
//               Container(width: 160, color: Colors.red),
//               Container(width: 160, color: Colors.blue),
//               Container(width: 160, color: Colors.green),
//               Container(width: 160, color: Colors.yellow),
//               Container(width: 160, color: Colors.orange),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

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
//         body: GridView.count(
//           // Create a grid with 2 columns.
//           // If you change the scrollDirection to horizontal,
//           // this produces 2 rows.
//           crossAxisCount: 2,
//           // Generate 100 widgets that display their index in the list.
//           children: List.generate(100, (index) {
//             return Center(
//               child: Text(
//                 'Item $index',
//                 style: TextTheme.of(context).headlineSmall,
//               ),
//             );
//           }),
//         ),
//       ),
//     );
//   }
// }

// !!! MIXED LISTS !!!
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

// CHAPTER 4: SCROLLING
// !!!parallax effect!!!
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const Color darkBlue = Color.fromARGB(255, 18, 32, 47);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: darkBlue),
      debugShowCheckedModeBanner: false,
      home: const Scaffold(body: Center(child: ExampleParallax())),
    );
  }
}

class ExampleParallax extends StatelessWidget {
  const ExampleParallax({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          for (final location in locations)
            LocationListItem(
              imageUrl: location.imageUrl,
              name: location.name,
              country: location.place,
            ),
        ],
      ),
    );
  }
}

class LocationListItem extends StatelessWidget {
  LocationListItem({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.country,
  });

  final String imageUrl;
  final String name;
  final String country;
  final GlobalKey _backgroundImageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              _buildParallaxBackground(context),
              _buildGradient(),
              _buildTitleAndSubtitle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParallaxBackground(BuildContext context) {
    return Flow(
      delegate: ParallaxFlowDelegate(
        scrollable: Scrollable.of(context),
        listItemContext: context,
        backgroundImageKey: _backgroundImageKey,
      ),
      children: [
        Image.network(imageUrl, key: _backgroundImageKey, fit: BoxFit.cover),
      ],
    );
  }

  Widget _buildGradient() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.6, 0.95],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleAndSubtitle() {
    return Positioned(
      left: 20,
      bottom: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            country,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class ParallaxFlowDelegate extends FlowDelegate {
  ParallaxFlowDelegate({
    required this.scrollable,
    required this.listItemContext,
    required this.backgroundImageKey,
  }) : super(repaint: scrollable.position);


  final ScrollableState scrollable;
  final BuildContext listItemContext;
  final GlobalKey backgroundImageKey;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return BoxConstraints.tightFor(width: constraints.maxWidth);
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    // Calculate the position of this list item within the viewport.
    final scrollableBox = scrollable.context.findRenderObject() as RenderBox;
    final listItemBox = listItemContext.findRenderObject() as RenderBox;
    final listItemOffset = listItemBox.localToGlobal(
      listItemBox.size.centerLeft(Offset.zero),
      ancestor: scrollableBox,
    );

    // Determine the percent position of this list item within the
    // scrollable area.
    final viewportDimension = scrollable.position.viewportDimension;
    final scrollFraction = (listItemOffset.dy / viewportDimension).clamp(
      0.0,
      1.0,
    );

    // Calculate the vertical alignment of the background
    // based on the scroll percent.
    final verticalAlignment = Alignment(0.0, scrollFraction * 2 - 1);

    // Convert the background alignment into a pixel offset for
    // painting purposes.
    final backgroundSize =
        (backgroundImageKey.currentContext!.findRenderObject() as RenderBox)
            .size;
    final listItemSize = context.size;
    final childRect = verticalAlignment.inscribe(
      backgroundSize,
      Offset.zero & listItemSize,
    );

    // Paint the background.
    context.paintChild(
      0,
      transform: Transform.translate(
        offset: Offset(0.0, childRect.top),
      ).transform,
    );
  }

  @override
  bool shouldRepaint(ParallaxFlowDelegate oldDelegate) {
    return scrollable != oldDelegate.scrollable ||
        listItemContext != oldDelegate.listItemContext ||
        backgroundImageKey != oldDelegate.backgroundImageKey;
  }

}

class Parallax extends SingleChildRenderObjectWidget {
  const Parallax({super.key, required Widget background})
    : super(child: background);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderParallax(scrollable: Scrollable.of(context));
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderParallax renderObject,
  ) {
    renderObject.scrollable = Scrollable.of(context);
  }
}

class ParallaxParentData extends ContainerBoxParentData<RenderBox> {}

class RenderParallax extends RenderBox
    with RenderObjectWithChildMixin<RenderBox>, RenderProxyBoxMixin {
  RenderParallax({required ScrollableState scrollable})
    : _scrollable = scrollable;

  ScrollableState _scrollable;

  ScrollableState get scrollable => _scrollable;

  set scrollable(ScrollableState value) {
    if (value != _scrollable) {
      if (attached) {
        _scrollable.position.removeListener(markNeedsLayout);
      }
      _scrollable = value;
      if (attached) {
        _scrollable.position.addListener(markNeedsLayout);
      }
    }
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    _scrollable.position.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _scrollable.position.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! ParallaxParentData) {
      child.parentData = ParallaxParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;

    // Force the background to take up all available width
    // and then scale its height based on the image's aspect ratio.
    final background = child!;
    final backgroundImageConstraints = BoxConstraints.tightFor(
      width: size.width,
    );
    background.layout(backgroundImageConstraints, parentUsesSize: true);

    // Set the background's local offset, which is zero.
    (background.parentData as ParallaxParentData).offset = Offset.zero;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Get the size of the scrollable area.
    final viewportDimension = scrollable.position.viewportDimension;

    // Calculate the global position of this list item.
    final scrollableBox = scrollable.context.findRenderObject() as RenderBox;
    final backgroundOffset = localToGlobal(
      size.centerLeft(Offset.zero),
      ancestor: scrollableBox,
    );

    // Determine the percent position of this list item within the
    // scrollable area.
    final scrollFraction = (backgroundOffset.dy / viewportDimension).clamp(
      0.0,
      1.0,
    );

    // Calculate the vertical alignment of the background
    // based on the scroll percent.
    final verticalAlignment = Alignment(0.0, scrollFraction * 2 - 1);

    // Convert the background alignment into a pixel offset for
    // painting purposes.
    final background = child!;
    final backgroundSize = background.size;
    final listItemSize = size;
    final childRect = verticalAlignment.inscribe(
      backgroundSize,
      Offset.zero & listItemSize,
    );

    // Paint the background.
    context.paintChild(
      background,
      (background.parentData as ParallaxParentData).offset +
          offset +
          Offset(0.0, childRect.top),
    );
  }
}

class Location {
  const Location({
    required this.name,
    required this.place,
    required this.imageUrl,
  });

  final String name;
  final String place;
  final String imageUrl;
}

const urlPrefix =
    'https://docs.flutter.dev/cookbook/img-files/effects/parallax';
const locations = [
  Location(
    name: 'Mount Rushmore',
    place: 'U.S.A',
    imageUrl: '$urlPrefix/01-mount-rushmore.jpg',
  ),
  Location(
    name: 'Gardens By The Bay',
    place: 'Singapore',
    imageUrl: '$urlPrefix/02-singapore.jpg',
  ),
  Location(
    name: 'Machu Picchu',
    place: 'Peru',
    imageUrl: '$urlPrefix/03-machu-picchu.jpg',
  ),
  Location(
    name: 'Vitznau',
    place: 'Switzerland',
    imageUrl: '$urlPrefix/04-vitznau.jpg',
  ),
  Location(
    name: 'Bali',
    place: 'Indonesia',
    imageUrl: '$urlPrefix/05-bali.jpg',
  ),
  Location(
    name: 'Mexico City',
    place: 'Mexico',
    imageUrl: '$urlPrefix/06-mexico-city.jpg',
  ),
  Location(name: 'Cairo', place: 'Egypt', imageUrl: '$urlPrefix/07-cairo.jpg'),
];