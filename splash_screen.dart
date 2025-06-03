import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_indicator/loading_indicator.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  void _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 4));

    String? token = await _apiService.getToken();
    String? role = await _apiService.getUserRole();

    if (!mounted) return;

    if (token == null) {
      context.go('/login');
    } else if (role == 'Admin') {
      context.go('/admin-dashboard');
    } else {
      context.go('/user-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0f2e1d), // Deep green
              Color(0xFFd9b37a), // Tree beige
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: FadeIn(
              duration: const Duration(seconds: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // Logo inside circle
                  CircleAvatar(
                    radius: screenWidth < 600 ? 60 : 80,
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/logo1.png',
                        width: screenWidth < 600 ? 100 : 140,
                        height: screenWidth < 600 ? 100 : 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Loading animation
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: LoadingIndicator(
                      indicatorType: Indicator.lineSpinFadeLoader,
                      colors: [
                        Color(0xFF6DA76A),
                        Color(0xFFD9B37A),
                        Color(0xFFD4A662),
                      ],
                      strokeWidth: 2,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Text caption
                  FadeIn(
                    duration: const Duration(seconds: 4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "UpGyaan: Where Rural Youth Meets Opportunity!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth < 600 ? 17 : 20,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Montserrat',
                        
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
