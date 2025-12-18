import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goldfinch_crm/theme.dart';
import 'package:goldfinch_crm/ui/components/notion_table.dart';
import 'package:goldfinch_crm/ui/components/page_header.dart';
import 'package:goldfinch_crm/ui/components/shad_button.dart';
import 'package:goldfinch_crm/ui/components/shad_text_field.dart';
import 'package:goldfinch_crm/utils/formatters.dart';

import 'package:goldfinch_crm/ui/components/booking_details_modal.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHeader(
        title: 'Bookings',
        subtitle: 'Real-time feed from Firestore · newest first',
        actions: [
          SizedBox(
            width: 280,
            child: ShadTextField(
              controller: _searchController,
              label: 'Search',
              hint: 'Passenger name or reference',
              prefixIcon: Icons.search_rounded,
              compact: true,
              hideLabel: true,
              showClearButton: true,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            // Limit to keep UI snappy; client-side sort by date/time
            .limit(500)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _loadingCard(context);
          }
          if (snap.hasError) {
            return _errorCard(context, snap.error);
          }

          final docs = snap.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          // Convert to plain maps with id
          List<Map<String, dynamic>> rows = docs
              .map((d) => {
                    'id': d.id,
                    ...?d.data(),
                  })
              .toList();

          // Client-side search (case-insensitive contains on passenger.fullName or reference)
          final q = _searchController.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            rows = rows.where((r) {
              final name = _readIn(r, ['passenger', 'fullName'])?.toString().toLowerCase() ?? '';
              final reference = r['reference']?.toString().toLowerCase() ?? '';
              return name.contains(q) || reference.contains(q);
            }).toList();
          }

          // Sort newest first by journey.date (Timestamp/DateTime/string) then fallback createdAt
          rows.sort((a, b) {
            final ad = _dateFrom(a);
            final bd = _dateFrom(b);
            return bd.compareTo(ad);
          });

          return NotionTable<Map<String, dynamic>>(
            rows: rows,
            columns: [
              NotionColumn<Map<String, dynamic>>(
                label: 'Pax Name',
                flex: 2,
                cellBuilder: (context, row) {
                  final name = _readIn(row, ['passenger', 'fullName'])?.toString() ?? '—';
                  final reference = row['reference']?.toString();
                  return Row(children: [
                    Expanded(child: Text(name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.slate900), overflow: TextOverflow.ellipsis)),
                    if (reference != null && reference.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _Capsule(text: reference),
                    ],
                  ]);
                },
                sortBy: (r) => _readIn(r, ['passenger', 'fullName'])?.toString().toLowerCase() ?? '',
              ),
              NotionColumn<Map<String, dynamic>>(
                label: 'Date & Time',
                flex: 2,
                cellBuilder: (context, row) {
                  final dt = _dateFrom(row);
                  final timeStr = _timeStringFrom(row);
                  return Text(
                    '${AppFormatters.date.format(dt)}${timeStr != null ? ' · $timeStr' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.slate600),
                    overflow: TextOverflow.ellipsis,
                  );
                },
                sortBy: (r) => _dateFrom(r),
              ),
              NotionColumn<Map<String, dynamic>>(
                label: 'Pickup Address',
                flex: 3,
                cellBuilder: (context, row) {
                  final v = _readIn(row, ['journey', 'pickupLocation'])?.toString() ?? '—';
                  return Text(v, overflow: TextOverflow.ellipsis);
                },
                sortBy: (r) => _readIn(r, ['journey', 'pickupLocation'])?.toString().toLowerCase() ?? '',
              ),
              NotionColumn<Map<String, dynamic>>(
                label: 'Drop-off Address',
                flex: 3,
                cellBuilder: (context, row) {
                  final v = _readIn(row, ['journey', 'dropoffLocation'])?.toString() ?? '—';
                  return Text(v, overflow: TextOverflow.ellipsis);
                },
                sortBy: (r) => _readIn(r, ['journey', 'dropoffLocation'])?.toString().toLowerCase() ?? '',
              ),
              NotionColumn<Map<String, dynamic>>(
                label: 'Status',
                flex: 1,
                cellBuilder: (context, row) {
                  final status = row['status']?.toString() ?? '—';
                  return _StatusPill(status: status);
                },
                sortBy: (r) => r['status']?.toString().toLowerCase() ?? '',
              ),
              NotionColumn<Map<String, dynamic>>(
                label: 'Platform',
                flex: 2,
                cellBuilder: (context, row) {
                  final v = row['platform']?.toString() ?? '—';
                  return Text(v, overflow: TextOverflow.ellipsis);
                },
                sortBy: (r) => r['platform']?.toString().toLowerCase() ?? '',
              ),
              NotionColumn<Map<String, dynamic>>(
                label: 'Action',
                width: 120,
                resizable: false,
                sortable: false,
                cellBuilder: (context, row) {
                  return Align(
                    alignment: Alignment.center,
                    child: ShadButton(
                      label: 'View',
                      icon: Icons.visibility_rounded,
                      compact: true,
                      onPressed: () async {
                        await BookingDetailsModal.show(context, data: row);
                      },
                    ),
                  );
                },
              ),
            ],
            initialSortColumnIndex: 1, // Date & Time
            initialSortAscending: false,
            emptyTitle: 'No bookings yet',
            emptyMessage: 'Newly created bookings will appear here in real time.',
          );
        },
      ),
    ]);
  }

  Widget _loadingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.shad),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(children: [
        const SizedBox(width: 4, height: 4, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 12),
        Text('Loading bookings...', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.slate500)),
      ]),
    );
  }

  Widget _errorCard(BuildContext context, Object? error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.shad),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Could not load bookings', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.slate900)),
            const SizedBox(height: 6),
            Text('$error', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.slate500)),
          ]),
        ),
      ]),
    );
  }

  static dynamic _readIn(Map<String, dynamic> map, List<String> path) {
    dynamic cur = map;
    for (final k in path) {
      if (cur is Map && cur.containsKey(k)) {
        cur = cur[k];
      } else {
        return null;
      }
    }
    return cur;
  }

  static DateTime _dateFrom(Map<String, dynamic> row) {
    final jDate = _readIn(row, ['journey', 'date']);
    if (jDate is Timestamp) return jDate.toDate();
    if (jDate is DateTime) return jDate;
    if (jDate is String) {
      // Attempt to parse ISO8601; fallback to epoch
      try {
        return DateTime.parse(jDate);
      } catch (_) {}
    }
    final createdAt = row['createdAt'];
    if (createdAt is Timestamp) return createdAt.toDate();
    if (createdAt is DateTime) return createdAt;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String? _timeStringFrom(Map<String, dynamic> row) {
    final t = _readIn(row, ['journey', 'time']);
    if (t == null) return null;
    if (t is Timestamp) {
      final d = t.toDate();
      return AppFormatters.time.format(d);
    }
    if (t is DateTime) {
      return AppFormatters.time.format(t);
    }
    return t.toString();
  }
}

class _Capsule extends StatelessWidget {
  final String text;
  const _Capsule({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.slate700, fontWeight: FontWeight.w700)),
    );
  }
}

class _StatusPill extends StatefulWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.status;
    final lower = s.toLowerCase();
    final isSuccess = lower.contains('paid');
    final isPending = lower.contains('await') || lower.contains('invoice') || lower.contains('pending');
    final bg = isSuccess
        ? AppColors.emeraldSoft
        : isPending
            ? AppColors.amberSoft
            : AppColors.slate100;
    final fg = AppColors.slate900;

    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: s));
        setState(() => _copied = true);
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) setState(() => _copied = false);
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border, width: 1)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(s, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 14, color: fg),
        ]),
      ),
    );
  }
}
