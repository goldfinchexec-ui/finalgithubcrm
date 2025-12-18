import 'package:flutter/material.dart';
import 'package:goldfinch_crm/ui/components/page_header.dart';

/// Minimal Home page to satisfy initial route and compile
/// Uses the shared AppShellScaffold so the sidebar/layout is consistent.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        PageHeader(
          title: 'Welcome',
          subtitle: 'Pick a section from the sidebar to get started.',
        ),
      ],
    );
  }
}
