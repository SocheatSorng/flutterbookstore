class BookReview {
  final int id;
  final int bookId;
  final String customerName;
  final int rating;
  final String content;
  final String createdAt;

  BookReview({
    required this.id,
    required this.bookId,
    required this.customerName,
    required this.rating,
    required this.content,
    required this.createdAt,
  });

  factory BookReview.fromJson(Map<String, dynamic> json) {
    return BookReview(
      id: json['id'] as int,
      bookId: json['book_id'] as int,
      customerName: json['customer_name'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'customer_name': customerName,
      'rating': rating,
      'content': content,
      'created_at': createdAt,
    };
  }
} 