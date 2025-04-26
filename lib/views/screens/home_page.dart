import 'package:flutter/material.dart';
import 'package:flutterbookstore/config/app_config.dart';
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutterbookstore/models/book.dart';
import 'package:flutterbookstore/models/category.dart';
import 'package:flutterbookstore/services/api_service.dart';
import 'package:flutterbookstore/views/screens/login_page.dart';
import 'package:flutterbookstore/views/screens/api_test_page.dart';
import 'package:flutterbookstore/views/screens/cart_page.dart';
import 'package:flutterbookstore/views/screens/profile_page.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchData();
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
      _filteredBooks = _books; // Initially, filtered books are the same as all books

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

  // Search books based on query
  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredBooks = _books; // Reset to all books when query is empty
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
        _filteredBooks = _books.where((book) {
          final titleMatch = book.title.toLowerCase().contains(query.toLowerCase());
          final authorMatch = book.author.toLowerCase().contains(query.toLowerCase());
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

  void _changeSelectedNavBar(int index) {
    if (index == 3) {
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
      troubleshootingTips = [
        '• Check the API server settings',
        '• Current server: ${AppConfig.apiHost}',
      ];
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      _showServerSettingsDialog();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColor.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Server Settings',
                      style: TextStyle(color: AppColor.primary),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  _runNetworkDiagnostics();
                },
                icon: Icon(Icons.network_check, color: AppColor.primary),
                label: Text(
                  'Run Network Diagnostics',
                  style: TextStyle(color: AppColor.primary),
                ),
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, Book Lover!',
            style: TextStyle(
              color: AppColor.dark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Text(
            'Find your next book',
            style: TextStyle(
              color: AppColor.dark,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.api),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ApiTestPage()),
            );
          },
          tooltip: 'Test API Connection',
        ),
        IconButton(
          onPressed: () {
            _showServerSettingsDialog();
          },
          icon: Icon(Icons.settings, color: AppColor.dark),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.notifications_outlined, color: AppColor.dark),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CartPage()),
            );
          },
          icon: Icon(Icons.shopping_cart_outlined, color: AppColor.dark),
        ),
      ],
    );
  }

  // Show server settings dialog
  void _showServerSettingsDialog() {
    // Controllers for text fields
    final hostController = TextEditingController(text: AppConfig.apiHost);
    final portController = TextEditingController(text: AppConfig.apiPort.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Server Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'These settings control the connection to your backend API server. '
              'Changes will apply after restarting the app.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            SizedBox(height: 16),
            TextField(
              controller: hostController,
              decoration: InputDecoration(
                labelText: 'API Host',
                border: OutlineInputBorder(),
                helperText: 'Example: api.example.com or 192.168.1.100',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: portController,
              decoration: InputDecoration(
                labelText: 'API Port',
                border: OutlineInputBorder(),
                helperText: 'Standard HTTP port is 80, HTTPS is 443',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current API URL: ${AppConfig.apiBaseUrl}',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save settings logic would go here (requires more infrastructure)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Settings functionality is not implemented yet'),
                  backgroundColor: Colors.orange,
                ),
              );
              Navigator.of(context).pop();
            },
            child: Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppColor.primary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Top Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(height: 24),
          
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
                        TextButton.icon(
                          icon: Icon(Icons.refresh, size: 16),
                          label: Text('Run Network Diagnostics'),
                          onPressed: () {
                            // Add network diagnostics functionality
                            _runNetworkDiagnostics();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: Icon(Icons.settings, size: 16),
                          label: Text('Server Settings'),
                          onPressed: () {
                            // Navigate to server settings page
                            _showServerSettingsDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.red.shade700,
                          ),
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

          // If searching, show search results instead of regular sections
          if (_isSearching) 
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppColor.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Searching...',
                    style: TextStyle(color: AppColor.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          else if (_searchQuery.isNotEmpty) ...[
            _buildBooksSection('Search Results for "${_searchQuery}"', _filteredBooks),
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
                        style: TextStyle(color: AppColor.grey, fontWeight: FontWeight.w500),
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
          _buildBooksSection('New Releases', _books.reversed.take(5).toList()),
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
                style: TextButton.styleFrom(foregroundColor: AppColor.primary),
                child: Text(
                  'See All',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Category List from API
        SizedBox(
          height: 105,
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
                          child: CategoryCard(categoryName: category.name),
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
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: AppColor.primary),
                child: Text(
                  'See All',
                  style: TextStyle(fontWeight: FontWeight.w600),
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
                            coverImage: book.image != null && book.image!.isNotEmpty 
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
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1507842217343-583bb7270b66?q=80&w=1000'),
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
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
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
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Up to 50% off on selected books',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Shop Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          activeIcon: Icon(Icons.explore),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_border_outlined),
          activeIcon: Icon(Icons.bookmark),
          label: 'Wishlist',
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
      elevation: 8,
    );
  }

  // Run network diagnostics and show results
  Future<void> _runNetworkDiagnostics() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Running Diagnostics...'),
        content: SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    try {
      final result = await _apiService.checkServerConnection();
      
      // Pop the loading dialog
      Navigator.of(context).pop();
      
      // Show the results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Network Diagnostics Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connected to network: ${result['isConnected'] ? 'Yes' : 'No'}'),
              Text('Server response code: ${result['statusCode'] ?? 'N/A'}'),
              Text('Response time: ${result['responseTime']}ms'),
              if (result['error'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Error: ${result['error']}',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchData(); // Retry data fetch
              },
              child: Text('Retry Fetch'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Pop the loading dialog
      Navigator.of(context).pop();
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Diagnostics Failed'),
          content: Text('Could not run network diagnostics: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}