import 'package:flutter/material.dart';
import 'package:flutterbookstore/constant/app_color.dart';
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
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
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

  Widget _buildBody() {
    return ListView(
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
        
        // Flash Sale Section
        _buildFlashSaleSection(),
        const SizedBox(height: 24),
        
        // Categories Section
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
        
        // Category List
        SizedBox(
          height: 105,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                CategoryCard(
                  name: 'Fiction',
                  iconPath: 'assets/icons/fiction.png',
                ),
                SizedBox(width: 16),
                CategoryCard(
                  name: 'Non-Fiction',
                  iconPath: 'assets/icons/non_fiction.png',
                ),
                SizedBox(width: 16),
                CategoryCard(
                  name: 'Science',
                  iconPath: 'assets/icons/science.png',
                ),
                SizedBox(width: 16),
                CategoryCard(
                  name: 'History',
                  iconPath: 'assets/icons/history.png',
                ),
                SizedBox(width: 16),
                CategoryCard(
                  name: 'Biography',
                  iconPath: 'assets/icons/history.png',
                ),
                SizedBox(width: 16),
                CategoryCard(
                  name: 'Fantasy',
                  iconPath: 'assets/icons/history.png',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Best Sellers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Best Sellers',
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
        
        // Best Sellers List
        SizedBox(
          height: 290,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                BookCard(
                  title: 'The Hobbit',
                  author: 'J.R.R. Tolkien',
                  coverImage: 'assets/images/book1.jpg',
                  price: 19.99,
                  rating: 4.8,
                ),
                SizedBox(width: 16),
                BookCard(
                  title: 'To Kill a Mockingbird',
                  author: 'Harper Lee',
                  coverImage: 'assets/images/book2.jpg',
                  price: 14.99,
                  rating: 4.9,
                ),
                SizedBox(width: 16),
                BookCard(
                  title: '1984',
                  author: 'George Orwell',
                  coverImage: 'assets/images/book3.jpg',
                  price: 12.99,
                  rating: 4.7,
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // New Releases
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New Releases',
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
        
        // New Releases List
        SizedBox(
          height: 290,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                BookCard(
                  title: 'Dune',
                  author: 'Frank Herbert',
                  coverImage: 'assets/images/book4.jpg',
                  price: 24.99,
                  rating: 4.6,
                ),
                SizedBox(width: 16),
                BookCard(
                  title: 'The Great Gatsby',
                  author: 'F. Scott Fitzgerald',
                  coverImage: 'assets/images/book5.jpg',
                  price: 15.99,
                  rating: 4.5,
                ),
                SizedBox(width: 16),
                BookCard(
                  title: 'Pride and Prejudice',
                  author: 'Jane Austen',
                  coverImage: 'assets/images/book6.jpg',
                  price: 13.99,
                  rating: 4.8,
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Featured Author Section
        _buildFeaturedAuthorSection(),
        const SizedBox(height: 40),
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

  Widget _buildFlashSaleSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColor.secondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.flash_on,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Flash Sale',
                    style: TextStyle(
                      color: AppColor.dark,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              _buildFlashSaleTimer(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 210,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Discount badge
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Container(
                              height: 140,
                              width: 140,
                              color: AppColor.lightGrey,
                              child: Center(
                                child: Icon(Icons.book, size: 40, color: AppColor.grey),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColor.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '-30%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Flash Sale Book',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '\$9.99',
                                  style: TextStyle(
                                    color: AppColor.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '\$14.99',
                                  style: TextStyle(
                                    color: AppColor.grey,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlashSaleTimer() {
    return Row(
      children: [
        _buildTimeBox('02'),
        const SizedBox(width: 4),
        Text(
          ':',
          style: TextStyle(
            color: AppColor.dark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        _buildTimeBox('45'),
        const SizedBox(width: 4),
        Text(
          ':',
          style: TextStyle(
            color: AppColor.dark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        _buildTimeBox('33'),
      ],
    );
  }

  Widget _buildTimeBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColor.dark,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        time,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
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
} 