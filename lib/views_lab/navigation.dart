import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// Navigator Class:
// pushAndRemoveUntil: Adds a navigation route to the stack and then removes the most recent routes from the stack until a condition is met.
// pushReplacement: Replaces the current route on the top of the stack with a new one.
// replace: Replace a route on the stack with another route.
// replaceRouteBelow: Replace the route below a specific route on the stack.
// popUntil: Removes the most recent routes that were added to the stack of navigation routes until a condition is met.
// removeRoute: Remove a specific route from the stack.
// removeRouteBelow: Remove the route below a specific route on the stack.
// restorablePush: Restore a route that was removed from the stack.
// pushNamed:Named routes are no longer recommended for most applications. (https://docs.flutter.dev/ui/navigation#limitations)

void main() {
  //runApp(const MaterialApp(title: 'Navigation Basics', home: FirstRoute()));
  // runApp(const CupertinoApp(title: 'Navigation Basics', home: FirstRoute()));
  runApp(
    MaterialApp(
      title: 'Named Routes Demo',
      // Start the app with the "/" named route. In this case, the app starts
      // on the FirstScreen widget.
      initialRoute: '/',
      routes: {
        // When navigating to the "/" route, build the FirstScreen widget.
        '/': (context) => const FirstRoute(),
        // When navigating to the "/second" route, build the SecondScreen widget.
        '/second': (context) => const SecondRoute(),
      },
    ),
  );
}

class FirstRoute extends StatelessWidget {
  const FirstRoute({super.key});

  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   appBar: AppBar(title: const Text('First Route')),
    //   body: Center(
    //     child: ElevatedButton(
    //       child: const Text('Open route'),
    //       onPressed: () {
    //         Navigator.push(
    //           context,
    //           MaterialPageRoute(builder: (context) => const SecondRoute()),
    //         );
    //       },
    //     ),
    //   ),
    // );
    // return CupertinoPageScaffold(
    //   navigationBar: const CupertinoNavigationBar(middle: Text('First Route')),
    //   child: Center(
    //     child: CupertinoButton(
    //       child: const Text('Open route'),
    //       onPressed: () {
    //         Navigator.push(
    //           context,
    //           CupertinoPageRoute(builder: (context) => const SecondRoute()),
    //         );
    //       },
    //     ),
    //   ),
    // );
    return Scaffold(
      appBar: AppBar(title: const Text('First Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to the second screen when tapped.
            Navigator.pushNamed(context, '/second');
          },
          child: const Text('Launch screen'),
        ),
      ),
    );
  }
}

class SecondRoute extends StatelessWidget {
  const SecondRoute({super.key});

  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   appBar: AppBar(title: const Text('Second Route')),
    //   body: Center(
    //     child: ElevatedButton(
    //       onPressed: () {
    //         Navigator.pop(context);
    //       },
    //       child: const Text('Go back!'),
    //     ),
    //   ),
    // );

    // return CupertinoPageScaffold(
    //   navigationBar: const CupertinoNavigationBar(middle: Text('Second Route')),
    //   child: Center(
    //     child: CupertinoButton(
    //       onPressed: () {
    //         Navigator.pop(context);
    //       },
    //       child: const Text('Go back!'),
    //     ),
    //   ),
    // );

    return Scaffold(
      appBar: AppBar(title: const Text('Second Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate back to first screen when tapped.
            Navigator.pop(context);
          },
          child: const Text('Go back!'),
        ),
      ),
    );
  }
}
