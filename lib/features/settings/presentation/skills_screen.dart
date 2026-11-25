import 'package:flutter/material.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final skills = [
      'Task Planning',
      'Calendar Management',
      'Homework Tracking',
      'Summaries',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Skills')),
      body: ListView.builder(
        itemCount: skills.length,
        itemBuilder: (context, i) {
          final skill = skills[i];
          return SwitchListTile(
            title: Text(skill),
            value: true,
            onChanged: (_) {},
          );
        },
      ),
    );
  }
}
