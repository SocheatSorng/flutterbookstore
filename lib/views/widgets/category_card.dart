import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';

class CategoryCard extends StatefulWidget {
  final String categoryName;
  final int? categoryId;
  final VoidCallback? onTap;
  final bool isSelected;

  const CategoryCard({
    super.key,
    required this.categoryName,
    this.categoryId,
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
    setState(() {
      _isHovered = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    setState(() {
      _isHovered = false;
    });
  }

  void _onTapCancel() {
    _animationController.reverse();
    setState(() {
      _isHovered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors(widget.categoryName);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          width: 100,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  widget.isSelected
                      ? [AppColor.primary.withOpacity(0.7), AppColor.primary]
                      : gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:
                    widget.isSelected
                        ? AppColor.primary.withOpacity(0.3)
                        : gradientColors[0].withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background Pattern
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Opacity(
                    opacity: 0.1,
                    child: CustomPaint(
                      painter: PatternPainter(isSelected: widget.isSelected),
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon with background
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getCategoryIcon(widget.categoryName),
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Category name
                    Flexible(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatCategoryName(widget.categoryName),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: -0.2,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Selected Indicator
              if (widget.isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check,
                        size: 12,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to format category names for better display
  String _formatCategoryName(String name) {
    // Special handling for specific categories
    if (name.toLowerCase() == 'non-fiction') {
      return 'Non-\nFiction';
    }
    if (name.toLowerCase().contains('children')) {
      return "Children's\nBooks";
    }
    return name;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fiction':
        return Icons.auto_stories;
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
      case 'technology':
        return Icons.computer;
      case 'business':
        return Icons.business;
      case 'romance':
        return Icons.favorite;
      case 'thriller':
        return Icons.psychology;
      case 'fantasy':
        return Icons.auto_awesome;
      case 'mystery':
        return Icons.search;
      default:
        return Icons.category;
    }
  }

  List<Color> _getGradientColors(String category) {
    switch (category.toLowerCase()) {
      case 'fiction':
        return [Color(0xFF5C6BC0), Color(0xFF3949AB)];
      case 'non-fiction':
        return [Color(0xFF26A69A), Color(0xFF00897B)];
      case 'science':
        return [Color(0xFF66BB6A), Color(0xFF43A047)];
      case 'history':
        return [Color(0xFFFF7043), Color(0xFFE64A19)];
      case 'biography':
        return [Color(0xFF7E57C2), Color(0xFF5E35B1)];
      case 'children':
        return [Color(0xFF42A5F5), Color(0xFF1E88E5)];
      case 'comics':
        return [Color(0xFFEF5350), Color(0xFFE53935)];
      case 'art':
        return [Color(0xFFEC407A), Color(0xFFD81B60)];
      case 'cooking':
        return [Color(0xFFFFA726), Color(0xFFFB8C00)];
      case 'technology':
        return [Color(0xFF29B6F6), Color(0xFF039BE5)];
      case 'business':
        return [Color(0xFF78909C), Color(0xFF546E7A)];
      case 'romance':
        return [Color(0xFFF06292), Color(0xFFD81B60)];
      case 'thriller':
        return [Color(0xFF5C6BC0), Color(0xFF3949AB)];
      case 'fantasy':
        return [Color(0xFF7986CB), Color(0xFF3F51B5)];
      case 'mystery':
        return [Color(0xFF8D6E63), Color(0xFF6D4C41)];
      default:
        return [Color(0xFF9E9E9E), Color(0xFF757575)];
    }
  }
}

class PatternPainter extends CustomPainter {
  final bool isSelected;

  PatternPainter({this.isSelected = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Draw pattern of circles or dots
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        final x = size.width / 5 * i;
        final y = size.height / 5 * j;
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }

    // Draw some diagonal lines
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);

    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
