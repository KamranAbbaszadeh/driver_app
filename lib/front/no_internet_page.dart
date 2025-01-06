import 'package:flutter/material.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Whoops! \n No Internet connection found. \n Check your connection or try again.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
