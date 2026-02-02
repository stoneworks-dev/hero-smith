import 'package:flutter/material.dart';

import '../../../core/text/heroes_sheet/gear/inventory_widgets_text.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/theme/form_theme.dart';

/// Card displaying an inventory container with its items.
class ContainerCard extends StatefulWidget {
  const ContainerCard({
    super.key,
    required this.container,
    required this.onAddItem,
    required this.onDeleteContainer,
    required this.onDeleteItem,
    required this.onEditItem,
    required this.onEditContainer,
    required this.onUpdateItemQuantity,
  });

  final Map<String, dynamic> container;
  final VoidCallback onAddItem;
  final VoidCallback onDeleteContainer;
  final Function(String) onDeleteItem;
  final Function(String, Map<String, dynamic>) onEditItem;
  final VoidCallback onEditContainer;
  final Function(String, int) onUpdateItemQuantity;

  @override
  State<ContainerCard> createState() => _ContainerCardState();
}

class _ContainerCardState extends State<ContainerCard> {
  bool _isExpanded = true;

  Future<void> _showQuantityDialog(
      BuildContext context, String itemId, int currentQuantity) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) =>
          _QuantityInputDialog(currentQuantity: currentQuantity),
    );

    if (result != null && result != currentQuantity) {
      widget.onUpdateItemQuantity(itemId, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items =
        widget.container['items'] as List<dynamic>? ?? <Map<String, dynamic>>[];
    final name = widget.container['name'] as String? ??
        InventoryWidgetsText.defaultContainerName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        children: [
          // Container header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: NavigationTheme.itemsColor.withAlpha(26),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(12),
                bottom: _isExpanded ? Radius.zero : const Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Fantasy chest/bag icon
                Icon(
                  _isExpanded ? Icons.card_travel : Icons.inventory_2,
                  color: NavigationTheme.itemsColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${items.length}${InventoryWidgetsText.containerItemsSuffix}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: NavigationTheme.itemsColor, size: 22),
                  onPressed: widget.onAddItem,
                  tooltip: InventoryWidgetsText.addItemTooltip,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      color: Colors.grey.shade400, size: 20),
                  onPressed: widget.onEditContainer,
                  tooltip: InventoryWidgetsText.editContainerTooltip,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red.shade400, size: 20),
                  onPressed: widget.onDeleteContainer,
                  tooltip: InventoryWidgetsText.deleteContainerTooltip,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade400,
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          // Items list
          if (_isExpanded && items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: items.map((item) {
                  final itemMap = item as Map<String, dynamic>;
                  final itemId = itemMap['id'] as String;
                  final qty = itemMap['quantity'];
                  final quantity = qty is int
                      ? qty
                      : int.tryParse(qty?.toString() ?? '1') ?? 1;
                  final description = itemMap['description'] as String?;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FormTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Row(
                      children: [
                        // Fantasy item icon
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: NavigationTheme.itemsColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.diamond_outlined, // Fantasy gem/item icon
                            color: NavigationTheme.itemsColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Item name and description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemMap['name'] as String? ??
                                    InventoryWidgetsText.defaultItemName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (description != null && description.isNotEmpty)
                                Text(
                                  description,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        // Quantity controls
                        Container(
                          decoration: BoxDecoration(
                            color: FormTheme.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(8)),
                                onTap: quantity > 1
                                    ? () => widget.onUpdateItemQuantity(
                                        itemId, quantity - 1)
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Icon(
                                    Icons.remove,
                                    size: 14,
                                    color: quantity > 1
                                        ? NavigationTheme.itemsColor
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => _showQuantityDialog(
                                    context, itemId, quantity),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(8)),
                                onTap: quantity < 999
                                    ? () => widget.onUpdateItemQuantity(
                                        itemId, quantity + 1)
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Icon(
                                    Icons.add,
                                    size: 14,
                                    color: quantity < 999
                                        ? NavigationTheme.itemsColor
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Edit button
                        IconButton(
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: Colors.grey.shade400),
                          onPressed: () => widget.onEditItem(itemId, itemMap),
                          tooltip: InventoryWidgetsText.editItemTooltip,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          visualDensity: VisualDensity.compact,
                        ),
                        // Delete button
                        IconButton(
                          icon: Icon(Icons.close,
                              size: 18, color: Colors.red.shade400),
                          onPressed: () => widget.onDeleteItem(itemId),
                          tooltip: InventoryWidgetsText.deleteItemTooltip,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          if (_isExpanded && items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                InventoryWidgetsText.emptyItemsMessage,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dialog for inputting a quantity value.
class _QuantityInputDialog extends StatefulWidget {
  const _QuantityInputDialog({required this.currentQuantity});

  final int currentQuantity;

  @override
  State<_QuantityInputDialog> createState() => _QuantityInputDialogState();
}

class _QuantityInputDialogState extends State<_QuantityInputDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentQuantity}');
    _focusNode = FocusNode();
    // Request focus after the dialog is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final qty = int.tryParse(_controller.text);
    if (qty != null && qty >= 1 && qty <= 999) {
      Navigator.of(context).pop(qty);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              InventoryWidgetsText.quantityDialogTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: InventoryWidgetsText.quantityDialogLabel,
                labelStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: FormTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: NavigationTheme.itemsColor),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    InventoryWidgetsText.quantityDialogCancelAction,
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NavigationTheme.itemsColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _submit,
                  child:
                      const Text(InventoryWidgetsText.quantityDialogSetAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
