class BookDetail {
  final int bookDetailID;
  final int bookID;
  final String description;
  final String publisher;
  final String language;
  final int pageCount;
  final String isbn;
  final double weight;
  final String dimensions;
  final String format;
  final String publicationDate;
  final String createdAt;
  final String? updatedAt;

  BookDetail({
    required this.bookDetailID,
    required this.bookID,
    required this.description,
    required this.publisher,
    required this.language,
    required this.pageCount,
    required this.isbn,
    required this.weight,
    required this.dimensions,
    required this.format,
    required this.publicationDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory BookDetail.fromJson(Map<String, dynamic> json) {
    return BookDetail(
      bookDetailID: json['BookDetailID'] ?? 0,
      bookID: json['BookID'] ?? 0,
      description: json['Description'] ?? '',
      publisher: json['Publisher'] ?? '',
      language: json['Language'] ?? '',
      pageCount: json['PageCount'] ?? 0,
      isbn: json['ISBN'] ?? '',
      weight: json['Weight'] != null ? double.parse(json['Weight'].toString()) : 0.0,
      dimensions: json['Dimensions'] ?? '',
      format: json['Format'] ?? '',
      publicationDate: json['PublicationDate'] ?? '',
      createdAt: json['CreatedAt'] ?? '',
      updatedAt: json['UpdatedAt'],
    );
  }
} 