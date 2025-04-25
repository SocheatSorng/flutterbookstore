class Book {
  final int id;
  final String title;
  final String author;
  final String coverImage;
  final double rating;
  final int totalReview;
  final String description;
  final double price;
  final bool isBestSeller;
  final bool isNewRelease;
  final String category;
  final int pages;
  final String publisher;
  final String language;
  final String isbn;
  final List<String> images;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverImage,
    required this.rating,
    required this.totalReview,
    required this.description,
    required this.price,
    this.isBestSeller = false,
    this.isNewRelease = false,
    required this.category,
    required this.pages,
    required this.publisher,
    required this.language,
    required this.isbn,
    required this.images,
  });
} 