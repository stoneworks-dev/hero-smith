import 'package:flutter/material.dart';
import '../../../core/text/main_pages/gear/items_page_text.dart';

class GearItemsPage extends StatelessWidget {
  const GearItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ItemsPageText.appBarTitle)),
      body: const Center(
        child: Text(ItemsPageText.comingSoon),
      ),
    );
  }
}
