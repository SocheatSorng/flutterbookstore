import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../models/cart.dart';
import '../../services/cart_service.dart';

class EnhancedCartTile extends StatefulWidget {
  final Cart cart;
  final Function onQuantityChanged;
  final Function? onRemove;

  const EnhancedCartTile({
    super.key,
    required this.cart,
    required this.onQuantityChanged,
    this.onRemove,
  });

  @override
  _EnhancedCartTileState createState() => _EnhancedCartTileState();
}

class _EnhancedCartTileState extends State<EnhancedCartTile> with SingleTickerProviderStateMixin {
  bool _isUpdating = false;
  bool _isRemoving = false;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.2, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update quantity'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      if (widget.onRemove != null) {
        widget.onRemove!();
      } else {
        widget.onQuantityChanged();
      }
    } catch (e) {
      print('Error removing item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove item from cart'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    return Dismissible(
      key: Key(widget.cart.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final result = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text('Remove Item'),
              content: Text('Are you sure you want to remove this item from your cart?'),
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
                  child: Text('Remove', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
        if (result == true) {
          _removeItem();
        }
        return false; // We'll handle the removal ourselves
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(height: 4),
            Text('Remove', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx < 0) {
            _controller.forward();
          } else if (details.delta.dx > 0) {
            _controller.reverse();
          }
        },
        onHorizontalDragEnd: (details) {
          if (_controller.value > 0.5) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
        },
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image with animated container
                Hero(
                  tag: 'cart_image_${widget.cart.id}',
                  child: Container(
                    width: 90,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: widget.cart.image.isEmpty ? AppColor.lightGrey : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.cart.image.isEmpty
                          ? Icon(Icons.book, size: 40, color: AppColor.primary)
                          : Image.network(
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
                ),
                SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name
                      Text(
                        widget.cart.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColor.dark,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      // Price
                      Row(
                        children: [
                          Text(
                            '\$${widget.cart.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColor.primary,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'per item',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColor.grey,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Total and quantity controls in a row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Total price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColor.grey,
                                ),
                              ),
                              Text(
                                '\$${widget.cart.total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.secondary,
                                ),
                              ),
                            ],
                          ),
                          // Quantity controls
                          Container(
                            decoration: BoxDecoration(
                              color: AppColor.lightGrey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                // Decrease Button
                                InkWell(
                                  onTap: _isUpdating
                                      ? null
                                      : () => _updateQuantity(widget.cart.quantity - 1),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: widget.cart.quantity > 1
                                          ? AppColor.primary
                                          : AppColor.grey.withOpacity(0.3),
                                    ),
                                    child: _isUpdating
                                        ? SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            Icons.remove,
                                            size: 16,
                                            color: widget.cart.quantity > 1
                                                ? Colors.white
                                                : AppColor.grey,
                                          ),
                                  ),
                                ),
                                // Quantity
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 8),
                                  width: 30,
                                  child: Text(
                                    widget.cart.quantity.toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.dark,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                // Increase Button
                                InkWell(
                                  onTap: _isUpdating
                                      ? null
                                      : () => _updateQuantity(widget.cart.quantity + 1),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColor.primary,
                                    ),
                                    child: _isUpdating
                                        ? SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            Icons.add,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
