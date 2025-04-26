class BookCategory {
  final int categoryID;
  final String name;
  final String? description;
  final String? image;
  final String createdAt;
  final int? booksCount;

  BookCategory({
    required this.categoryID,
    required this.name,
    this.description,
    this.image,
    required this.createdAt,
    this.booksCount,
  });

  factory BookCategory.fromJson(Map<String, dynamic> json) {
    return BookCategory(
      categoryID: json['CategoryID'],
      name: json['Name'],
      description: json['Description'],
      image: json['Image'],
      createdAt: json['CreatedAt'],
      booksCount: json['books_count'],
    );
  }
} 