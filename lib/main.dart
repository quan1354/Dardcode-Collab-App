import 'package:darkord/views/chat_list.dart';
import 'package:flutter/material.dart';
import 'package:darkord/views/login.dart';
import 'package:darkord/consts/color.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context)  {
    return MaterialApp(
      title: 'Darkord',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: mainBGColor
        ),
        scaffoldBackgroundColor: mainBGColor, 
      ),
      home: LoginForm(),
    );
  }
}