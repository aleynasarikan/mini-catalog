import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MiniCatalogApp());
}

class MiniCatalogApp extends StatelessWidget {
  const MiniCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GIPHTO',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
                  ),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 92,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'GIPHTO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Gifts for every occasion',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const productsUrl = 'https://wantapi.com/products.php';
  static const localDataAsset = 'temp_api.json';

  int selectedIndex = 0;
  List<Product> products = [];
  List<CategoryData> categories = [];
  final List<CartItem> cartItems = [];
  final Set<int> favoriteIds = {};
  bool loading = true;
  String? error;
  String searchQuery = '';
  String selectedCategory = 'All';
  String profileName = 'Andrew';
  String profilePhotoUrl = 'https://i.pravatar.cc/150?img=12';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http
          .get(Uri.parse(productsUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        var items = <dynamic>[];

        if (data is Map && data['data'] is List) {
          items = data['data'];
        } else if (data is List) {
          items = data;
        } else if (data is Map && data['products'] is List) {
          items = data['products'];
        }

        final parsed = items
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();
        final finalProducts = parsed.isNotEmpty ? parsed : sampleProducts;
        setState(() {
          products = finalProducts;
          categories = _buildCategoryData(finalProducts);
          if (selectedCategory != 'All' &&
              !categories.any(
                (category) => category.title == selectedCategory,
              )) {
            selectedCategory = 'All';
          }
          loading = false;
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (errorValue) {
      final fallbackProducts = await _loadLocalProducts();
      setState(() {
        error = 'Veri alınamadı: $errorValue';
        products = fallbackProducts.isNotEmpty
            ? fallbackProducts
            : sampleProducts;
        categories = _buildCategoryData(products);
        loading = false;
      });
    }
  }

  Future<List<Product>> _loadLocalProducts() async {
    try {
      final jsonString = await rootBundle.loadString(localDataAsset);
      final data = json.decode(jsonString);
      var items = <dynamic>[];

      if (data is Map && data['data'] is List) {
        items = data['data'];
      } else if (data is List) {
        items = data;
      } else if (data is Map && data['products'] is List) {
        items = data['products'];
      }

      return items
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _addToCart(Product product) {
    final existing = cartItems
        .where((item) => item.product.id == product.id)
        .toList();
    if (existing.isNotEmpty) {
      setState(() {
        existing.first.quantity++;
      });
    } else {
      setState(() {
        cartItems.add(CartItem(product: product));
      });
    }
  }

  void _removeFromCart(Product product) {
    setState(() {
      cartItems.removeWhere((item) => item.product.id == product.id);
    });
  }

  void _toggleFavorite(Product product) {
    setState(() {
      if (favoriteIds.contains(product.id)) {
        favoriteIds.remove(product.id);
      } else {
        favoriteIds.add(product.id);
      }
    });
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: product,
          onAddToCart: () => _addToCart(product),
          isFavorite: favoriteIds.contains(product.id),
          onToggleFavorite: () => _toggleFavorite(product),
          onViewCart: () {
            Navigator.of(context).pop();
            setState(() => selectedIndex = 2);
          },
        ),
      ),
    );
  }

  bool _matchesCategory(Product product) {
    if (selectedCategory == 'All') return true;
    final categoryValue =
        (product.category.isNotEmpty
                ? product.category
                : inferCategoryFromName(product.name))
            .toLowerCase();
    final selected = selectedCategory.toLowerCase();
    return categoryValue == selected ||
        product.name.toLowerCase().contains(selected) ||
        product.tagline.toLowerCase().contains(selected) ||
        categoryValue.contains(selected);
  }

  List<CategoryData> _buildCategoryData(List<Product> products) {
    final grouped = <String, List<Product>>{};
    for (final product in products) {
      final category = product.category.isNotEmpty
          ? product.category
          : inferCategoryFromName(product.name);
      grouped.putIfAbsent(category, () => []).add(product);
    }

    return grouped.entries.map((entry) {
      final title = entry.key;
      final sampleProduct = entry.value.first;
      final defaultInfo = categoryInfo[title];
      return CategoryData(
        title: title,
        subtitle: defaultInfo?.subtitle ?? 'Explore the best $title products',
        imageUrl: sampleProduct.imageUrl,
        color: defaultInfo?.color ?? Colors.indigo,
        icon: defaultInfo?.icon ?? Icons.category,
      );
    }).toList();
  }

  List<Product> get _filteredProducts {
    final query = searchQuery.toLowerCase();
    return products.where((product) {
      if (!_matchesCategory(product)) return false;
      if (searchQuery.isEmpty) return true;
      return product.name.toLowerCase().contains(query) ||
          product.tagline.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final pages = [
      HomeTab(
        products: _filteredProducts,
        loading: loading,
        error: error,
        searchQuery: searchQuery,
        selectedCategory: selectedCategory,
        profileName: profileName,
        favoriteIds: favoriteIds,
        categories: categories,
        onSearchChanged: (value) => setState(() => searchQuery = value),
        onCategorySelected: (category) =>
            setState(() => selectedCategory = category),
        onProductTap: _openProduct,
        onAddToCart: _addToCart,
        onToggleFavorite: _toggleFavorite,
        cartCount: cartCount,
      ),
      CategoriesTab(
        categories: categories,
        onCategoryTap: (category) {
          setState(() {
            selectedCategory = category;
            selectedIndex = 0;
            searchQuery = '';
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$category seçildi')));
        },
      ),
      CartContent(
        cartItems: cartItems,
        onRemove: _removeFromCart,
        onCheckout: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Checkout işlemi tamamlandı')),
          );
        },
      ),
      WishlistTab(
        favoriteProducts: products
            .where((p) => favoriteIds.contains(p.id))
            .toList(),
        onProductTap: _openProduct,
        onToggleFavorite: _toggleFavorite,
      ),
      ProfileTab(
        name: profileName,
        photoUrl: profilePhotoUrl,
        onNameChanged: (value) => setState(() => profileName = value),
        onPhotoUrlChanged: (value) => setState(() => profilePhotoUrl = value),
      ),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: Colors.indigo.shade700,
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => selectedIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_bag_outlined),
                if (cartCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        cartCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'My Bag',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Wishlist',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  final List<Product> products;
  final bool loading;
  final String? error;
  final String searchQuery;
  final String selectedCategory;
  final String profileName;
  final Set<int> favoriteIds;
  final List<CategoryData> categories;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategorySelected;
  final void Function(Product) onProductTap;
  final void Function(Product) onAddToCart;
  final void Function(Product) onToggleFavorite;
  final int cartCount;

  const HomeTab({
    super.key,
    required this.products,
    required this.loading,
    required this.error,
    required this.searchQuery,
    required this.selectedCategory,
    required this.profileName,
    required this.favoriteIds,
    required this.categories,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.onProductTap,
    required this.onAddToCart,
    required this.onToggleFavorite,
    required this.cartCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroProduct = products.isNotEmpty
        ? products.first
        : sampleProducts.first;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${profileName.isNotEmpty ? profileName.split(' ').first : 'Friend'}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find the perfect gift today',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEDEDF7),
                      ),
                      child: const Icon(Icons.person, color: Colors.indigo),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search gifts',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final category = isAll ? null : categories[index - 1];
                      final title = isAll ? 'All' : category!.title;
                      final selected = selectedCategory == title;
                      return ChoiceChip(
                        label: Text(title),
                        selected: selected,
                        onSelected: (_) => onCategorySelected(title),
                        selectedColor: Colors.indigo.shade100,
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.indigo.shade900
                              : Colors.grey.shade800,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.indigo.shade900,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Make their day',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Memorable gifts delivered in time.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton(
                                onPressed: () => onProductTap(heroProduct),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.indigo.shade900,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('Send gift'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        child: SizedBox(
                          width: 140,
                          height: 180,
                          child: Image.network(
                            heroProduct.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: Colors.grey.shade200),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trending Products',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'See all',
                      style: TextStyle(color: Colors.indigo),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          if (loading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: Colors.indigo.shade700),
              ),
            )
          else if (error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            )
          else if (products.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No products found.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 700
                      ? 3
                      : 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    onTap: () => onProductTap(product),
                    onAddToCart: () => onAddToCart(product),
                    onToggleFavorite: () => onToggleFavorite(product),
                    isFavorite: favoriteIds.contains(product.id),
                  );
                }, childCount: products.length),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}

class CategoryData {
  final String title;
  final String subtitle;
  final String imageUrl;
  final Color color;
  final IconData icon;

  const CategoryData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.color,
    required this.icon,
  });
}

const Map<String, CategoryData> categoryInfo = {
  'Phones': CategoryData(
    title: 'Phones',
    subtitle: 'Shop the latest smartphones',
    imageUrl: 'https://wantapi.com/assets/images/iphone.png',
    color: Colors.blue,
    icon: Icons.phone_iphone,
  ),
  'Laptops': CategoryData(
    title: 'Laptops',
    subtitle: 'Powerful notebooks for every workflow',
    imageUrl: 'https://wantapi.com/assets/images/macbook.png',
    color: Colors.deepPurple,
    icon: Icons.laptop_mac,
  ),
  'Tablets': CategoryData(
    title: 'Tablets',
    subtitle: 'Portable screens for work and play',
    imageUrl: 'https://wantapi.com/assets/images/ipad.png',
    color: Colors.teal,
    icon: Icons.tablet_mac,
  ),
  'Wearables': CategoryData(
    title: 'Wearables',
    subtitle: 'Smart watches and modern accessories',
    imageUrl: 'https://wantapi.com/assets/images/watch.png',
    color: Colors.indigo,
    icon: Icons.watch,
  ),
  'Audio': CategoryData(
    title: 'Audio',
    subtitle: 'Headphones and home audio gear',
    imageUrl: 'https://wantapi.com/assets/images/airpods.png',
    color: Colors.orange,
    icon: Icons.headphones,
  ),
  'Desktops': CategoryData(
    title: 'Desktops',
    subtitle: 'Desktops and powerful workstations',
    imageUrl: 'https://wantapi.com/assets/images/imac.png',
    color: Colors.green,
    icon: Icons.desktop_windows,
  ),
  'Other': CategoryData(
    title: 'Other',
    subtitle: 'Discover the rest of our catalog',
    imageUrl: 'https://wantapi.com/assets/images/visionpro.png',
    color: Colors.grey,
    icon: Icons.category,
  ),
};

class CategoriesTab extends StatelessWidget {
  final List<CategoryData> categories;
  final ValueChanged<String> onCategoryTap;

  const CategoriesTab({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('Categories'), elevation: 0),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () => onCategoryTap(category.title),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                image: DecorationImage(
                  image: NetworkImage(category.imageUrl),
                  fit: BoxFit.cover,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.08),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(0, 0, 0, 0.55),
                      Color.fromRGBO(0, 0, 0, 0.12),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      category.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class WishlistTab extends StatelessWidget {
  final List<Product> favoriteProducts;
  final void Function(Product) onProductTap;
  final void Function(Product) onToggleFavorite;

  const WishlistTab({
    super.key,
    required this.favoriteProducts,
    required this.onProductTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('Wishlist'), elevation: 0),
      body: favoriteProducts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.favorite_border, size: 84, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      'Your wishlist is empty',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Tap the heart icon on any product to add it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: favoriteProducts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final product = favoriteProducts[index];
                return ListTile(
                  onTap: () => onProductTap(product),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      product.imageUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey.shade200),
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    product.priceLabel,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: IconButton(
                    onPressed: () => onToggleFavorite(product),
                    icon: const Icon(Icons.favorite, color: Colors.redAccent),
                  ),
                );
              },
            ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  final String name;
  final String photoUrl;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onPhotoUrlChanged;

  const ProfileTab({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.onNameChanged,
    required this.onPhotoUrlChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = name.isNotEmpty
        ? name
              .trim()
              .split(' ')
              .map((part) => part.isNotEmpty ? part[0] : '')
              .take(2)
              .join()
        : 'U';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('Profile'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo,
                ),
                clipBehavior: Clip.hardEdge,
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Premium member',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: name,
            onChanged: onNameChanged,
            decoration: InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: photoUrl,
            onChanged: onPhotoUrlChanged,
            decoration: InputDecoration(
              labelText: 'Profile photo URL',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.payment_outlined),
            title: const Text('Payment methods'),
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Shipping address'),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help center'),
          ),
          const SizedBox(height: 24),
          Text(
            'Member perks',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enjoy 10% off your next order and free shipping for premium members.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class CartContent extends StatelessWidget {
  final List<CartItem> cartItems;
  final void Function(Product product) onRemove;
  final VoidCallback onCheckout;

  const CartContent({
    super.key,
    required this.cartItems,
    required this.onRemove,
    required this.onCheckout,
  });

  String get _currency {
    if (cartItems.isNotEmpty && cartItems.first.product.currency.isNotEmpty) {
      return '${cartItems.first.product.currency} ';
    }
    return '';
  }

  double get totalPrice => cartItems.fold(0, (sum, item) => sum + item.total);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Bag')),
      body: cartItems.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 84,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Add items to start shopping.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: cartItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            const BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.04),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              item.product.imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: Colors.grey.shade200),
                            ),
                          ),
                          title: Text(
                            item.product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.product.priceLabel}  •  Qty ${item.quantity}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: IconButton(
                            onPressed: () => onRemove(item.product),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$_currency${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: onCheckout,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Checkout',
                            style: TextStyle(fontSize: 16),
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
}

class Product {
  final int id;
  final String name;
  final String tagline;
  final String description;
  final double price;
  final String priceLabel;
  final String currency;
  final String imageUrl;
  final String category;
  final Map<String, String> specs;

  const Product({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.price,
    required this.priceLabel,
    required this.currency,
    required this.imageUrl,
    this.category = '',
    required this.specs,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['product_id'] ?? json['ID'];
    final name = json['name'] ?? json['title'] ?? json['product_name'];
    final tagline = json['tagline']?.toString() ?? '';
    final description = json['description']?.toString() ?? '';
    final priceRaw =
        json['price'] ?? json['amount'] ?? json['sale_price'] ?? '';
    final priceLabel = priceRaw.toString();
    final sanitized = priceLabel.replaceAll(RegExp(r'[^0-9\.]'), '');
    final priceValue = double.tryParse(sanitized) ?? 0.0;
    final currency = json['currency']?.toString() ?? '';

    String imageUrl = '';
    final images =
        json['image'] ??
        json['image_url'] ??
        json['images'] ??
        json['imageLink'];
    if (images is String) {
      imageUrl = images;
    } else if (images is List && images.isNotEmpty) {
      imageUrl = images.first.toString();
    } else if (json['image_link'] != null) {
      imageUrl = json['image_link'].toString();
    }

    final specs = <String, String>{};
    if (json['specs'] is Map) {
      for (final entry in (json['specs'] as Map).entries) {
        specs[entry.key.toString()] = entry.value.toString();
      }
    }

    final category =
        json['category'] ??
        json['categories'] ??
        json['type'] ??
        json['cat'] ??
        '';
    final rawCategory = category?.toString();
    final inferredCategory = rawCategory != null && rawCategory.isNotEmpty
        ? rawCategory
        : inferCategoryFromName(name?.toString() ?? '');

    return Product(
      id: int.tryParse(id?.toString() ?? '') ?? 0,
      name: name?.toString() ?? 'Unknown',
      tagline: tagline,
      description: description,
      price: priceValue,
      priceLabel: priceLabel.isNotEmpty
          ? priceLabel
          : priceValue.toStringAsFixed(0),
      currency: currency,
      imageUrl: imageUrl,
      category: inferredCategory,
      specs: specs,
    );
  }
}

String inferCategoryFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('iphone') || lower.contains('phone')) return 'Phones';
  if (lower.contains('macbook') || lower.contains('laptop')) return 'Laptops';
  if (lower.contains('ipad') || lower.contains('tablet')) return 'Tablets';
  if (lower.contains('watch') || lower.contains('vision')) return 'Wearables';
  if (lower.contains('airpods') ||
      lower.contains('homepod') ||
      lower.contains('headphones')) {
    return 'Audio';
  }
  if (lower.contains('imac') || lower.contains('desktop')) {
    return 'Desktops';
  }
  return 'Other';
}

const List<Product> sampleProducts = [
  Product(
    id: 101,
    name: 'Sample Phone',
    tagline: 'Light, fast and modern.',
    description:
        'A modern phone with premium features and long-lasting battery.',
    price: 699,
    priceLabel: '599',
    currency: 'USD',
    imageUrl: 'https://picsum.photos/seed/101/600/400',
    specs: {'chip': 'A15', 'display': '6.1"', 'battery': '24h'},
  ),
  Product(
    id: 102,
    name: 'Sample Laptop',
    tagline: 'Power for creators.',
    description:
        'A high-performance laptop for both work and creative workflows.',
    price: 1599,
    priceLabel: '259',
    currency: 'USD',
    imageUrl: 'https://picsum.photos/seed/102/600/400',
    specs: {'chip': 'M2', 'display': '14"', 'weight': '3.5 lbs'},
  ),
  Product(
    id: 103,
    name: 'Sample Headphones',
    tagline: 'Noise cancellation that works.',
    description:
        'Premium sound quality with adaptive noise cancellation for every environment.',
    price: 299,
    priceLabel: '299',
    currency: 'USD',
    imageUrl: 'https://picsum.photos/seed/103/600/400',
    specs: {'audio': 'Spatial', 'battery': '30h', 'case': 'Wireless'},
  ),
];

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

class CatalogListPage extends StatefulWidget {
  const CatalogListPage({super.key});

  @override
  State<CatalogListPage> createState() => _CatalogListPageState();
}

class _CatalogListPageState extends State<CatalogListPage> {
  static const bannerUrl = 'https://wantapi.com/assets/banner.png';
  static const productsUrl = 'https://wantapi.com/products.php';

  List<Product> products = [];
  final List<CartItem> cartItems = [];
  final Set<int> favoriteIds = {};
  bool loading = true;
  String? error;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http
          .get(Uri.parse(productsUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        var items = <dynamic>[];

        if (data is Map && data['data'] is List) {
          items = data['data'];
        } else if (data is List) {
          items = data;
        } else if (data is Map && data['products'] is List) {
          items = data['products'];
        }

        final parsed = items
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();
        setState(() {
          products = parsed.isNotEmpty ? parsed : sampleProducts;
          loading = false;
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (errorValue) {
      setState(() {
        error = 'Veri alınamadı: $errorValue';
        products = sampleProducts;
        loading = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    if (searchQuery.isEmpty) {
      return products;
    }
    final query = searchQuery.toLowerCase();
    return products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.tagline.toLowerCase().contains(query);
    }).toList();
  }

  void _addToCart(Product product) {
    final existing = cartItems
        .where((item) => item.product.id == product.id)
        .toList();
    if (existing.isNotEmpty) {
      setState(() {
        existing.first.quantity++;
      });
    } else {
      setState(() {
        cartItems.add(CartItem(product: product));
      });
    }
  }

  void _removeFromCart(Product product) {
    setState(() {
      cartItems.removeWhere((item) => item.product.id == product.id);
    });
  }

  void _toggleFavorite(Product product) {
    setState(() {
      if (favoriteIds.contains(product.id)) {
        favoriteIds.remove(product.id);
      } else {
        favoriteIds.add(product.id);
      }
    });
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CartPage(
          cartItems: cartItems,
          onRemove: _removeFromCart,
          onCheckout: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Checkout işlemi tamamlandı')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _openCart,
            icon: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.shopping_bag_outlined),
                if (cartCount > 0)
                  Positioned(
                    right: 0,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        cartCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find your perfect device.',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search products',
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      bannerUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey.shade200, height: 160),
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchProducts,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_filteredProducts.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No products found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900
                        ? 3
                        : constraints.maxWidth > 640
                        ? 2
                        : 1;
                    final aspectRatio = crossAxisCount == 1
                        ? 1.15
                        : crossAxisCount == 2
                        ? 0.85
                        : 0.75;
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return ProductCard(
                          product: product,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailPage(
                                product: product,
                                onAddToCart: () => _addToCart(product),
                                onToggleFavorite: () =>
                                    _toggleFavorite(product),
                                isFavorite: favoriteIds.contains(product.id),
                                onViewCart: () {
                                  Navigator.of(context).pop();
                                  _openCart();
                                },
                              ),
                            ),
                          ),
                          onAddToCart: () => _addToCart(product),
                          onToggleFavorite: () => _toggleFavorite(product),
                          isFavorite: favoriteIds.contains(product.id),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleFavorite;
  final bool isFavorite;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
    required this.onToggleFavorite,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            const BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.08),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      onToggleFavorite();
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white.withAlpha(
                        (0.92 * 255).round(),
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? Colors.redAccent
                            : Colors.grey.shade700,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Flexible(
              fit: FlexFit.loose,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            product.priceLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade600,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleFavorite;
  final bool isFavorite;
  final VoidCallback onViewCart;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.onToggleFavorite,
    required this.isFavorite,
    required this.onViewCart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
            onPressed: onToggleFavorite,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : Colors.white,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey.shade200),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.tagline,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    product.priceLabel,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Product details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isNotEmpty
                        ? product.description
                        : 'No description available.',
                    style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: product.specs.entries.map((entry) {
                      return Chip(
                        label: Text('${entry.key}: ${entry.value}'),
                        backgroundColor: Colors.grey.shade100,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        onAddToCart();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            backgroundColor: Colors.indigo.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            content: Row(
                              children: const [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 12),
                                Expanded(child: Text('Sepete eklendi!')),
                              ],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.add_shopping_cart, size: 20),
                      label: const Text(
                        'Sepete Ekle',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: onViewCart,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                      label: const Text(
                        'Sepeti Görüntüle',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartPage extends StatelessWidget {
  final List<CartItem> cartItems;
  final void Function(Product product) onRemove;
  final VoidCallback onCheckout;

  const CartPage({
    super.key,
    required this.cartItems,
    required this.onRemove,
    required this.onCheckout,
  });

  String get _currency {
    if (cartItems.isNotEmpty && cartItems.first.product.currency.isNotEmpty) {
      return '${cartItems.first.product.currency} ';
    }
    return '';
  }

  double get totalPrice => cartItems.fold(0, (sum, item) => sum + item.total);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cartItems.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      size: 84,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add items to start shopping.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: cartItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            const BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.04),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              item.product.imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: Colors.grey.shade200),
                            ),
                          ),
                          title: Text(
                            item.product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.product.priceLabel}  •  Qty ${item.quantity}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: IconButton(
                            onPressed: () => onRemove(item.product),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$_currency${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: onCheckout,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Checkout',
                            style: TextStyle(fontSize: 16),
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
}
