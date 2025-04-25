import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';

class CategoryCard extends StatelessWidget {
  final String name;
  final String iconPath;

  const CategoryCard({
    Key? key,
    required this.name,
    required this.iconPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _getCategoryIcon(name),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              color: AppColor.dark,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    // Use default icons based on category name
    IconData iconData;
    switch (category.toLowerCase()) {
      case 'fiction':
        iconData = Icons.book;
        break;
      case 'non-fiction':
        iconData = Icons.menu_book;
        break;
      case 'science':
        iconData = Icons.science;
        break;
      case 'history':
        iconData = Icons.history;
        break;
      default:
        iconData = Icons.category;
    }

    return Icon(
      iconData,
      size: 30,
      color: AppColor.primary,
    );
  }
} 