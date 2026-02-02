/// Widget for displaying and managing a hero's coin purse.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/text/heroes_sheet/main_stats/coin_purse_text.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/theme/main_stats_theme.dart';
import 'coin_purse_model.dart';

/// A widget that displays and allows editing of coins in the purse.
class CoinPurseWidget extends StatefulWidget {
  const CoinPurseWidget({
    super.key,
    required this.coinPurse,
    required this.onChanged,
  });

  final CoinPurse coinPurse;
  final ValueChanged<CoinPurse> onChanged;

  @override
  State<CoinPurseWidget> createState() => _CoinPurseWidgetState();
}

class _CoinPurseWidgetState extends State<CoinPurseWidget> {
  late CoinPurse _purse;

  @override
  void initState() {
    super.initState();
    _purse = widget.coinPurse;
  }

  @override
  void didUpdateWidget(CoinPurseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coinPurse != widget.coinPurse) {
      _purse = widget.coinPurse;
    }
  }

  void _updatePurse(CoinPurse newPurse) {
    setState(() {
      _purse = newPurse;
    });
    widget.onChanged(newPurse);
  }

  Future<void> _showAddCoinDialog() async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final multiplierController = TextEditingController(text: '1.0');
    int selectedColor = MainStatsTheme.coinColors[0];

    final result = await showDialog<Coin>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: NavigationTheme.cardBackgroundDark,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade800),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(selectedColor).withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_circle, color: Color(selectedColor)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    CoinPurseText.addCoinTitle,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: CoinPurseText.coinNameLabel,
                      labelStyle: TextStyle(color: Colors.grey.shade400),
                      hintText: CoinPurseText.coinNameHint,
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(selectedColor)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: CoinPurseText.quantityLabel,
                            labelStyle: TextStyle(color: Colors.grey.shade400),
                            hintText: CoinPurseText.quantityHint,
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade700),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade700),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(selectedColor)),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: multiplierController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: CoinPurseText.valueLabel,
                            labelStyle: TextStyle(color: Colors.grey.shade400),
                            hintText: CoinPurseText.valueHint,
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade700),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade700),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(selectedColor)),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            LengthLimitingTextInputFormatter(8),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(CoinPurseText.colorLabel, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MainStatsTheme.coinColors.map((colorValue) {
                      final isSelected = selectedColor == colorValue;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = colorValue),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(colorValue),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected
                            ? [BoxShadow(color: Color(colorValue).withAlpha(150), blurRadius: 8)]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.black54)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade400,
                  ),
                  child: const Text(CoinPurseText.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final quantity = int.tryParse(quantityController.text);
                                  final multiplier = double.tryParse(multiplierController.text);
                    if (name.isNotEmpty && quantity != null && quantity > 0 && multiplier != null && multiplier > 0) {
                      Navigator.of(dialogContext).pop(
                        Coin(name: name, quantity: quantity, multiplier: multiplier, colorValue: selectedColor),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(selectedColor),
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text(CoinPurseText.add),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      _updatePurse(_purse.addCoin(result));
    }
  }

  Future<void> _showEditCoinDialog(int index, Coin coin) async {
    final nameController = TextEditingController(text: coin.name);
    final quantityController = TextEditingController(text: coin.quantity.toString());
    final multiplierController = TextEditingController(text: coin.multiplier.toString());
    int selectedColor = coin.colorValue;

    final result = await showDialog<Coin>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: NavigationTheme.cardBackgroundDark,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade800),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(selectedColor).withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit, color: Color(selectedColor)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    CoinPurseText.editCoinTitle,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: CoinPurseText.coinNameLabel,
                      labelStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(selectedColor)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: CoinPurseText.quantityLabel,
                            labelStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade700),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade700),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(selectedColor)),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: multiplierController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: CoinPurseText.valueLabel,
                            labelStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade700),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade700),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(selectedColor)),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            LengthLimitingTextInputFormatter(8),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(CoinPurseText.colorLabel, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MainStatsTheme.coinColors.map((colorValue) {
                      final isSelected = selectedColor == colorValue;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = colorValue),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(colorValue),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: Color(colorValue).withAlpha(150), blurRadius: 8)]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.black54)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade400,
                  ),
                  child: const Text(CoinPurseText.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final quantity = int.tryParse(quantityController.text);
                    final multiplier = double.tryParse(multiplierController.text);
                    if (name.isNotEmpty && quantity != null && quantity > 0 && multiplier != null && multiplier > 0) {
                      Navigator.of(dialogContext).pop(
                        Coin(id: coin.id, name: name, quantity: quantity, multiplier: multiplier, colorValue: selectedColor),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(selectedColor),
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text(CoinPurseText.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      _updatePurse(_purse.updateCoin(index, result));
    }
  }

  void _removeCoin(int index) {
    _updatePurse(_purse.removeCoin(index));
  }

  double _calculateReorderListHeight(int itemCount) {
    // Avoid shrink-wrapping viewports in dialogs (intrinsics crash).
    // Provide a bounded height and let the list scroll internally.
    const double minHeight = 68.0;
    const double maxHeight = 280.0;
    const double approxTileHeight = 62.0; // 56 height + 6 margin

    final double desired = itemCount <= 0 ? minHeight : itemCount * approxTileHeight;
    if (desired < minHeight) return minHeight;
    if (desired > maxHeight) return maxHeight;
    return desired;
  }

  String _formatMultiplier(double multiplier) {
    // Remove trailing zeros and decimal point if whole number
    String str = multiplier.toStringAsFixed(2);
    str = str.replaceAll(RegExp(r'0*$'), '');
    str = str.replaceAll(RegExp(r'\.$'), '');
    return str;
  }


  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color accentColor,
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: onPressed != null
                ? accentColor.withAlpha(180)
                : Colors.grey.shade700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: onPressed != null
              ? accentColor
              : Colors.grey.shade600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withAlpha(150),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade800.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, 
                size: 20, 
                color: Colors.amber.shade400,
              ),
              const SizedBox(width: 8),
              Text(
                'Coin Purse',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade400,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _showAddCoinDialog,
                icon: Icon(Icons.add_circle, color: Colors.amber.shade400),
                tooltip: CoinPurseText.add,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (_purse.coins.isEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  CoinPurseText.emptyState,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            SizedBox(
              height: _calculateReorderListHeight(_purse.coins.length),
              child: ReorderableListView.builder(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                _updatePurse(_purse.reorderCoins(oldIndex, newIndex));
              },
              itemCount: _purse.coins.length,
              itemBuilder: (context, index) {
                final coin = _purse.coins[index];
                final coinColor = Color(coin.colorValue);
                return Container(
                  key: ValueKey(coin.id),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: coinColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: coinColor.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      // Drag handle on the left
                      ReorderableDragStartListener(
                        index: index,
                        child: Container(
                          width: 28,
                          height: 56,
                          decoration: BoxDecoration(
                            color: coinColor.withAlpha(40),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(7),
                              bottomLeft: Radius.circular(7),
                            ),
                          ),
                          child: Icon(
                            Icons.drag_indicator,
                            size: 16,
                            color: coinColor.withAlpha(200),
                          ),
                        ),
                      ),
                      // Coin info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              // Name and calculation
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      coin.name,
                                      style: TextStyle(
                                        color: coinColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${coin.quantity} × ${_formatMultiplier(coin.multiplier)} = ${coin.totalValue.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity +/- buttons
                              _buildQuantityButton(
                                icon: Icons.remove,
                                accentColor: coinColor,
                                onPressed: coin.quantity > 1
                                    ? () {
                                        _updatePurse(_purse.updateCoin(
                                          index,
                                          Coin(
                                            id: coin.id,
                                            name: coin.name,
                                            quantity: coin.quantity - 1,
                                            multiplier: coin.multiplier,
                                            colorValue: coin.colorValue,
                                          ),
                                        ));
                                      }
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              _buildQuantityButton(
                                icon: Icons.add,
                                accentColor: coinColor,
                                onPressed: () {
                                  _updatePurse(_purse.updateCoin(
                                    index,
                                    Coin(
                                      id: coin.id,
                                      name: coin.name,
                                      quantity: coin.quantity + 1,
                                      multiplier: coin.multiplier,
                                      colorValue: coin.colorValue,
                                    ),
                                  ));
                                },
                              ),
                              const SizedBox(width: 4),
                              // Popup menu for edit/delete
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                iconSize: 18,
                                icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade500),
                                color: NavigationTheme.cardBackgroundDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey.shade700),
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditCoinDialog(index, coin);
                                  } else if (value == 'delete') {
                                    _removeCoin(index);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    height: 36,
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
                                        const SizedBox(width: 8),
                                        const Text(CoinPurseText.edit, style: TextStyle(color: Colors.white, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    height: 36,
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 16, color: Colors.red.shade400),
                                        const SizedBox(width: 8),
                                        Text(CoinPurseText.delete, style: TextStyle(color: Colors.red.shade400, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CoinPurseText.totalValueLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade300,
                  ),
                ),
                Text(
                  _purse.totalValue.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), ''),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade400,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


