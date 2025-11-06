import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:darkord/views/login.dart';
import 'package:darkord/consts/app_constants.dart';
import 'package:darkord/api/auth_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: const AppBarTheme(backgroundColor: AppConstants.mainBGColor),
        scaffoldBackgroundColor: AppConstants.mainBGColor,
        useMaterial3: true,
      ),
      home: const LoginForm(),
    );
  }
}
