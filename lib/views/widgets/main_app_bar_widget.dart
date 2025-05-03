import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutterbookstore/views/screens/cart_page.dart';
import 'package:flutterbookstore/views/widgets/app_logo.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int cartValue;
  final bool showBackButton;

  const MainAppBar({
    super.key,
    this.cartValue = 0,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading:
          showBackButton
              ? IconButton(
                icon: Icon(Icons.arrow_back, color: AppColor.dark),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
              : null,
      title: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [AppLogo(height: 30)],
        ),
      ),
      actions: [
        // Cart Button
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {
                  // Navigate to cart page
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) => CartPage()))
                      .then((_) {
                        // Force a rebuild to update cart count if needed
                        if (context is StatefulElement) {
                          (context.state).setState(() {});
                        }
                      });
                },
                icon: Icon(Icons.shopping_cart_outlined, color: AppColor.dark),
              ),
              if (cartValue > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$cartValue',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
