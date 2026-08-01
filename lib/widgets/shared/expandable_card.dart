import 'package:flutter/material.dart';
import '../../core/theme/form_theme.dart';
import '../../core/theme/navigation_theme.dart';

class ExpandableCard extends StatefulWidget {
  final String title;
  final Widget? leading;
  final Widget? badge;
  final Widget? subtitle;
  final Widget expandedContent;
  final Color borderColor;
  final Widget? preview;
  final bool initiallyExpanded;
  final bool expandOnTap;
  final bool showExpandButton;
  final bool showHeaderExpandIndicator;
  final String expandButtonLabel;
  final String collapseButtonLabel;

  const ExpandableCard({
    super.key,
    required this.title,
    this.leading,
    this.badge,
    this.subtitle,
    required this.expandedContent,
    required this.borderColor,
    this.preview,
    this.initiallyExpanded = false,
    this.expandOnTap = true,
    this.showExpandButton = false,
    this.showHeaderExpandIndicator = true,
    this.expandButtonLabel = 'Expand',
    this.collapseButtonLabel = 'Collapse',
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: widget.initiallyExpanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Container(
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: widget.borderColor.withAlpha(153), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.expandOnTap ? _toggleExpanded : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Always visible header with title and badge
                Row(
                  children: [
                    if (widget.leading != null) ...[
                      widget.leading!,
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: FormTheme.textBright,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: _isExpanded ? null : 2,
                        overflow: _isExpanded ? null : TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.badge != null) ...[
                      const SizedBox(width: 8),
                      widget.badge!,
                    ],
                    if (widget.showHeaderExpandIndicator) ...[
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          color: widget.borderColor.withAlpha(178),
                          size: 20,
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  widget.subtitle!,
                ],
                if (widget.preview != null) ...[
                  const SizedBox(height: 8),
                  widget.preview!,
                ],
                if (widget.showExpandButton) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _toggleExpanded,
                      icon: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          size: 18,
                          color: widget.borderColor,
                        ),
                      ),
                      label: Text(
                        _isExpanded
                            ? widget.collapseButtonLabel
                            : widget.expandButtonLabel,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: widget.borderColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                // Expandable content
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      widget.expandedContent,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
