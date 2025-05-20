import 'package:flutter/material.dart';
import 'dart:async';
import 'screen/login.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoFadeAnimation;

  final String fullText = "ShareNotes";
  String typedText = "";
  int _index = 0;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _logoFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    _logoController.forward();

    Future.delayed(Duration(milliseconds: 1000), () {
      _startTypingText();
    });

    Timer(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

  void _startTypingText() {
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_index < fullText.length) {
        setState(() {
          typedText += fullText[_index];
          _index++;
        });
      } else {
        timer.cancel();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int splitIndex = "Share".length;
    final String first =
        typedText.length >= splitIndex
            ? typedText.substring(0, splitIndex)
            : typedText;
    final String second =
        typedText.length > splitIndex ? typedText.substring(splitIndex) : '';

    return Scaffold(
      backgroundColor: Color(0xFFF0FEFF),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Color(0xFF24527A),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Color(0xFF24527A),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SlideTransition(
                  position: _logoSlideAnimation,
                  child: FadeTransition(
                    opacity: _logoFadeAnimation,
                    child: Image.asset('assets/img/logo.png', width: 120),
                  ),
                ),
                SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: first,
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF24527A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: second,
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFFDDA853),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
