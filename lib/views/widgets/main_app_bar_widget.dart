import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int cartValue;
  final int chatValue;
  final bool showBackButton;

  const MainAppBar({
    Key? key,
    this.cartValue = 0,
    this.chatValue = 0,
    this.showBackButton = false,
  }) : super(key: key);

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
      title: Container(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 30,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  'Book Store',
                  style: TextStyle(
                    color: AppColor.dark,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        // Chat Button
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.chat_outlined, color: AppColor.dark),
              ),
              if (chatValue > 0)
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
                      '$chatValue',
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
        // Cart Button
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
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
