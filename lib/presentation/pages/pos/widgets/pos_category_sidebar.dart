import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';

class PosCategorySidebar extends StatefulWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const PosCategorySidebar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<PosCategorySidebar> createState() => _PosCategorySidebarState();
}

class _PosCategorySidebarState extends State<PosCategorySidebar> {
  bool _isExtended = false;

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Semua Kategori':
        return Icons.grid_view;
      case 'Favorit':
        return Icons.star_border;
      case 'Produk Paket':
        return Icons.inventory_2_outlined;
      case 'Produk Layanan':
        return Icons.menu_book_outlined;
      case 'Promo':
        return Icons.local_offer_outlined;
      case 'Deposit':
        return Icons.account_balance_wallet_outlined;
      case 'Makanan':
        return Icons
            .restaurant_menu; // We'll use a restaurant icon instead of "MA" text for consistency, or text can be used if preferred.
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExtended ? 240 : 88, // 88 for comfortable tablet touch target
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Expand / Collapse Button (matches top item in screenshot)
          InkWell(
            onTap: () {
              setState(() {
                _isExtended = !_isExtended;
              });
            },
            child: Container(
              height: 88, // Square aspect ratio
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              alignment: Alignment.center,
              child: Transform.scale(
                scaleX: _isExtended
                    ? 1
                    : -1, // Mirrors menu_open to point right when collapsed
                child: const Icon(
                  Icons.menu_open,
                  color: Colors.black87,
                  size: 24, // Smaller icon gives more visual padding
                ),
              ),
            ),
          ),
          // Categories List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: widget.categories.length,
              itemBuilder: (context, index) {
                final category = widget.categories[index];
                final isSelected = category == widget.selectedCategory;

                Widget iconWidget;
                if (category == 'Makanan') {
                  iconWidget = Text(
                    'MA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  );
                } else {
                  iconWidget = Icon(
                    _getIconForCategory(category),
                    color: isSelected ? AppColors.primary : Colors.black87,
                    size: 24, // Smaller icon
                  );
                }

                return InkWell(
                  onTap: () => widget.onCategorySelected(category),
                  child: Container(
                    height:
                        88, // Perfect square in collapsed state gives more padding
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE6F7F3)
                          : Colors.transparent,
                      border: isSelected
                          ? Border(
                              left: const BorderSide(
                                color: AppColors.primary,
                                width: 4,
                              ),
                              top: const BorderSide(
                                color: AppColors.primary,
                                width: 1,
                              ),
                              bottom: const BorderSide(
                                color: AppColors.primary,
                                width: 1,
                              ),
                              right: const BorderSide(
                                color: AppColors.primary,
                                width: 1,
                              ),
                            )
                          : Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                    ),
                    child: Row(
                      mainAxisAlignment: _isExtended
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        if (_isExtended) const SizedBox(width: 24),
                        // Wrap icon in a container with left margin to offset the thick left border when centered
                        Container(
                          margin: EdgeInsets.only(
                            right: isSelected && !_isExtended ? 4 : 0,
                          ),
                          child: iconWidget,
                        ),
                        if (_isExtended) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
