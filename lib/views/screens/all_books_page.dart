import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';
import 'package:flutterbookstore/models/book.dart';
import 'package:flutterbookstore/models/category.dart';
import 'package:flutterbookstore/services/api_service.dart';
import 'package:flutterbookstore/views/widgets/book_card.dart';
import 'package:flutterbookstore/views/widgets/category_card.dart';
import 'package:flutterbookstore/views/screens/book_detail_page.dart';
import 'dart:async';

class AllBooksPage extends StatefulWidget {
  const AllBooksPage({super.key});

  @override
  State<AllBooksPage> createState() => _AllBooksPageState();
}

class _AllBooksPageState extends State<AllBooksPage> {
  final ApiService _apiService = ApiService();
  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  List<BookCategory> _categories = [];
  BookCategory? _selectedCategory;
  bool _isLoading = true;
  bool _isLoadingCategories = true;
  String _errorMessage = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Search suggestions
  List<Book> _searchSuggestions = [];
  bool _isLoadingSuggestions = false;
  bool _showSuggestions = false;
  Timer? _debounceTimer;
  final FocusNode _searchFocusNode = FocusNode();

  bool _isGridView = true; // Toggle between grid and list view

  // Sorting options
  String _sortBy = 'title'; // Default sort field
  String _sortDirection = 'asc'; // Default sort direction

  // Price filter options
  RangeValues _priceRange = const RangeValues(0, 100);
  double _minPrice = 0;
  double _maxPrice = 100;
  bool _isPriceRangeLoaded = false;
  bool _isPriceFilterActive = false;

  // Map for displaying sort options to user
  final Map<String, String> _sortOptions = {
    'title': 'Title',
    'author': 'Author',
    'price': 'Price',
    'date': 'Date Added',
  };

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _fetchCategories();
    _fetchPriceRange();

    // Add listener to focus node to show/hide suggestions
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchPriceRange() async {
    try {
      final priceRange = await _apiService.getBookPriceRange();
      setState(() {
        _minPrice = priceRange['min'] ?? 0;
        _maxPrice = priceRange['max'] ?? 100;
        _priceRange = RangeValues(_minPrice, _maxPrice);
        _isPriceRangeLoaded = true;
      });
    } catch (e) {
      print("Error loading price range: $e");
      // Use default values if there's an error
      setState(() {
        _minPrice = 0;
        _maxPrice = 100;
        _priceRange = const RangeValues(0, 100);
        _isPriceRangeLoaded = true;
      });
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await _apiService.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        print("Error loading categories: $e");
      });
    }
  }

  Future<void> _fetchBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isPriceFilterActive) {
        _books = await _apiService.getSortedBooks(
          sortBy: _sortBy,
          sortDirection: _sortDirection,
          minPrice: _priceRange.start,
          maxPrice: _priceRange.end,
        );
      } else {
        _books = await _apiService.getBooks();
      }
      _filterBooks();

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

  Future<void> _fetchSortedBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      _books = await _apiService.getSortedBooks(
        sortBy: _sortBy,
        sortDirection: _sortDirection,
        categoryId: _selectedCategory?.categoryID,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        minPrice: _isPriceFilterActive ? _priceRange.start : null,
        maxPrice: _isPriceFilterActive ? _priceRange.end : null,
      );
      _filterBooks();

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

  Future<void> _filterBooksByCategory(BookCategory? category) async {
    setState(() {
      _isLoading = true;
      _selectedCategory = category;
    });

    try {
      if (category == null) {
        // If no category selected, show sorted books
        await _fetchSortedBooks();
      } else {
        // Fetch books by category with sorting and price filtering
        _books = await _apiService.getSortedBooksByCategory(
          category.categoryID,
          sortBy: _sortBy,
          sortDirection: _sortDirection,
          minPrice: _isPriceFilterActive ? _priceRange.start : null,
          maxPrice: _isPriceFilterActive ? _priceRange.end : null,
        );
        _filterBooks();
      }

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

  void _filterBooks() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredBooks = _books;
      });
      return;
    }

    setState(() {
      _filteredBooks =
          _books.where((book) {
            final titleMatch = book.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            final authorMatch = book.author.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            return titleMatch || authorMatch;
          }).toList();
    });
  }

  void _searchBooks(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterBooks();

    // Handle search suggestions when user types
    if (query.isNotEmpty) {
      _debounceSearchSuggestions(query);
    } else {
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _debounceSearchSuggestions(String query) {
    // Cancel previous timer if it exists
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    // Set a new timer to delay the API call
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _getSearchSuggestions(query);
    });
  }

  Future<void> _getSearchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
      _showSuggestions = true;
    });

    try {
      // Get all books and filter locally for suggestions
      final allBooks =
          _books.isNotEmpty
              ? _books // Use existing books if already loaded
              : await _apiService.getBooks();

      // Filter for matches in title or author
      final suggestions =
          allBooks.where((book) {
            final titleMatch = book.title.toLowerCase().contains(
              query.toLowerCase(),
            );
            final authorMatch = book.author.toLowerCase().contains(
              query.toLowerCase(),
            );
            return titleMatch || authorMatch;
          }).toList();

      // Limit the number of suggestions
      final limitedSuggestions = suggestions.take(5).toList();

      if (mounted) {
        setState(() {
          _searchSuggestions = limitedSuggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchSuggestions = [];
          _isLoadingSuggestions = false;
        });
      }
      print('Error getting search suggestions: $e');
    }
  }

  void _selectSearchSuggestion(Book book) {
    _searchController.text = book.title;
    setState(() {
      _searchQuery = book.title;
      _showSuggestions = false;
      _searchSuggestions = [];
    });
    _filterBooks();
    _searchFocusNode.unfocus();

    // Navigate to book details
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookDetailPage(book: book)),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Sort Books',
            style: TextStyle(color: AppColor.dark, fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sort by',
                      style: TextStyle(
                        color: AppColor.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._sortOptions.entries.map(
                      (entry) => RadioListTile<String>(
                        title: Text(entry.value),
                        value: entry.key,
                        groupValue: _sortBy,
                        activeColor: AppColor.primary,
                        dense: true,
                        onChanged: (value) {
                          setDialogState(() {
                            _sortBy = value!;
                          });
                        },
                      ),
                    ),
                    Divider(),
                    Text(
                      'Direction',
                      style: TextStyle(
                        color: AppColor.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: Text('Ascending (A-Z, Low to High)'),
                      value: 'asc',
                      groupValue: _sortDirection,
                      activeColor: AppColor.primary,
                      dense: true,
                      onChanged: (value) {
                        setDialogState(() {
                          _sortDirection = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('Descending (Z-A, High to Low)'),
                      value: 'desc',
                      groupValue: _sortDirection,
                      activeColor: AppColor.primary,
                      dense: true,
                      onChanged: (value) {
                        setDialogState(() {
                          _sortDirection = value!;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: AppColor.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchSortedBooks();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Apply', style: TextStyle(color: Colors.white)),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  String _getSortDisplayText() {
    String field = _sortOptions[_sortBy] ?? 'Title';
    String direction = _sortDirection == 'asc' ? '↑' : '↓';
    return '$field $direction';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard and suggestions when tapping outside
        FocusScope.of(context).unfocus();
        setState(() {
          _showSuggestions = false;
        });
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'All Books',
            style: TextStyle(color: AppColor.dark, fontWeight: FontWeight.bold),
          ),
          iconTheme: IconThemeData(color: AppColor.dark),
          actions: [
            // Toggle view button
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list : Icons.grid_view,
                color: AppColor.primary,
              ),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
              tooltip:
                  _isGridView ? 'Switch to List View' : 'Switch to Grid View',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Box
            Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search books, authors...',
                      hintStyle: TextStyle(color: AppColor.grey, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: AppColor.grey),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: Icon(Icons.clear, color: AppColor.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchBooks('');
                                  _searchFocusNode.unfocus();
                                },
                              )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onChanged: _searchBooks,
                    onTap: () {
                      if (_searchController.text.isNotEmpty) {
                        setState(() {
                          _showSuggestions = true;
                        });
                      }
                    },
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      // Hide suggestions when user presses enter/search
                      setState(() {
                        _showSuggestions = false;
                      });
                      _searchFocusNode.unfocus();
                    },
                  ),

                  // Search suggestions
                  if (_showSuggestions &&
                      (_isLoadingSuggestions || _searchSuggestions.isNotEmpty))
                    Container(
                      constraints: BoxConstraints(maxHeight: 300),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        border: Border(
                          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        ),
                      ),
                      child:
                          _isLoadingSuggestions
                              ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColor.primary,
                                    ),
                                  ),
                                ),
                              )
                              : ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: ClampingScrollPhysics(),
                                itemCount: _searchSuggestions.length,
                                itemBuilder: (context, index) {
                                  final suggestion = _searchSuggestions[index];
                                  return ListTile(
                                    title: Text(
                                      suggestion.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      'by ${suggestion.author}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    leading: Container(
                                      width: 40,
                                      height: 60,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: AppColor.primary.withOpacity(
                                          0.1,
                                        ),
                                      ),
                                      child:
                                          suggestion.image != null &&
                                                  suggestion.image!.isNotEmpty
                                              ? Image.network(
                                                suggestion.image!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Icon(
                                                    Icons.book,
                                                    color: AppColor.primary,
                                                  );
                                                },
                                              )
                                              : Icon(
                                                Icons.book,
                                                color: AppColor.primary,
                                              ),
                                    ),
                                    trailing: Text(
                                      '\$${suggestion.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: AppColor.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onTap:
                                        () =>
                                            _selectSearchSuggestion(suggestion),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                  );
                                },
                              ),
                    ),
                ],
              ),
            ),

            // Category filters
            if (_isLoadingCategories)
              SizedBox(
                height: 115,
                child: Center(
                  child: CircularProgressIndicator(color: AppColor.primary),
                ),
              )
            else if (_categories.isNotEmpty)
              SizedBox(
                height: 115,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Add "All" category option
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: SizedBox(
                        width: 110,
                        child: CategoryCard(
                          categoryName: 'All',
                          isSelected: _selectedCategory == null,
                          onTap: () => _filterBooksByCategory(null),
                        ),
                      ),
                    ),
                    ..._categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: SizedBox(
                          width: category.name.length > 8 ? 130 : 110,
                          child: CategoryCard(
                            categoryName: category.name,
                            categoryId: category.categoryID,
                            isSelected:
                                _selectedCategory?.categoryID ==
                                category.categoryID,
                            onTap: () => _filterBooksByCategory(category),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Results count and sort
            if (!_isLoading && _errorMessage.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredBooks.length} ${_filteredBooks.length == 1 ? 'book' : 'books'} found',
                      style: TextStyle(
                        color: AppColor.grey,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            // Filter Section (expanded/collapsed)
            if (!_isLoading && _errorMessage.isEmpty)
              ExpansionTile(
                title: Text(
                  'Filters',
                  style: TextStyle(
                    color: AppColor.dark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                initiallyExpanded: false,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                children: [_buildFilterSection()],
              ),

            // Content
            Expanded(
              child:
                  _errorMessage.isNotEmpty
                      ? _buildErrorWidget()
                      : _isLoading
                      ? _buildLoadingWidget()
                      : _isGridView
                      ? _buildBooksGrid()
                      : _buildBooksList(),
            ),
          ],
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
            ElevatedButton.icon(
              onPressed: _fetchSortedBooks,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchQuery.isEmpty ? Icons.library_books : Icons.search_off,
                size: 80,
                color: AppColor.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? (_selectedCategory == null
                        ? 'No books available'
                        : 'No books in ${_selectedCategory!.name} category')
                    : 'No books found for "$_searchQuery"',
                style: TextStyle(
                  color: AppColor.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _searchBooks('');
                  },
                  icon: Icon(Icons.clear, size: 16),
                  label: Text('Clear Search'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColor.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBooksGrid() {
    if (_filteredBooks.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh:
          _selectedCategory == null
              ? _fetchSortedBooks
              : () => _filterBooksByCategory(_selectedCategory),
      color: AppColor.primary,
      child: GridView.builder(
        controller: _scrollController,
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
            coverImage:
                book.image != null && book.image!.isNotEmpty
                    ? book.image!
                    : null,
            price: book.price,
            rating: 4.5,
            bookData: book,
          );
        },
      ),
    );
  }

  Widget _buildBooksList() {
    if (_filteredBooks.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh:
          _selectedCategory == null
              ? _fetchSortedBooks
              : () => _filterBooksByCategory(_selectedCategory),
      color: AppColor.primary,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _filteredBooks.length,
        separatorBuilder: (context, index) => const Divider(height: 16),
        itemBuilder: (context, index) {
          final book = _filteredBooks[index];
          return _buildBookListItem(book);
        },
      ),
    );
  }

  Widget _buildBookListItem(Book book) {
    // Get category name if available
    String categoryName = 'Unknown Category';
    if (book.category != null && book.category!.containsKey('Name')) {
      categoryName = book.category!['Name'];
    } else {
      // Try to find category from our list
      final category =
          _categories.where((c) => c.categoryID == book.categoryID).toList();
      if (category.isNotEmpty) {
        categoryName = category.first.name;
      } else {
        categoryName = 'Category ${book.categoryID}';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to book details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailPage(book: book),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      book.image != null && book.image!.isNotEmpty
                          ? Image.network(
                            book.image!,
                            width: 80,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderBookCover(book);
                            },
                          )
                          : _buildPlaceholderBookCover(book),
                ),
                const SizedBox(width: 16),
                // Book details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColor.dark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${book.author}',
                        style: TextStyle(fontSize: 14, color: AppColor.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '4.5',
                            style: TextStyle(
                              color: AppColor.dark,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColor.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${book.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build a placeholder book cover
  Widget _buildPlaceholderBookCover(Book book) {
    return Container(
      width: 80,
      height: 110,
      color: AppColor.primary.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, color: AppColor.primary),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              book.title,
              style: TextStyle(fontSize: 10, color: AppColor.dark),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories filter section
            if (_categories.isNotEmpty) _buildCategoriesFilter(),

            // Sorting section
            _buildSortingSection(),

            // Price range filter
            if (_isPriceRangeLoaded) _buildPriceRangeFilter(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Price Range', style: Theme.of(context).textTheme.titleMedium),
            Switch(
              value: _isPriceFilterActive,
              onChanged: (value) {
                setState(() {
                  _isPriceFilterActive = value;
                  if (value) {
                    // Apply price filter
                    _fetchSortedBooks();
                  } else {
                    // Reset price filter
                    _fetchSortedBooks();
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '\$${_priceRange.start.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: RangeSlider(
                values: _priceRange,
                min: _minPrice,
                max: _maxPrice,
                divisions: 100,
                labels: RangeLabels(
                  '\$${_priceRange.start.toStringAsFixed(2)}',
                  '\$${_priceRange.end.toStringAsFixed(2)}',
                ),
                onChanged: (values) {
                  setState(() {
                    _priceRange = values;
                  });
                },
                onChangeEnd: (values) {
                  if (_isPriceFilterActive) {
                    _fetchSortedBooks();
                  }
                },
              ),
            ),
            Text(
              '\$${_priceRange.end.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCategoriesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categories', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add "All" category option
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => _filterBooksByCategory(null),
                  backgroundColor: Colors.white,
                  selectedColor: AppColor.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color:
                        _selectedCategory == null
                            ? AppColor.primary
                            : AppColor.grey,
                    fontWeight:
                        _selectedCategory == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
              ),
              ..._categories.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category.name),
                    selected:
                        _selectedCategory?.categoryID == category.categoryID,
                    onSelected: (_) => _filterBooksByCategory(category),
                    backgroundColor: Colors.white,
                    selectedColor: AppColor.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color:
                          _selectedCategory?.categoryID == category.categoryID
                              ? AppColor.primary
                              : AppColor.grey,
                      fontWeight:
                          _selectedCategory?.categoryID == category.categoryID
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSortingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sort By', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ..._sortOptions.entries.map(
              (entry) => ChoiceChip(
                label: Text(
                  '${entry.value} ${_sortBy == entry.key ? (_sortDirection == 'asc' ? '↑' : '↓') : ''}',
                ),
                selected: _sortBy == entry.key,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      if (_sortBy == entry.key) {
                        // Toggle direction if already selected
                        _sortDirection =
                            _sortDirection == 'asc' ? 'desc' : 'asc';
                      } else {
                        _sortBy = entry.key;
                      }
                      _fetchSortedBooks();
                    });
                  }
                },
                backgroundColor: Colors.white,
                selectedColor: AppColor.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color:
                      _sortBy == entry.key ? AppColor.primary : AppColor.grey,
                  fontWeight:
                      _sortBy == entry.key
                          ? FontWeight.bold
                          : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
