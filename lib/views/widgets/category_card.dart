import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';

class CategoryCard extends StatelessWidget {
  final String categoryName;
  final int? categoryId;
  final VoidCallback? onTap;
  final bool isSelected;

  const CategoryCard({
    Key? key,
    required this.categoryName,
    this.categoryId,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, // Fixed width
        height: 100, // Fixed height
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AppColor.primary, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(categoryName),
              size: 40,
              color: isSelected ? AppColor.primary : Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                categoryName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColor.primary : AppColor.dark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fiction':
        return Icons.book;
      case 'non-fiction':
        return Icons.menu_book;
      case 'science':
        return Icons.science;
      case 'history':
        return Icons.history_edu;
      case 'biography':
        return Icons.person;
      case 'children':
        return Icons.child_care;
      case 'comics':
        return Icons.bubble_chart;
      case 'art':
        return Icons.palette;
      case 'cooking':
        return Icons.restaurant;
      default:
        return Icons.category;
    }
  }
} 