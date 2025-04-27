import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutterbookstore/models/book.dart';
import 'package:flutterbookstore/services/api_service.dart';
import 'package:flutterbookstore/views/widgets/book_card.dart';

class AllBooksPage extends StatefulWidget {
  const AllBooksPage({Key? key}) : super(key: key);

  @override
  State<AllBooksPage> createState() => _AllBooksPageState();
}

class _AllBooksPageState extends State<AllBooksPage> {
  final ApiService _apiService = ApiService();
  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      _books = await _apiService.getBooks();
      _filteredBooks = _books;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _searchBooks(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredBooks = _books;
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _searchQuery = query;
      _filteredBooks = _books.where((book) {
        final titleMatch = book.title.toLowerCase().contains(query.toLowerCase());
        final authorMatch = book.author.toLowerCase().contains(query.toLowerCase());
        return titleMatch || authorMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('All Books', style: TextStyle(color: AppColor.dark)),
        iconTheme: IconThemeData(color: AppColor.dark),
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColor.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColor.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search books, authors...',
                        hintStyle: TextStyle(color: AppColor.grey),
                        border: InputBorder.none,
                      ),
                      onChanged: _searchBooks,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: AppColor.grey),
                      onPressed: () {
                        _searchController.clear();
                        _searchBooks('');
                      },
                    ),
                ],
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _errorMessage.isNotEmpty
                ? _buildErrorWidget()
                : _isLoading
                    ? _buildLoadingWidget()
                    : _buildBooksGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColor.primary),
          const SizedBox(height: 16),
          Text(
            'Loading books...',
            style: TextStyle(color: AppColor.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColor.primary, size: 60),
            const SizedBox(height: 16),
            Text(
              'Error Loading Books',
              style: TextStyle(
                color: AppColor.dark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColor.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchBooks,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksGrid() {
    if (_filteredBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.library_books : Icons.search_off, 
              size: 80, 
              color: AppColor.grey.withOpacity(0.5)
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty 
                ? 'No books available' 
                : 'No books found for "$_searchQuery"',
              style: TextStyle(
                color: AppColor.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBooks,
      color: AppColor.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredBooks.length,
        itemBuilder: (context, index) {
          final book = _filteredBooks[index];
          return BookCard(
            title: book.title,
            author: book.author,
            coverImage: book.image != null && book.image!.isNotEmpty 
              ? book.image! 
              : 'https://via.placeholder.com/150/0d5c46/ffffff?text=${Uri.encodeComponent(book.title)}',
            price: book.price,
            rating: 4.5,
            bookData: book,
          );
        },
      ),
    );
  }
} 