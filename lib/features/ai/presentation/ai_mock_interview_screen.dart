import 'package:flutter/material.dart';
import '../screens/mock_interview_screen.dart';

/// Legacy alias / wrapper pointing to the primary MockInterviewScreen.
class AIMockInterviewScreen extends StatelessWidget {
  const AIMockInterviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MockInterviewScreen();
  }
}
