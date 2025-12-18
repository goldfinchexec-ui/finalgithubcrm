import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/theme.dart';

class AppShellScaffold extends ConsumerWidget {
  final Widget child;
  const AppShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(shellUiProvider).sidebarCollapsed;
    return Scaffold(
      body: Row(
        // Ensure the sidebar and the content column take the full viewport height
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        SidebarNav(collapsed: collapsed),
        Expanded(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(scrollbars: false, overscroll: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: double.infinity,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class SidebarNav extends ConsumerWidget {
  final bool collapsed;
  const SidebarNav({super.key, required this.collapsed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = collapsed ? 70.0 : 250.0;
    final loc = GoRouterState.of(context).uri.toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: const BoxDecoration(color: AppColors.sidebar),
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Header: logo + title (expanded) with an overlaid collapse/expand toggle.
          // Using Stack ensures the toggle doesn't participate in Row width
          // calculations, preventing overflow in collapsed (narrow) mode.
          Padding(
            padding: EdgeInsets.fromLTRB(collapsed ? 10 : 16, 16, collapsed ? 10 : 16, 12),
            child: SizedBox(
              height: 36,
              child: Stack(children: [
                // Logo + optional title
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        width: collapsed ? 30 : 34,
                        height: collapsed ? 30 : 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: const Icon(Icons.savings_outlined, color: Colors.white, size: 18),
                      ),
                      if (!collapsed) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Goldfinch',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Toggle button (doesn't consume horizontal space)
                Align(
                  alignment: Alignment.centerRight,
                  child: Tooltip(
                    message: collapsed ? 'Expand' : 'Collapse',
                    child: SizedBox(
                      width: collapsed ? 28 : 32,
                      height: collapsed ? 28 : 32,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => ref.read(shellUiProvider.notifier).toggleSidebar(),
                        icon: Icon(
                          collapsed ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SidebarItem(label: 'Dashboard', icon: Icons.dashboard_outlined, to: '/dashboard', collapsed: collapsed, selected: loc.startsWith('/dashboard')),
                  const SizedBox(height: 12),
                  SidebarGroup(label: 'Bookings', collapsed: collapsed),
                  SidebarItem(label: 'Bookings', icon: Icons.event_note_outlined, to: '/bookings', collapsed: collapsed, selected: loc.startsWith('/bookings')),
                  const SizedBox(height: 12),
                  SidebarGroup(label: 'Drivers', collapsed: collapsed),
                  SidebarItem(label: 'All Drivers', icon: Icons.badge_outlined, to: '/drivers', collapsed: collapsed, selected: loc.startsWith('/drivers')),
                  SidebarItem(label: 'Driver Invoices', icon: Icons.request_quote_outlined, to: '/driver-invoices', collapsed: collapsed, selected: loc.startsWith('/driver-invoices')),
                  const SizedBox(height: 12),
                  SidebarGroup(label: 'Clients', collapsed: collapsed),
                  SidebarItem(label: 'All Clients', icon: Icons.apartment_outlined, to: '/clients', collapsed: collapsed, selected: loc.startsWith('/clients')),
                  SidebarItem(label: 'Client Invoices', icon: Icons.receipt_long_outlined, to: '/client-invoices', collapsed: collapsed, selected: loc.startsWith('/client-invoices')),
                  const SizedBox(height: 12),
                  SidebarGroup(label: 'Finance', collapsed: collapsed),
                  SidebarItem(label: 'General Income', icon: Icons.trending_up_outlined, to: '/general-income', collapsed: collapsed, selected: loc.startsWith('/general-income')),
                  SidebarItem(label: 'General Expenses', icon: Icons.trending_down_outlined, to: '/general-expenses', collapsed: collapsed, selected: loc.startsWith('/general-expenses')),
                  SidebarItem(label: 'Receipt Vault', icon: Icons.folder_open_outlined, to: '/receipt-vault', collapsed: collapsed, selected: loc.startsWith('/receipt-vault')),
                ],
              ),
            ),
          ),
          // Bottom user capsule (replaces demo/local preview)
          Padding(
            padding: const EdgeInsets.all(12),
            child: _SidebarUserSection(collapsed: collapsed),
          ),
        ]),
      ),
    );
  }
}

class SidebarGroup extends StatelessWidget {
  final String label;
  final bool collapsed;
  const SidebarGroup({super.key, required this.label, required this.collapsed});

  @override
  Widget build(BuildContext context) {
    if (collapsed) return const SizedBox(height: 10);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.55), fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    );
  }
}

class SidebarItem extends ConsumerWidget {
  final String label;
  final IconData icon;
  final String to;
  final bool collapsed;
  final bool selected;

  const SidebarItem({super.key, required this.label, required this.icon, required this.to, required this.collapsed, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = selected ? Colors.white.withValues(alpha: 0.10) : Colors.transparent;
    final fg = selected ? Colors.white : Colors.white.withValues(alpha: 0.78);

    final item = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent, width: 1)),
      child: Row(children: [
        Icon(icon, color: fg, size: 20),
        if (!collapsed) ...[
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ],
      ]),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: collapsed ? label : '',
        child: InkWell(
          onTap: () {
            // Navigate
            context.go(to);
            // Auto-collapse the sidebar on narrow viewports so the menu "closes"
            // This helps on smaller screens and resolves perceived overflow
            final width = MediaQuery.of(context).size.width;
            if (width < 1000 && !collapsed) {
              ref.read(shellUiProvider.notifier).toggleSidebar();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: item,
        ),
      ),
    );
  }
}

class _SidebarUserSection extends ConsumerWidget {
  final bool collapsed;
  const _SidebarUserSection({required this.collapsed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state so this updates reactively when the user signs in/out
    final auth = ref.watch(authStateProvider);
    final user = auth.asData?.value;

    // Fallbacks
    final name = (() {
      final dn = user?.displayName?.trim();
      if (dn != null && dn.isNotEmpty) return dn;
      final email = user?.email ?? '';
      if (email.contains('@')) return email.split('@').first;
      return 'Staff';
    })();
    final photoUrl = user?.photoURL;

    final container = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
      ),
      child: Builder(builder: (context) {
        if (collapsed) {
          // Compact: just the avatar with a tooltip for the name
          return Tooltip(
            message: name,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Icon(Icons.person, color: Colors.white.withValues(alpha: 0.9), size: 16)
                  : null,
            ),
          );
        }
        // Expanded: avatar + name capsule
        return Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Icon(Icons.person, color: Colors.white.withValues(alpha: 0.9), size: 16)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }),
    );

    // Provide a simple account menu with Log out
    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, -6),
      position: PopupMenuPosition.under,
      onSelected: (value) async {
        if (value == 'logout') {
          await ref.read(authServiceProvider).signOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 10),
              Text('Log out', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
      child: container,
    );
  }
}
