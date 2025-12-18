import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goldfinch_crm/theme.dart';

class BookingDetailsModal extends StatefulWidget {
  final Map<String, dynamic> data;
  const BookingDetailsModal({super.key, required this.data});

  static Future<void> show(BuildContext context, {required Map<String, dynamic> data}) {
    return showDialog(
      context: context,
      useRootNavigator: true,
      builder: (_) => BookingDetailsModal(data: data),
    );
  }

  @override
  State<BookingDetailsModal> createState() => _BookingDetailsModalState();
}

class _BookingDetailsModalState extends State<BookingDetailsModal> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.data;

    final pax = (data['passenger'] is Map) ? Map<String, dynamic>.from(data['passenger']) : <String, dynamic>{};
    final journey = (data['journey'] is Map) ? Map<String, dynamic>.from(data['journey']) : <String, dynamic>{};
    final vehicle = (data['vehicle'] is Map) ? Map<String, dynamic>.from(data['vehicle']) : <String, dynamic>{};
    final payment = (data['payment'] is Map) ? Map<String, dynamic>.from(data['payment']) : <String, dynamic>{};

    // Collect "other" fields not in these sections to show under Misc.
    final known = {'id', 'passenger', 'journey', 'vehicle', 'payment'};
    final others = <String, dynamic>{};
    for (final e in data.entries) {
      if (!known.contains(e.key)) others[e.key] = e.value;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.shad)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 720),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: Text('Booking Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.slate900)),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.slate700),
              ),
            ]),
            const SizedBox(height: 6),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            Expanded(
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _Section(title: 'Passenger Details', children: [
                      _FieldRow(label: 'Full Name', value: pax['fullName']),
                      _FieldRow(label: 'Phone', value: pax['phone']),
                      _FieldRow(label: 'Email', value: pax['email']),
                      _FieldRow(label: 'Luggage', value: pax['luggage'] ?? pax['bags']),
                      _FieldRow(label: 'Notes', value: pax['notes']),
                    ]),
                    const SizedBox(height: 16),
                    _Section(title: 'Journey Info', children: [
                      _FieldRow(label: 'Date', value: journey['date']),
                      _FieldRow(label: 'Time', value: journey['time']),
                      _FieldRow(label: 'Pickup Address', value: journey['pickupLocation']),
                      _FieldRow(label: 'Drop-off Address', value: journey['dropoffLocation']),
                      _FieldRow(label: 'Flight Number', value: journey['flightNumber']),
                      _FieldRow(label: 'Via / Waypoints', value: journey['via']),
                      _FieldRow(label: 'Distance', value: journey['distance']),
                      _FieldRow(label: 'Duration', value: journey['duration']),
                      _FieldRow(label: 'Journey Notes', value: journey['notes']),
                    ]),
                    const SizedBox(height: 16),
                    _Section(title: 'Vehicle & Payment', children: [
                      _FieldRow(label: 'Vehicle', value: vehicle['type'] ?? vehicle['name']),
                      _FieldRow(label: 'Driver', value: vehicle['driver']),
                      _FieldRow(label: 'Platform', value: data['platform']),
                      _FieldRow(label: 'Status', value: data['status']),
                      _FieldRow(label: 'Reference', value: data['reference']),
                      _FieldRow(label: 'Price', value: payment['price'] ?? data['price']),
                      _FieldRow(label: 'Currency', value: payment['currency']),
                      _FieldRow(label: 'Payment Method', value: payment['method']),
                      _FieldRow(label: 'Invoice Number', value: payment['invoiceNumber']),
                      _FieldRow(label: 'Payment Notes', value: payment['notes']),
                    ]),
                    if (others.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _Section(
                        title: 'Other Fields',
                        children: others.entries.map((e) => _FieldRow(label: e.key, value: e.value)).toList(),
                      ),
                    ],
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.shad),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.slate900)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}

class _FieldRow extends StatefulWidget {
  final String label;
  final dynamic value;
  const _FieldRow({required this.label, required this.value});

  @override
  State<_FieldRow> createState() => _FieldRowState();
}

class _FieldRowState extends State<_FieldRow> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final v = _stringify(widget.value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 180,
          child: Text(widget.label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.slate500, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(v, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.slate700), overflow: TextOverflow.visible),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: v));
            setState(() => _copied = true);
            await Future.delayed(const Duration(milliseconds: 900));
            if (mounted) setState(() => _copied = false);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 16, color: AppColors.slate700),
          ),
        ),
      ]),
    );
  }

  String _stringify(dynamic v) {
    if (v == null) return '—';
    if (v is String) return v;
    if (v is num || v is bool) return v.toString();
    if (v is DateTime) return v.toIso8601String();
    try {
      return v.toString();
    } catch (_) {
      return '$v';
    }
  }
}
