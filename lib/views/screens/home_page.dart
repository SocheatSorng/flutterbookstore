import 'package:flutter/material.dart';
import 'package:flutterbookstore/config/app_config.dart';
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutterbookstore/models/book.dart';
import 'package:flutterbookstore/models/category.dart';
import 'package:flutterbookstore/services/api_service.dart';
import 'package:flutterbookstore/services/cart_service.dart';
import 'package:flutterbookstore/views/screens/login_page.dart';
import 'package:flutterbookstore/views/screens/cart_page.dart';
import 'package:flutterbookstore/views/screens/profile_page.dart';
import 'package:flutterbookstore/views/screens/all_books_page.dart';
import 'package:flutterbookstore/views/widgets/book_card.dart';
import 'package:flutterbookstore/views/widgets/category_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedNavbar = 0;
  final ApiService _apiService = ApiService();
  List<Book> _books = [];
  List<Book> _filteredBooks = []; // For displaying search results
  bool _isLoading = true;
  bool _isSearching = false; // Flag to track if search is in progress
  String _errorMessage = '';
  String _searchQuery = ''; // Store the current search query
  List<BookCategory> _categories = [];
  final TextEditingController _searchController = TextEditingController();

  // Add state for category filtering
  BookCategory? _selectedCategory;
  bool _isLoadingCategory = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadCartData(); // Load cart data when homepage initializes
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch books from API
      _books = await _apiService.getBooks();
      _filteredBooks =
          _books; // Initially, filtered books are the same as all books

      // Fetch categories from API
      _categories = await _apiService.getCategories();

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

  // Load cart data to display the badge
  Future<void> _loadCartData() async {
    try {
      await CartService.fetchCartItems();
      setState(() {
        // Just refresh the state to update the badge
      });
    } catch (e) {
      print('Error loading cart data: $e');
    }
  }

  // Search books based on query
  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredBooks = _books; // Reset to all books when query is empty
        _searchQuery = ''; // Clear the search query when empty
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
      _errorMessage = '';
    });

    try {
      final results = await _apiService.searchBooks(query);

      setState(() {
        _filteredBooks = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Search failed: ${e.toString()}';

        // Keep showing the current books instead of emptying the list
        // This provides a better user experience when search fails
        _filteredBooks =
            _books.where((book) {
              final titleMatch = book.title.toLowerCase().contains(
                query.toLowerCase(),
              );
              final authorMatch = book.author.toLowerCase().contains(
                query.toLowerCase(),
              );
              return titleMatch || authorMatch;
            }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search error: Server unavailable'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: () => _searchBooks(query),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Add a new method to fetch books by category
  Future<void> _fetchBooksByCategory(BookCategory category) async {
    setState(() {
      _isLoadingCategory = true;
      _errorMessage = '';
      _selectedCategory = category;
    });

    try {
      final books = await _apiService.getBooksByCategory(category.categoryID);

      setState(() {
        _filteredBooks = books;
        _isLoadingCategory = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategory = false;
        _errorMessage = 'Failed to load books for category: ${e.toString()}';
        // Try to filter books locally if API fails
        _filteredBooks =
            _books
                .where((book) => book.categoryID == category.categoryID)
                .toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading books for ${category.name}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: () => _fetchBooksByCategory(category),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Add a method to clear category filtering
  void _clearCategoryFilter() {
    setState(() {
      _selectedCategory = null;
      _filteredBooks = _books;
    });
  }

  void _changeSelectedNavBar(int index) {
    if (index == 1) {
      // Navigate to All Books page when Books tab is selected
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AllBooksPage()),
      );
      return;
    }

    if (index == 2) {
      // Navigate to profile page when Profile tab is selected
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
      return;
    }

    setState(() {
      _selectedNavbar = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body:
          _errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : _isLoading
              ? _buildLoadingWidget()
              : _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildErrorWidget() {
    // Extract meaningful error message for common connection errors
    String errorTitle = 'Error Loading Data';
    String errorMessage = _errorMessage;
    List<String> troubleshootingTips = [];

    if (_errorMessage.contains('SocketException') ||
        _errorMessage.contains('Connection refused') ||
        _errorMessage.contains('Connection timed out')) {
      errorTitle = 'Connection Error';
      errorMessage =
          'Could not connect to the API server at ${AppConfig.apiBaseUrl}';

      troubleshootingTips = [
        '• Check your internet connection',
        '• The remote server might be down',
        '• Try again later',
        '• If problem persists, contact support',
      ];
    } else if (_errorMessage.contains('Invalid host')) {
      errorTitle = 'Invalid Host';
      errorMessage = 'The API server address is invalid';
      troubleshootingTips = ['• Check the API server settings'];
    } else if (_errorMessage.contains('TimeoutException') ||
        _errorMessage.contains('Future not completed')) {
      errorTitle = 'Server Timeout';
      errorMessage =
          'The API server at ${AppConfig.apiBaseUrl} is taking too long to respond';

      troubleshootingTips = [
        '• The server might be experiencing high traffic',
        '• Your internet connection might be slow',
        '• Try again later',
        '• If problem persists, contact support',
      ];
    }

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColor.primary, size: 60),
              const SizedBox(height: 16),
              Text(
                errorTitle,
                style: TextStyle(
                  color: AppColor.dark,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColor.grey, fontSize: 14),
              ),
              if (troubleshootingTips.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Troubleshooting Tips:',
                  style: TextStyle(
                    color: AppColor.dark,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...troubleshootingTips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      tip,
                      style: TextStyle(color: AppColor.grey, fontSize: 14),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchData,
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColor.lightGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(Icons.search, color: AppColor.grey, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search books, authors...',
                  hintStyle: TextStyle(color: AppColor.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 12),
                ),
                onChanged: (value) {
                  // Debounce search to avoid too many API calls
                  Future.delayed(Duration(milliseconds: 500), () {
                    if (value == _searchController.text) {
                      _searchBooks(value);
                    }
                  });
                },
                textInputAction: TextInputAction.search,
                onSubmitted: _searchBooks,
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: AppColor.grey, size: 18),
                constraints: BoxConstraints(maxWidth: 30),
                padding: EdgeInsets.zero,
                onPressed: () {
                  _searchController.clear();
                  _searchBooks('');
                },
              ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.notifications_outlined, color: AppColor.dark),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartPage()),
                ).then((_) {
                  // Refresh the cart count when returning from CartPage
                  setState(() {});
                });
              },
              icon: Icon(Icons.shopping_cart_outlined, color: AppColor.dark),
            ),
            if (CartService.itemCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '${CartService.itemCount}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppColor.primary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Error message display
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Error Loading Data',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _fetchData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.red.shade700,
                          ),
                          child: Text('Try Again'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Banner Section
          _buildBannerSection(),
          const SizedBox(height: 24),

          // If a category is selected, show a banner for it
          if (_selectedCategory != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColor.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category, color: AppColor.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Showing books in "${_selectedCategory!.name}" category',
                        style: TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColor.primary),
                      onPressed: _clearCategoryFilter,
                      tooltip: 'Clear filter',
                    ),
                  ],
                ),
              ),
            ),
          if (_selectedCategory != null) const SizedBox(height: 16),

          // If searching, show search results instead of regular sections
          if (_isSearching || _isLoadingCategory)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColor.primary),
                    const SizedBox(height: 16),
                    Text(
                      _isSearching
                          ? 'Searching...'
                          : 'Loading books for ${_selectedCategory!.name}...',
                      style: TextStyle(
                        color: AppColor.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_searchQuery.isNotEmpty) ...[
            _buildBooksSection(
              'Search Results for "${_searchQuery}"',
              _filteredBooks,
            ),
            if (_filteredBooks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 64, color: AppColor.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No books found for "${_searchQuery}"',
                        style: TextStyle(
                          color: AppColor.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ] else if (_selectedCategory != null) ...[
            // Show books for selected category
            _buildBooksSection(
              'Books in ${_selectedCategory!.name}',
              _filteredBooks,
            ),
            if (_filteredBooks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(Icons.book_outlined, size: 64, color: AppColor.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No books found in ${_selectedCategory!.name} category',
                        style: TextStyle(
                          color: AppColor.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ] else ...[
            // Categories Section from API
            _buildCategoriesSection(),
            const SizedBox(height: 24),

            // Popular Books Section
            _buildBooksSection('Popular Books', _books.take(5).toList()),
            const SizedBox(height: 24),

            // New Releases Section
            _buildBooksSection(
              'New Releases',
              _books.reversed.take(5).toList(),
            ),
            const SizedBox(height: 24),

            // Books From API
            _buildBooksSection('All Books', _books),
            const SizedBox(height: 24),

            // Featured Author Section
            _buildFeaturedAuthorSection(),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: TextStyle(
                  color: AppColor.dark,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColor.primary,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: AppColor.primary.withOpacity(0.3)),
                  ),
                ),
                child: Text(
                  'See All',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Category List from API
        SizedBox(
          height: 115,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child:
                _categories.isEmpty
                    ? Center(
                      child: Text(
                        'No categories available',
                        style: TextStyle(color: AppColor.grey),
                      ),
                    )
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: CategoryCard(
                            categoryName: category.name,
                            categoryId: category.categoryID,
                            isSelected:
                                _selectedCategory?.categoryID ==
                                category.categoryID,
                            onTap: () => _fetchBooksByCategory(category),
                          ),
                        );
                      },
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildBooksSection(String title, List<Book> books) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColor.dark,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to All Books page when See All is tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AllBooksPage()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColor.primary,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: AppColor.primary.withOpacity(0.3)),
                  ),
                ),
                child: Text(
                  'See All',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 290,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child:
                books.isEmpty
                    ? Center(
                      child: Text(
                        'No books available',
                        style: TextStyle(color: AppColor.grey),
                      ),
                    )
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: BookCard(
                            title: book.title,
                            author: book.author,
                            coverImage:
                                book.image != null && book.image!.isNotEmpty
                                    ? book.image!
                                    : 'https://via.placeholder.com/150/0d5c46/ffffff?text=${Uri.encodeComponent(book.title)}',
                            price: book.price,
                            rating: 4.5, // Default rating
                            bookData: book,
                          ),
                        );
                      },
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerSection() {
    return Container(
      height: 180,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1507842217343-583bb7270b66?q=80&w=1000',
          ),
          fit: BoxFit.cover,
          colorFilter: const ColorFilter.mode(
            Color.fromRGBO(13, 92, 70, 0.8),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Summer Reading Sale',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Up to 50% off on selected books',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.local_offer, size: 16),
                    label: Text(
                      'Shop Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedAuthorSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Author',
            style: TextStyle(
              color: AppColor.dark,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColor.lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColor.accent,
                  child: CircleAvatar(
                    radius: 38,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1544717305-2782549b5136?q=80&w=1000',
                    ),
                    onBackgroundImageError: (_, __) {
                      // Handle error when image is not available
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'J.K. Rowling',
                        style: TextStyle(
                          color: AppColor.dark,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Author of Harry Potter series and other magical books',
                        style: TextStyle(color: AppColor.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: AppColor.primary,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'View Profile',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Books',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedNavbar,
          selectedItemColor: AppColor.primary,
          unselectedItemColor: AppColor.grey,
          showUnselectedLabels: true,
          onTap: _changeSelectedNavBar,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
        ),
      ),
    );
  }
}
