import 'package:flutter/material.dart';

import '../theme/app_text.dart';

/// Big 28 px title at the top of a tab page, like "Settings".
class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key, this.trailing});

  final String title;

  /// Optional buttons on the right, like search on Transactions.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: AppText.title28),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
