import 'package:flutter/material.dart';
import 'package:flutterbookstore/config/app_config.dart';
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutterbookstore/models/book.dart';
import 'package:flutterbookstore/models/category.dart';
import 'package:flutterbookstore/services/api_service.dart';
import 'package:flutterbookstore/views/screens/login_page.dart';
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
  bool _isLoading = true;
  String _errorMessage = '';
  List<BookCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch books from API
      _books = await _apiService.getBooks();
      
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

  void _changeSelectedNavBar(int index) {
    setState(() {
      _selectedNavbar = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _errorMessage.isNotEmpty
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
    
    if (_errorMessage.contains('SocketException') || _errorMessage.contains('Connection refused') || _errorMessage.contains('Connection timed out')) {
      errorTitle = 'Connection Error';
      errorMessage = 'Could not connect to the API server at ${AppConfig.apiBaseUrl}';
      
      troubleshootingTips = [
        '• Check your internet connection',
        '• The remote server might be down',
        '• Try again later',
        '• If problem persists, contact support'
      ];
    } else if (_errorMessage.contains('Invalid host')) {
      errorTitle = 'Invalid Host';
      errorMessage = 'The API server address is invalid';
      troubleshootingTips = [
        '• Check the API server settings',
        '• Current server: ${AppConfig.apiHost}'
      ];
    } else if (_errorMessage.contains('TimeoutException') || _errorMessage.contains('Future not completed')) {
      errorTitle = 'Server Timeout';
      errorMessage = 'The API server at ${AppConfig.apiBaseUrl} is taking too long to respond';
      
      troubleshootingTips = [
        '• The server might be experiencing high traffic',
        '• Your internet connection might be slow',
        '• Try again later',
        '• If problem persists, contact support'
      ];
    }
    
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: AppColor.primary,
                size: 60,
              ),
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
                style: TextStyle(
                  color: AppColor.grey,
                  fontSize: 14,
                ),
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
                      style: TextStyle(
                        color: AppColor.grey,
                        fontSize: 14,
                      ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Server Settings',
                      style: TextStyle(
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  _runNetworkDiagnostics();
                },
                icon: Icon(
                  Icons.network_check,
                  color: AppColor.primary,
                ),
                label: Text(
                  'Run Network Diagnostics',
                  style: TextStyle(
                    color: AppColor.primary,
                  ),
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
          CircularProgressIndicator(
            color: AppColor.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading books...',
            style: TextStyle(
              color: AppColor.grey,
              fontWeight: FontWeight.w500,
            ),
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
          onPressed: () {
            _showServerSettingsDialog();
          },
          icon: Icon(
            Icons.settings,
            color: AppColor.dark,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.notifications_outlined,
            color: AppColor.dark,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.shopping_cart_outlined,
            color: AppColor.dark,
          ),
        ),
      ],
    );
  }

  // Show server settings dialog
  void _showServerSettingsDialog() {
    final TextEditingController ipController = TextEditingController(text: AppConfig.apiHost);
    final TextEditingController portController = TextEditingController(text: AppConfig.apiPort.toString());
    final TextEditingController timeoutController = TextEditingController(text: AppConfig.connectionTimeoutSeconds.toString());
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Server Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                decoration: InputDecoration(
                  labelText: 'Server IP',
                  hintText: 'e.g., 192.168.0.117',
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: portController,
                decoration: InputDecoration(
                  labelText: 'Server Port',
                  hintText: 'e.g., 8000',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              TextField(
                controller: timeoutController,
                decoration: InputDecoration(
                  labelText: 'Connection Timeout (seconds)',
                  hintText: 'e.g., 30',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              Text(
                'Current API URL: ${AppConfig.apiBaseUrl}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColor.grey,
                ),
              ),
              SizedBox(height: 8),
              if (_errorMessage.isNotEmpty)
                Text(
                  'Last Error: ${_errorMessage.split(':').first}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newIp = ipController.text;
                final newPort = int.tryParse(portController.text) ?? 8000;
                final newTimeout = int.tryParse(timeoutController.text) ?? 30;
                
                if (newIp.isNotEmpty) {
                  setState(() {
                    AppConfig.apiHost = newIp;
                    AppConfig.apiPort = newPort;
                  });
                  
                  Navigator.of(context).pop();
                  
                  // Refresh data with new settings
                  _fetchData();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Server settings updated!'),
                      backgroundColor: AppColor.primary,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
              ),
              child: Text('Save'),
            ),
          ],
        );
      },
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
                  Icon(
                    Icons.search,
                    color: AppColor.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search books, authors...',
                        hintStyle: TextStyle(
                          color: AppColor.grey,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Banner Section
          _buildBannerSection(),
          const SizedBox(height: 24),
          
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
                ),
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
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
            child: _categories.isEmpty
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
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColor.primary,
                ),
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
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
            child: books.isEmpty
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
                          coverImage: book.image ?? 'assets/images/book1.jpg',
                          price: book.price,
                          rating: 4.5, // Default rating
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
        image: const DecorationImage(
          image: AssetImage('assets/images/book_banner.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
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
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
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
                    backgroundImage: const AssetImage('assets/images/author.jpg'),
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
                        style: TextStyle(
                          color: AppColor.grey,
                          fontSize: 14,
                        ),
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
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
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

  void _runNetworkDiagnostics() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Running Diagnostics...'),
          content: Container(
            height: 100,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppColor.primary,
                  ),
                  SizedBox(height: 16),
                  Text('Testing connection to server...'),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      // Check server connection
      final result = await _apiService.checkServerConnection();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show results
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Network Diagnostics'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Server: ${AppConfig.apiBaseUrl}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Connection: ${result['isConnected'] ? 'Success ✓' : 'Failed ✗'}',
                  style: TextStyle(
                    color: result['isConnected'] ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (result['statusCode'] != null)
                  Text('Status Code: ${result['statusCode']}'),
                if (result['responseTime'] > 0)
                  Text('Response Time: ${result['responseTime']}ms'),
                if (result['error'] != null) ...[
                  SizedBox(height: 8),
                  Text(
                    'Error Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${result['error']}',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
                SizedBox(height: 16),
                Text(
                  'What does this mean?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                if (result['isConnected'])
                  Text(
                    'The server is reachable, but the API endpoint might be taking too long to respond. Try increasing the timeout setting.',
                  )
                else if (result['error'] != null && result['error'].toString().contains('SocketException'))
                  Text(
                    'The server is not reachable. Check your network connection and server IP address.',
                  )
                else if (result['error'] != null && result['error'].toString().contains('TimeoutException'))
                  Text(
                    'The connection to the server timed out. The server might be overloaded or not responding.',
                  )
                else
                  Text(
                    'There was an error connecting to the server. Check your settings and try again.',
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showServerSettingsDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                ),
                child: Text('Adjust Settings'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Diagnostic failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 