import 'package:flutter/material.dart';
import '../screens/job_match_screen.dart';

/// Legacy export/wrapper for [JobMatchScreen].
class JobDescriptionInputScreen extends StatelessWidget {
  final VoidCallback? onSuccess;

  const JobDescriptionInputScreen({
    super.key,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return JobMatchScreen(onSuccess: onSuccess);
  }
}
