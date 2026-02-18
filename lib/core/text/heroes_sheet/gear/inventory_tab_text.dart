import '../../common/common_text.dart';

class InventoryTabText {
  static const String loadInventoryFailedPrefix = 'Failed to load inventory: ';
  static const String createContainerFailedPrefix = 'Failed to create container: ';
  static const String deleteContainerDialogTitle = 'Delete Container';
  static const String deleteContainerDialogContent =
      'Delete this container and all items inside? This cannot be undone.';
  static const String deleteContainerCancelAction = CommonText.cancel;
  static const String deleteContainerConfirmAction = CommonText.delete;
  static const String deleteContainerFailedPrefix = 'Failed to delete container: ';
  static const String addItemFailedPrefix = 'Failed to add item: ';
  static const String deleteItemFailedPrefix = 'Failed to delete item: ';
  static const String updateContainerFailedPrefix = 'Failed to update container: ';
  static const String updateItemFailedPrefix = 'Failed to update item: ';
  static const String updateQuantityFailedPrefix = 'Failed to update quantity: ';
  static const String inventoryTitle = 'Inventory';
  static const String newContainerButtonLabel = 'New Container';
  static const String defaultContainerName = 'Container';
  static const String emptyContainersMessage =
      'No containers yet.\nCreate a container to organize your items.';

  // Catalog search
  static const String searchCatalogTitle = 'Add From Catalog';
  static const String searchCatalogHint = 'Search items...';
  static const String searchCatalogEmpty = 'No items found';
  static const String searchCatalogEmptySubtitle =
      'Create items in the Items page to see them here';
  static const String addToCatalogAction = 'Add';

  // Loose items
  static const String looseItemsTitle = 'Loose Items';
  static const String looseItemsSubtitle = 'Items not in any container';
  static const String emptyLooseItems = 'No loose items';
  static const String addLooseItemTitle = 'Add Loose Item';
  static const String moveItemFailedPrefix = 'Failed to move item: ';

  // Move dialog
  static const String moveItemTitle = 'Move Item';
  static const String moveItemSubtitle = 'Select destination';
  static const String looseItemsDestination = 'Loose Items';
  static const String noDestinations = 'No other destinations available';
}
