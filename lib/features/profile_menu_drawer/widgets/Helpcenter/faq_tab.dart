import 'package:flutter/material.dart';
import 'faq_category_chips.dart';
import 'faq_search_bar.dart';
import 'faq_list.dart';

class FaqTab extends StatefulWidget {
  const FaqTab({super.key});

  @override
  State<FaqTab> createState() => _FaqTabState();
}

class _FaqTabState extends State<FaqTab> {
  String selectedCategory = 'General';

  void _onCategoryChanged(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(color: Color.fromARGB(255, 51, 3, 66)),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// CATEGORY CHIPS ROW
              FaqCategoryChips(
                onCategoryChanged: _onCategoryChanged,
                selectedCategory: selectedCategory,
              ),

              const SizedBox(height: 25),

              /// SEARCH BAR
              FaqSearchBar(selectedCategory: selectedCategory),

              const SizedBox(height: 20),

              /// FAQ LIST - Only show when General is selected
              if (selectedCategory == 'General')
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: const FaqList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
