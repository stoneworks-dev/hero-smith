class ItemsPageText {
  // App bar
  static const String appBarTitle = 'Items';

  // Search
  static const String searchHint = 'Search items...';

  // Filter categories
  static const String filterAll = 'All';
  static const String filterProjectMaterial = 'Project Materials';
  static const String filterTreasureComponent = 'Treasure Components';
  static const String filterEquipment = 'Equipment';
  static const String filterConsumable = 'Consumables';
  static const String filterCustom = 'Custom';

  // Category labels
  static const String categoryProjectMaterial = 'Project Material';
  static const String categoryEquipment = 'Equipment';
  static const String categoryConsumable = 'Consumable';
  static const String categoryCustom = 'Custom Item';
  static const String categoryItem = 'Item';

  // Empty states
  static const String emptyItems = 'No items yet';
  static const String emptyItemsSubtitle =
      'Items from downtime projects and custom items you create will appear here';
  static const String noSearchResults = 'No items match your search';

  // Actions
  static const String addItem = 'Create Item';
  static const String deleteItem = 'Delete Item';
  static const String editItem = 'Edit Item';

  // Create dialog
  static const String createItemTitle = 'Create New Item';
  static const String createItemNameLabel = 'Item Name';
  static const String createItemNameHint = 'e.g. Healing Potion';
  static const String createItemDescriptionLabel = 'Description (optional)';
  static const String createItemDescriptionHint = 'Describe the item...';
  static const String createItemCategoryLabel = 'Category';
  static const String cancel = 'Cancel';
  static const String create = 'Create';
  static const String save = 'Save';

  // Edit dialog
  static const String editItemTitle = 'Edit Item';

  // Delete dialog
  static const String deleteItemTitle = 'Delete Item?';
  static const String deleteItemMessage =
      'This will remove the item from the catalog. Items already in hero inventories will not be affected.';
  static const String delete = 'Delete';

  // Info labels
  static const String sourceSeeded = 'Game Data';
  static const String sourceUser = 'Custom';
  static String usedByProjects(int count) =>
      'Used by $count project${count != 1 ? 's' : ''}';

  // Snackbar
  static String itemCreated(String name) => '$name added to catalog';
  static String itemDeleted(String name) => '$name removed from catalog';
  static const String cannotDeleteSeeded =
      'Game data items cannot be deleted';
  static String failedToCreate(Object e) => 'Failed to create item: $e';
}
