import 'package:flutter/material.dart';

import 'package:goldfinch_crm/theme.dart';

/// Describes a single column in [NotionTable].
/// Provide a [cellBuilder] to render each cell and an optional [sortBy]
/// to enable sorting by this column.
class NotionColumn<T> {
  final String label;
  final Widget Function(BuildContext context, T row) cellBuilder;
  final Comparable<dynamic> Function(T row)? sortBy;
  final bool sortable;
  final int flex;
  final double? width; // If provided, a fixed column width. Enables resizing.
  final bool resizable;
  final TextAlign headerAlign;
  final IconData? headerIcon; // Optional small icon (e.g., Aa)
  final Color? headerIconColor;

  const NotionColumn({
    required this.label,
    required this.cellBuilder,
    this.sortBy,
    this.sortable = true,
    this.flex = 1,
    this.width,
    this.resizable = true,
    this.headerAlign = TextAlign.left,
    this.headerIcon,
    this.headerIconColor,
  });
}

/// A minimal Notion-like data table with:
/// - Clean header with sort toggles
/// - Optional selection checkbox column
/// - Mixed fixed-width and flexible columns
/// - Optional column resize for fixed-width columns
/// - Shadcn-inspired styling consistent with the app
class NotionTable<T> extends StatefulWidget {
  final List<T> rows;
  final List<NotionColumn<T>> columns;
  final bool showSelection;
  final Set<int>? selectedIndices;
  final void Function(Set<int> indices)? onSelectionChanged;
  final int? initialSortColumnIndex;
  final bool initialSortAscending;
  final String? emptyTitle;
  final String? emptyMessage;
  /// Optional callback to provide a soft background color per row (for visual accents)
  /// Return a Color to tint the row, or null for default transparent background.
  final Color? Function(T row)? rowBackgroundColor;

  const NotionTable({
    super.key,
    required this.rows,
    required this.columns,
    this.showSelection = false,
    this.selectedIndices,
    this.onSelectionChanged,
    this.initialSortColumnIndex,
    this.initialSortAscending = true,
    this.emptyTitle,
    this.emptyMessage,
    this.rowBackgroundColor,
  });

  @override
  State<NotionTable<T>> createState() => _NotionTableState<T>();
}

class _NotionTableState<T> extends State<NotionTable<T>> {
  late List<T> _sorted;
  int? _sortIndex;
  bool _ascending = true;
  late List<double?> _widths; // if null => use flex
  late Set<int> _selected;
  final ScrollController _vertical = ScrollController();

  @override
  void initState() {
    super.initState();
    _sorted = List<T>.from(widget.rows);
    _sortIndex = widget.initialSortColumnIndex;
    _ascending = widget.initialSortAscending;
    _widths = widget.columns.map((c) => c.width).toList();
    _selected = widget.selectedIndices != null ? {...widget.selectedIndices!} : <int>{};
    _applySort();
  }

  @override
  void didUpdateWidget(covariant NotionTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep current sort but refresh data when rows change
    if (!identical(widget.rows, oldWidget.rows)) {
      _sorted = List<T>.from(widget.rows);
      _applySort();
    }
    if (widget.selectedIndices != null && widget.selectedIndices != oldWidget.selectedIndices) {
      _selected = {...widget.selectedIndices!};
    }
  }

  void _applySort() {
    final idx = _sortIndex;
    if (idx == null) return;
    final column = widget.columns[idx];
    final by = column.sortBy;
    if (by == null) return;
    _sorted.sort((a, b) {
      final ca = by(a);
      final cb = by(b);
      int result = 0;
      if (ca == null && cb == null) {
        result = 0;
      } else if (ca == null) {
        result = -1;
      } else if (cb == null) {
        result = 1;
      } else {
        result = Comparable.compare(ca, cb);
      }
      return _ascending ? result : -result;
    });
  }

  void _toggleSort(int idx) {
    setState(() {
      if (_sortIndex == idx) {
        _ascending = !_ascending;
      } else {
        _sortIndex = idx;
        _ascending = true;
      }
      _applySort();
    });
  }

  void _onDragResize(double dx, int idx) {
    setState(() {
      final current = _widths[idx] ?? 160.0;
      final next = (current + dx).clamp(80.0, 640.0);
      _widths[idx] = next;
    });
  }

  void _toggleSelectAll(bool? checked) {
    setState(() {
      if (checked == true) {
        _selected = Set<int>.from(Iterable<int>.generate(_sorted.length));
      } else {
        _selected.clear();
      }
    });
    widget.onSelectionChanged?.call(_selected);
  }

  void _toggleRowSelection(int index, bool? checked) {
    setState(() {
      if (checked == true) {
        _selected.add(index);
      } else {
        _selected.remove(index);
      }
    });
    widget.onSelectionChanged?.call(_selected);
  }

  @override
  Widget build(BuildContext context) {
    if (_sorted.isEmpty && (widget.emptyTitle != null || widget.emptyMessage != null)) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.shad),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (widget.emptyTitle != null)
            Text(widget.emptyTitle!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.slate900)),
          if (widget.emptyMessage != null) ...[
            const SizedBox(height: 6),
            Text(widget.emptyMessage!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.slate500, height: 1.45)),
          ],
        ]),
      );
    }

    // Single bordered grid: header + rows
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(AppRadius.shad),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Header<T>(
          columns: widget.columns,
          widths: _widths,
          showSelection: widget.showSelection,
          allSelected: _selected.length == _sorted.length && _sorted.isNotEmpty,
          sortIndex: _sortIndex,
          ascending: _ascending,
          onToggleSort: _toggleSort,
          onResize: _onDragResize,
          onToggleAll: _toggleSelectAll,
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.border),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: ListView.separated(
            controller: _vertical,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: AppColors.border),
            itemBuilder: (context, i) {
              final row = _sorted[i];
              return _DataRow<T>(
                index: i,
                row: row,
                columns: widget.columns,
                widths: _widths,
                selected: _selected.contains(i),
                showSelection: widget.showSelection,
                onChanged: (v) => _toggleRowSelection(i, v),
                backgroundColor: widget.rowBackgroundColor?.call(row),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _Header<T> extends StatelessWidget {
  final List<NotionColumn<T>> columns;
  final List<double?> widths;
  final bool showSelection;
  final bool allSelected;
  final int? sortIndex;
  final bool ascending;
  final void Function(int idx) onToggleSort;
  final void Function(double dx, int idx) onResize;
  final void Function(bool? v) onToggleAll;

  const _Header({
    required this.columns,
    required this.widths,
    required this.showSelection,
    required this.allSelected,
    required this.sortIndex,
    required this.ascending,
    required this.onToggleSort,
    required this.onResize,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.shad),
          topRight: Radius.circular(AppRadius.shad),
        ),
      ),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppColors.slate500, fontWeight: FontWeight.w700),
        child: Row(children: [
          ...List.generate(columns.length, (i) {
            final col = columns[i];
            final fixed = widths[i];
            final isSorted = sortIndex == i;
            final icon = isSorted
                ? (ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                : Icons.swap_vert_rounded;
            final canSort = col.sortable && col.sortBy != null;

            final label = Row(mainAxisSize: MainAxisSize.min, children: [
              if (col.headerIcon != null) ...[
                Icon(col.headerIcon, size: 14, color: col.headerIconColor ?? AppColors.slate500),
                const SizedBox(width: 6),
              ],
              Flexible(child: Text(col.label, textAlign: col.headerAlign, overflow: TextOverflow.ellipsis)),
              if (canSort) ...[
                const SizedBox(width: 6),
                Icon(icon, size: 14, color: AppColors.slate500),
              ],
            ]);

            Widget head = InkWell(
              onTap: canSort ? () => onToggleSort(i) : null,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Align(alignment: Alignment.centerLeft, child: label),
              ),
            );

            if (fixed != null) {
              head = SizedBox(width: fixed, child: head);
            } else {
              head = Expanded(flex: col.flex, child: head);
            }

            // Add a thin drag handle if column is fixed and resizable
            final showHandle = fixed != null && col.resizable;
            if (showHandle) {
              head = Stack(children: [
                head,
                Positioned(
                  right: -2,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (d) => onResize(d.delta.dx, i),
                    child: Container(width: 6, color: Colors.transparent),
                  ),
                ),
              ]);
            }

            // vertical divider for header except last column
            return [
              head,
              if (i != columns.length - 1) _VerticalDivider(),
            ];
          }).expand((e) => e),
        ]),
      ),
    );
  }
}

class _DataRow<T> extends StatelessWidget {
  final int index;
  final T row;
  final List<NotionColumn<T>> columns;
  final List<double?> widths;
  final bool selected;
  final bool showSelection;
  final void Function(bool? v) onChanged;
  final Color? backgroundColor;

  const _DataRow({
    required this.index,
    required this.row,
    required this.columns,
    required this.widths,
    required this.selected,
    required this.showSelection,
    required this.onChanged,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 48,
      decoration: BoxDecoration(
        color: bg,
      ),
      child: Row(children: [
        ...List.generate(columns.length, (cIdx) {
          final col = columns[cIdx];
          final fixed = widths[cIdx];
          // Center all data cells except the first column, which remains left-aligned
          final alignment = cIdx == 0 ? Alignment.centerLeft : Alignment.center;
          final cell = Align(alignment: alignment, child: col.cellBuilder(context, row));
          return [
            if (fixed != null)
              SizedBox(width: fixed, child: cell)
            else
              Expanded(flex: col.flex, child: cell),
            if (cIdx != columns.length - 1) _VerticalDivider(),
          ];
        }).expand((e) => e),
      ]),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 24, color: AppColors.border);
  }
}
