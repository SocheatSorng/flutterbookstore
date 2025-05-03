import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../services/cart_service.dart';

class CartAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBackPressed;
  final VoidCallback? onClearCart;
  final bool isEmpty;

  const CartAppBar({
    super.key,
    required this.onBackPressed,
    this.onClearCart,
    this.isEmpty = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 1);

  @override
  _CartAppBarState createState() => _CartAppBarState();
}

class _CartAppBarState extends State<CartAppBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isClearingCart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmClearCart() async {
    if (widget.isEmpty || _isClearingCart) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Clear Cart'),
          content: Text('Are you sure you want to remove all items from your cart?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: AppColor.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Clear Cart', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (result == true && widget.onClearCart != null) {
      setState(() {
        _isClearingCart = true;
      });
      
      try {
        await CartService.clearCart();
        widget.onClearCart!();
      } finally {
        if (mounted) {
          setState(() {
            _isClearingCart = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: AppColor.dark, size: 20),
                onPressed: widget.onBackPressed,
              ),
              title: Column(
                children: [
                  Text(
                    'Your Cart',
                    style: TextStyle(
                      color: AppColor.dark,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!widget.isEmpty)
                    Text(
                      '${CartService.itemCount} items',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColor.grey,
                      ),
                    ),
                ],
              ),
              actions: [
                if (!widget.isEmpty)
                  _isClearingCart
                      ? Container(
                          width: 48,
                          height: 48,
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: _confirmClearCart,
                          tooltip: 'Clear cart',
                        ),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: AppColor.border,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
