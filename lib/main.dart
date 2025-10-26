import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this import
import 'package:darkord/views/chat_list.dart';
import 'package:darkord/views/profile.dart';
import 'package:darkord/views/login.dart';
import 'package:darkord/consts/color.dart';
import 'package:darkord/api/auth_provider.dart'; // You'll need to create this

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Darkord',
      theme: ThemeData(
        appBarTheme: AppBarTheme(backgroundColor: mainBGColor),
        scaffoldBackgroundColor: mainBGColor,
      ),
      home: LoginForm(),
    );
  }
}
