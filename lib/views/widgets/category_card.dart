import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';

class CategoryCard extends StatelessWidget {
  final String categoryName;

  const CategoryCard({
    Key? key,
    required this.categoryName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, // Fixed width
      height: 100, // Fixed height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              categoryName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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