class Cart {
  final String id;
  final String bookId;
  final String title;
  final String image;
  final double price;
  int quantity;

  Cart({
    required this.id,
    required this.bookId,
    required this.title,
    required this.image,
    required this.price,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Cart copyWith({
    String? id,
    String? bookId,
    String? title,
    String? image,
    double? price,
    int? quantity,
  }) {
    return Cart(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      image: image ?? this.image,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}
