class Book {
  final int bookID;
  final int categoryID;
  final String title;
  final String author;
  final double price;
  final int stockQuantity;
  final String? image;
  final String createdAt;
  final Map<String, dynamic>? category;

  Book({
    required this.bookID,
    required this.categoryID,
    required this.title,
    required this.author,
    required this.price,
    required this.stockQuantity,
    this.image,
    required this.createdAt,
    this.category,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      bookID: json['BookID'],
      categoryID: json['CategoryID'],
      title: json['Title'],
      author: json['Author'],
      price: double.parse(json['Price'].toString()),
      stockQuantity: json['StockQuantity'],
      image: json['Image'],
      createdAt: json['CreatedAt'],
      category: json['category'] != null ? Map<String, dynamic>.from(json['category']) : null,
    );
  }
} 