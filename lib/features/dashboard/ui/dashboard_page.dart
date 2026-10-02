import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_title.dart';
import '../../../router.dart';
import '../../../shell/placeholder_body.dart';

/// Home tab. Placeholder until Task 5.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            PageTitle(
              'Home',
              trailing: CircleIconButton.raised(
                icon: AppIcons.search,
                semanticLabel: 'Search transactions',
                onTap: () => context.go(Routes.transactions),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: PlaceholderCard(
                message: 'The Dashboard is built in Task 5.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
