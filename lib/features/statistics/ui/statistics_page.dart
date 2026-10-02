import 'package:flutter/material.dart';

import '../../../core/widgets/page_title.dart';
import '../../../shell/placeholder_body.dart';

/// Statistics tab. Placeholder until Task 11.
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: const [
            PageTitle('Statistics'),
            Padding(
              padding: EdgeInsets.all(16),
              child: PlaceholderCard(
                message: 'Statistics are built in Task 11.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
