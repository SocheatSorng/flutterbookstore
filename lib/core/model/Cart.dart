class Cart {
  final int id;
  final int bookId;
  final String bookTitle;
  final String bookAuthor;
  final String bookCover;
  final double bookPrice;
  final int quantity;

  Cart({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookCover,
    required this.bookPrice,
    required this.quantity,
  });

  double get totalPrice => bookPrice * quantity;
} 