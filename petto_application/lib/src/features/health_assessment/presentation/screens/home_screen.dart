import 'package:flutter/material.dart';
import 'health_assessment_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Petto - Pet Health'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pets,
              size: 100,
              color: Color(0xFF6C63FF),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Petto',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI-Powered Pet Health Assessment',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HealthAssessmentScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.medical_services),
              label: const Text('Start Assessment'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
