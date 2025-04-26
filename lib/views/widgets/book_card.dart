import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';

class BookCard extends StatelessWidget {
  final String title;
  final String author;
  final String coverImage;
  final double price;
  final double rating;

  const BookCard({
    Key? key,
    required this.title,
    required this.author,
    required this.coverImage,
    required this.price,
    required this.rating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Book Cover
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: SizedBox(
              height: 150,
              width: 150,
              child: _buildCoverImage(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColor.dark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Author
                  Text(
                    author,
                    style: TextStyle(
                      color: AppColor.grey,
                      fontWeight: FontWeight.w400,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Rating
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        rating.toString(),
                        style: TextStyle(
                          color: AppColor.dark,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Price and Buy Now Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      // Buy Now Icon Button
                      InkWell(
                        onTap: () {
                          _showBuyNowDialog(context);
                        },
                        child: Icon(
                          Icons.shopping_cart,
                          color: AppColor.primary,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    // Check if the coverImage is a remote URL or a local asset
    bool isRemoteImage = coverImage.startsWith('http');
    
    if (isRemoteImage) {
      return Image.network(
        coverImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback widget if the image fails to load
          return Container(
            color: AppColor.lightGrey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 36, color: AppColor.grey),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Image not available',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColor.grey,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColor.lightGrey,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: AppColor.primary,
              ),
            ),
          );
        },
      );
    } else {
      // Original fallback for local assets or missing images
      return Container(
        color: AppColor.lightGrey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, size: 36, color: AppColor.grey),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColor.dark,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showBuyNowDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Buy Now'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Do you want to purchase:'),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('by $author'),
              const SizedBox(height: 10),
              Text(
                'Price: \$${price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Proceed to checkout?',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Future implementation for checkout
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added to cart!'),
                    backgroundColor: AppColor.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
              ),
              child: Text('Add to Cart'),
            ),
          ],
        );
      },
    );
  }
} 