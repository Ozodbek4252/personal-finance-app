import 'package:flutter/material.dart';

import '../../../core/widgets/page_title.dart';
import '../../../shell/placeholder_body.dart';

/// Transactions tab. Placeholder until Task 7.
class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: const [
            PageTitle('Transactions'),
            Padding(
              padding: EdgeInsets.all(16),
              child: PlaceholderCard(
                message: 'Transaction history is built in Task 7.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
