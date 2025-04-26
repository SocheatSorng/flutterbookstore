import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';

class MenuTileWidget extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final EdgeInsetsGeometry margin;
  final Color titleColor;
  final Color? iconBackground;
  final Function() onTap;

  const MenuTileWidget({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.margin = const EdgeInsets.all(0),
    this.titleColor = AppColor.dark,
    this.iconBackground,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColor.border, width: 1)),
        ),
        child: Row(
          children: [
            // Left Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: iconBackground ?? AppColor.lightGrey,
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppColor.grey, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Forward Icon
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColor.dark.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
