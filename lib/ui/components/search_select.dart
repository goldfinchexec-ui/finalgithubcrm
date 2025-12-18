import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:goldfinch_crm/theme.dart';

/// A reusable search-and-select widget with inline suggestions and basic fuzzy matching.
///
/// It renders a text field and, as the user types, shows a suggestion list ranked by a
/// lightweight score across multiple tokens (e.g., name, code, email). Selecting a row
/// calls [onSelected] and updates the text field with the selected item's title.
class SearchSelect<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final String Function(T) idOf;
  final String Function(T) titleOf;
  final String? Function(T)? subtitleOf;
  final List<String> Function(T) tokensOf;
  final ValueChanged<T> onSelected;
  final String? selectedId;
  final TextEditingController? controller;
  final int maxResults;
  final bool compact;

  const SearchSelect({
    super.key,
    required this.label,
    required this.items,
    required this.idOf,
    required this.titleOf,
    required this.tokensOf,
    required this.onSelected,
    this.subtitleOf,
    this.selectedId,
    this.controller,
    this.maxResults = 8,
    this.compact = false,
  });

  @override
  State<SearchSelect<T>> createState() => _SearchSelectState<T>();
}

class _SearchSelectState<T> extends State<SearchSelect<T>> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  String _query = '';
  List<T> _results = [];
  bool _didInitSelectedText = false;
  double _fieldWidth = 0;
  double _fieldHeight = 0;
  // Track whether a tap is occurring inside the overlay so we don't
  // prematurely close it on TextField focus loss before the tap fires.
  bool _pointerDownInOverlay = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onChanged);
    _focusNode.addListener(_handleFocusChange);
    _computeResults();
    // Measure after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureField());
  }

  @override
  void didUpdateWidget(covariant SearchSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If selection exists and we haven't populated the field yet, show its title in the field.
    if (!_didInitSelectedText && widget.selectedId != null) {
      final matches = widget.items.where((e) => widget.idOf(e) == widget.selectedId);
      if (matches.isNotEmpty) {
        final sel = matches.first;
        _controller.text = widget.titleOf(sel);
        _didInitSelectedText = true;
      }
    }
    _computeResults();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onChanged);
    }
    _hideOverlay();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() {
        _query = _controller.text.trim();
        _computeResults();
      });
      debugPrint('SearchSelect: onChanged -> query="$_query" results=${_results.length}');
      _updateOverlay();
    });
  }

  void _computeResults() {
    final q = _query.toLowerCase();
    if (q.isEmpty) {
      _results = widget.items.take(widget.maxResults).toList();
      return;
    }

    int scoreItem(T item) {
      final tokens = widget.tokensOf(item)
          .where((t) => t.trim().isNotEmpty)
          .map((t) => t.toLowerCase())
          .toList();
      if (tokens.isEmpty) return 0;

      final parts = q.split(RegExp(r"\s+")).where((s) => s.isNotEmpty).toList();
      int score = 0;
      for (int i = 0; i < tokens.length; i++) {
        final hay = tokens[i];
        final weight = (tokens.length - i); // earlier tokens weigh more
        for (final p in parts) {
          if (hay == p) {
            score += 6 * weight;
          } else if (hay.startsWith(p)) {
            score += 4 * weight;
          } else if (hay.contains(p)) {
            score += 2 * weight;
          }
        }
      }
      return score;
    }

    final scored = <(T, int)>[];
    for (final item in widget.items) {
      final s = scoreItem(item);
      if (s > 0) scored.add((item, s));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    _results = scored.map((e) => e.$1).take(widget.maxResults).toList();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      debugPrint('SearchSelect: focus gained');
      _showOverlay();
    } else {
      // Do NOT immediately hide on focus loss. We keep the overlay open and
      // let either (a) a suggestion tap close it, or (b) an outside tap on the
      // background dismissor close it. This avoids the race where the field
      // loses focus before the overlay gets the tap.
      debugPrint('SearchSelect: focus lost, keeping overlay open');
    }
  }

  void _measureField() {
    final ctx = _fieldKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final needsUpdate = size.width != _fieldWidth || size.height != _fieldHeight;
    if (needsUpdate) {
      setState(() {
        _fieldWidth = size.width;
        _fieldHeight = size.height;
      });
      _updateOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _updateOverlay();
      return;
    }
    _overlayEntry = _buildOverlayEntry();
    if (_overlayEntry != null) {
      // Insert into the ROOT overlay so it sits above the dialog's modal barrier
      // and can receive taps. Using the nearest overlay can put it under the
      // DialogRoute's barrier which blocks taps on the suggestions.
      final overlay = Overlay.of(context, rootOverlay: true);
      overlay?.insert(_overlayEntry!);
      debugPrint('SearchSelect: overlay inserted');
    }
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    debugPrint('SearchSelect: overlay removed');
  }

  void _updateOverlay() {
    if (_overlayEntry == null) return;
    _overlayEntry!.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showLabel = !widget.compact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Text(
            widget.label,
            style: theme.textTheme.labelMedium?.copyWith(color: AppColors.slate500, fontWeight: FontWeight.w600),
          ),
        if (showLabel) const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: _buildTextField(theme),
        ),
      ],
    );
  }

  Widget _buildTextField(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Update cached width; height will be measured after frame
        if (constraints.maxWidth != _fieldWidth) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _measureField());
        }
        return Container(
          key: _fieldKey,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Search…',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.shad)),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _controller.clear();
                          _query = '';
                          _computeResults();
                        });
                        _updateOverlay();
                      },
                    )
                  : const Icon(Icons.search, size: 18),
            ),
            onTap: () {
              _showOverlay();
            },
            onSubmitted: (_) {
              if (_results.isNotEmpty) _select(_results.first);
            },
          ),
        );
      },
    );
  }

  OverlayEntry? _buildOverlayEntry() {
    final theme = Theme.of(context);
    return OverlayEntry(
      builder: (context) {
        // Keep the overlay visible until explicitly dismissed (outside tap or selection).
        // This avoids the long-standing race where the TextField loses focus
        // before the tap on a suggestion can be processed.
        final hasResults = _results.isNotEmpty;
        final showEmptyState = _query.isNotEmpty && _results.isEmpty;
        // Wrap the entire stack in a Listener so pointer tracking happens BEFORE gesture detection
        return Listener(
          onPointerDown: (event) {
            // Check if pointer is inside the suggestion panel (below the field)
            final fieldBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
            if (fieldBox != null) {
              final fieldOffset = fieldBox.localToGlobal(Offset.zero);
              final panelTop = fieldOffset.dy + _fieldHeight + 6;
              final panelLeft = fieldOffset.dx;
              final panelRight = panelLeft + _fieldWidth;
              final panelBottom = panelTop + 320; // max height of panel
              final tapY = event.position.dy;
              final tapX = event.position.dx;
              if (tapY >= panelTop && tapY <= panelBottom && tapX >= panelLeft && tapX <= panelRight) {
                _pointerDownInOverlay = true;
                debugPrint('SearchSelect: pointer down INSIDE overlay panel');
              } else {
                _pointerDownInOverlay = false;
                debugPrint('SearchSelect: pointer down OUTSIDE overlay panel');
              }
            }
          },
          onPointerUp: (_) {
            // Reset the flag after any onTap runs
            Future.microtask(() {
              _pointerDownInOverlay = false;
            });
          },
          behavior: HitTestBehavior.translucent,
          child: Positioned.fill(
            child: Stack(
              children: [
                // Background dismissor
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapDown: (_) {
                      if (_pointerDownInOverlay) {
                        debugPrint('SearchSelect: outside tap IGNORED (tap originated in overlay)');
                        return;
                      }
                      debugPrint('SearchSelect: outside tap -> hide overlay');
                      _hideOverlay();
                      _focusNode.unfocus();
                    },
                  ),
                ),
                // Suggestion panel on top
                CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0, (_fieldHeight > 0 ? _fieldHeight : 48) + 6),
                  child: Material(
                    color: Colors.transparent,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: _fieldWidth > 0 ? _fieldWidth : 500,
                        minWidth: _fieldWidth > 0 ? _fieldWidth : 280,
                        maxHeight: 320,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border.all(color: AppColors.border, width: 1),
                          borderRadius: BorderRadius.circular(AppRadius.shad),
                        ),
                        child: hasResults
                            ? ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                shrinkWrap: true,
                                itemCount: _results.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.6)),
                                itemBuilder: (context, index) {
                                  final item = _results[index];
                                  final title = widget.titleOf(item);
                                  final subtitle = widget.subtitleOf?.call(item);
                                  final isSelected = widget.selectedId != null && widget.idOf(item) == widget.selectedId;
                                  return InkWell(
                                    onTap: () {
                                      debugPrint('SearchSelect: tap suggestion -> "$title"');
                                      _select(item);
                                      _hideOverlay();
                                      _focusNode.unfocus();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Row(
                                        children: [
                                          Icon(isSelected ? Icons.check_circle : Icons.person_outline, size: 18, color: isSelected ? AppColors.primary : AppColors.slate500),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _highlightText(title, _query, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                                if (subtitle != null && subtitle.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2),
                                                    child: _highlightText(subtitle, _query, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate600)),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                child: Text(
                                  showEmptyState ? 'No matches' : 'Start typing to search',
                                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate500),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _select(T item) {
    final title = widget.titleOf(item);
    // Call parent's callback first to avoid controller-listener races in parents
    try {
      widget.onSelected(item);
      debugPrint('SearchSelect: selected -> $title');
    } catch (e) {
      debugPrint('SearchSelect onSelected error: $e');
    }
    // Update field text and move caret to end
    _controller.value = TextEditingValue(
      text: title,
      selection: TextSelection.collapsed(offset: title.length),
    );
    // Reset search query so reopening doesn’t show filtered old results
    setState(() {
      _query = title;
      _computeResults();
    });
    // keep focus only if user will continue typing; focus is removed by caller on tap
  }

  Widget _highlightText(String text, String query, {TextStyle? style}) {
    if (query.isEmpty) return Text(text, style: style);
    final lower = text.toLowerCase();
    final q = query.toLowerCase();

    // Highlight first occurrence of any query token
    final parts = q.split(RegExp(r"\s+")).where((s) => s.isNotEmpty).toList();
    int start = -1;
    int len = 0;
    for (final p in parts) {
      final idx = lower.indexOf(p);
      if (idx >= 0 && (start == -1 || idx < start)) {
        start = idx;
        len = p.length;
      }
    }
    if (start == -1) return Text(text, style: style);
    final pre = text.substring(0, start);
    final mid = text.substring(start, start + len);
    final post = text.substring(start + len);
    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: pre),
          TextSpan(text: mid, style: style?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          TextSpan(text: post),
        ],
      ),
    );
  }
}
