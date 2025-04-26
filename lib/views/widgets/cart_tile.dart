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
              image: DecorationImage(
                image: AssetImage(widget.cart.image),
                fit: BoxFit.cover,
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
                  'Rp ${widget.cart.price.toStringAsFixed(0)}',
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
                    // Decrease quantity button
                    GestureDetector(
                      onTap: () {
                        if (widget.cart.quantity > 1) {
                          CartService.updateQuantity(
                            widget.cart.id,
                            widget.cart.quantity - 1,
                          );
                          setState(() {});
                          widget.onQuantityChanged();
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColor.primarySoft,
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                    // Quantity
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${widget.cart.quantity}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColor.secondary,
                        ),
                      ),
                    ),
                    // Increase quantity button
                    GestureDetector(
                      onTap: () {
                        CartService.updateQuantity(
                          widget.cart.id,
                          widget.cart.quantity + 1,
                        );
                        setState(() {});
                        widget.onQuantityChanged();
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColor.primarySoft,
                        ),
                        child: Icon(
                          Icons.add,
                          size: 16,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                    Spacer(),
                    // Remove button
                    GestureDetector(
                      onTap: () {
                        CartService.removeFromCart(widget.cart.id);
                        widget.onQuantityChanged();
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.red.withOpacity(0.1),
                        ),
                        child: Icon(
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
