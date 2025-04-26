import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../models/cart.dart';
import '../../services/cart_service.dart';

class CartTile extends StatefulWidget {
  final Cart cart;
  final Function onQuantityChanged;

  CartTile({required this.cart, required this.onQuantityChanged});

  @override
  _CartTileState createState() => _CartTileState();
}

class _CartTileState extends State<CartTile> {
  bool _isUpdating = false;
  bool _isRemoving = false;

  Future<void> _updateQuantity(int newQuantity) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // Make sure quantity is at least 1
      if (newQuantity < 1) newQuantity = 1;

      await CartService.updateQuantity(widget.cart.id, newQuantity);
      widget.onQuantityChanged();
    } catch (e) {
      print('Error updating quantity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update quantity'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _removeItem() async {
    if (_isRemoving) return;

    setState(() {
      _isRemoving = true;
    });

    try {
      await CartService.removeFromCart(widget.cart.id);
      widget.onQuantityChanged();
    } catch (e) {
      print('Error removing item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove item from cart'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRemoving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 120,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.border, width: 1),
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 80,
            height: 80,
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: widget.cart.image.isEmpty ? AppColor.lightGrey : null,
            ),
            child:
                widget.cart.image.isEmpty
                    ? Icon(Icons.book, size: 40, color: AppColor.primary)
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.cart.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColor.lightGrey,
                            child: Icon(
                              Icons.book,
                              size: 40,
                              color: AppColor.primary,
                            ),
                          );
                        },
                      ),
                    ),
          ),
          // Info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  widget.cart.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColor.secondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                // Product price
                Text(
                  '\$${widget.cart.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary,
                  ),
                ),
                SizedBox(height: 6),
                // Quantity
                Row(
                  children: [
                    // Decrease Button
                    GestureDetector(
                      onTap:
                          _isUpdating
                              ? null
                              : () => _updateQuantity(widget.cart.quantity - 1),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: AppColor.lightGrey,
                        ),
                        child:
                            _isUpdating
                                ? SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColor.primary,
                                  ),
                                )
                                : Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: AppColor.dark,
                                ),
                      ),
                    ),
                    // Quantity
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        widget.cart.quantity.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColor.dark,
                        ),
                      ),
                    ),
                    // Increase Button
                    GestureDetector(
                      onTap:
                          _isUpdating
                              ? null
                              : () => _updateQuantity(widget.cart.quantity + 1),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: AppColor.lightGrey,
                        ),
                        child:
                            _isUpdating
                                ? SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColor.primary,
                                  ),
                                )
                                : Icon(
                                  Icons.add,
                                  size: 16,
                                  color: AppColor.dark,
                                ),
                      ),
                    ),
                    Spacer(),
                    // Remove Button
                    GestureDetector(
                      onTap: _isRemoving ? null : _removeItem,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color:
                              _isRemoving
                                  ? Colors.red.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.1),
                        ),
                        child:
                            _isRemoving
                                ? SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                )
                                : Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red,
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
