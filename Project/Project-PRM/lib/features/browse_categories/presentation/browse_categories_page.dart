import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/category_repository.dart';
import '../models/category.dart';
import '../models/collection.dart';
import '../models/product.dart';
import 'collection_details_page.dart';
import 'discover_products_page.dart';

class BrowseCategoriesPage extends StatefulWidget {
  const BrowseCategoriesPage({required this.repository, super.key});

  final CategoryRepository repository;

  @override
  State<BrowseCategoriesPage> createState() => _BrowseCategoriesPageState();
}

class _BrowseCategoriesPageState extends State<BrowseCategoriesPage> {
  static const _allGendersId = 0;
  static const _womenId = 2;
  static const _menId = 1;

  int _genderId = _allGendersId;
  List<StoreCollection> _collections = [];
  List<ProductCategory> _categories = [];
  List<StoreProduct> _products = [];
  List<StoreProduct> _offers = [];
  final Set<String> _selectedCategoryIds = {};
  int _activeBannerIndex = 0;
  bool _isLoadingCollections = true;
  bool _isLoadingCategories = true;
  bool _isApplyingFilters = false;
  bool _isLoadingOffers = true;
  String? _collectionError;
  String? _categoryError;
  String? _productError;
  String? _offersError;

  @override
  void initState() {
    super.initState();
    _loadCollections();
    _loadCategories();
    _loadProducts();
    _loadOffers();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoadingCollections = true;
      _collectionError = null;
    });

    try {
      final collections = await widget.repository.fetchCollections();
      if (!mounted) return;
      setState(() {
        _collections = collections;
        _isLoadingCollections = false;
      });
    } on DioException catch (error) {
      _setCollectionError(error.message ?? 'Could not connect to the store.');
    } on FormatException catch (error) {
      _setCollectionError(error.message);
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final categories = await widget.repository.fetchCategories(
        genderId: _genderId,
      );
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } on DioException catch (error) {
      _setCategoryError(error.message ?? 'Could not connect to the store.');
    } on FormatException catch (error) {
      _setCategoryError(error.message);
    }
  }

  Future<void> _loadProducts({String? categoryIds}) async {
    setState(() {
      _isApplyingFilters = true;
      _productError = null;
    });

    try {
      final products = await widget.repository.fetchProducts(
        categoryIds: categoryIds,
      );
      if (!mounted) return;
      setState(() {
        _products = products;
        _isApplyingFilters = false;
      });
    } on DioException catch (error) {
      _setProductError(error.message ?? 'Could not connect to the store.');
    } on FormatException catch (error) {
      _setProductError(error.message);
    }
  }

  Future<void> _loadOffers({String? categoryIds}) async {
    setState(() {
      _isLoadingOffers = true;
      _offersError = null;
    });

    try {
      final offers = await widget.repository.fetchOffers(
        categoryIds: categoryIds,
      );
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _isLoadingOffers = false;
      });
    } on DioException catch (error) {
      _setOffersError(error.message ?? 'Could not connect to the store.');
    } on FormatException catch (error) {
      _setOffersError(error.message);
    }
  }

  void _setCollectionError(String message) {
    if (!mounted) return;
    setState(() {
      _collectionError = message;
      _isLoadingCollections = false;
    });
  }

  void _setCategoryError(String message) {
    if (!mounted) return;
    setState(() {
      _categoryError = message;
      _isLoadingCategories = false;
    });
  }

  void _setProductError(String message) {
    if (!mounted) return;
    setState(() {
      _productError = message;
      _isApplyingFilters = false;
    });
  }

  void _setOffersError(String message) {
    if (!mounted) return;
    setState(() {
      _offersError = message;
      _isLoadingOffers = false;
    });
  }

  void _selectGender(int genderId) {
    if (_genderId == genderId) return;
    setState(() {
      _genderId = genderId;
      _selectedCategoryIds.clear();
    });
    _loadCategories();
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (!_selectedCategoryIds.add(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      }
    });
  }

  Future<void> _applyFilters() async {
    final categoryIds = _selectedCategoryIds.join(',');
    await Future.wait([
      _loadProducts(categoryIds: categoryIds),
      _loadOffers(categoryIds: categoryIds),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('eFashion'),
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final categoryIds = _selectedCategoryIds.isEmpty
              ? null
              : _selectedCategoryIds.join(',');
          await Future.wait([
            _loadCollections(),
            _loadCategories(),
            _loadProducts(categoryIds: categoryIds),
            _loadOffers(categoryIds: categoryIds),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _buildCollectionCarousel(theme),
            const SizedBox(height: 22),
            Text(
              'Browse Product Categories',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a category to find something you love.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _buildGenderSelector(theme),
            const SizedBox(height: 22),
            Row(
              children: [
                Text(
                  'Categories',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_selectedCategoryIds.isNotEmpty)
                  Text(
                    '${_selectedCategoryIds.length} selected',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCategories(theme),
            const SizedBox(height: 28),
            _buildOffersCarousel(theme),
            const SizedBox(height: 28),
            Row(
              children: [
                Text(
                  _selectedCategoryIds.isEmpty
                      ? 'Products'
                      : 'Filtered products',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _openDiscoverProducts(
                    title: 'Discover Products',
                    offersOnly: false,
                  ),
                  child: const Text('See all'),
                ),
                if (_isApplyingFilters)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProducts(theme),
          ],
        ),
      ),
      bottomNavigationBar: _selectedCategoryIds.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: FilledButton.icon(
                onPressed: _isApplyingFilters ? null : _applyFilters,
                icon: const Icon(Icons.filter_alt_outlined),
                label: Text(
                  'Apply ${_selectedCategoryIds.length} '
                  '${_selectedCategoryIds.length == 1 ? 'category' : 'categories'}',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
    );
  }

  Widget _buildGenderSelector(ThemeData theme) {
    return Wrap(
      spacing: 10,
      children: [
        _GenderChip(
          label: 'All',
          icon: Icons.grid_view_rounded,
          selected: _genderId == _allGendersId,
          onTap: () => _selectGender(_allGendersId),
        ),
        _GenderChip(
          label: 'Women',
          icon: Icons.woman_rounded,
          selected: _genderId == _womenId,
          onTap: () => _selectGender(_womenId),
        ),
        _GenderChip(
          label: 'Men',
          icon: Icons.man_rounded,
          selected: _genderId == _menId,
          onTap: () => _selectGender(_menId),
        ),
      ],
    );
  }

  Widget _buildCollectionCarousel(ThemeData theme) {
    if (_isLoadingCollections) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_collectionError != null) {
      return _ErrorMessage(
        message: _collectionError!,
        onRetry: _loadCollections,
      );
    }
    if (_collections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: CarouselSlider.builder(
            itemCount: _collections.length,
            itemBuilder: (context, index, realIndex) {
              final collection = _collections[index];
              return _CollectionBanner(
                collection: collection,
                onTap: () => _showCollectionDetails(collection),
              );
            },
            options: CarouselOptions(
              height: 300,
              viewportFraction: 1,
              autoPlay: _collections.length > 1,
              autoPlayInterval: const Duration(seconds: 5),
              onPageChanged: (index, reason) {
                setState(() => _activeBannerIndex = index);
              },
            ),
          ),
        ),
        if (_collections.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _collections.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == _activeBannerIndex ? 24 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: index == _activeBannerIndex
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOffersCarousel(ThemeData theme) {
    if (_isLoadingOffers && _offers.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_offersError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Offers',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          _ErrorMessage(
            message: _offersError!,
            onRetry: () => _loadOffers(
              categoryIds: _selectedCategoryIds.isEmpty
                  ? null
                  : _selectedCategoryIds.join(','),
            ),
          ),
        ],
      );
    }
    if (_offers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Offers',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _openDiscoverProducts(
                title: 'Discover Offers',
                offersOnly: true,
              ),
              child: const Text('See all'),
            ),
            if (_isLoadingOffers)
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 238,
          child: CarouselSlider.builder(
            itemCount: _offers.length,
            itemBuilder: (context, index, realIndex) =>
                _OfferCard(product: _offers[index]),
            options: CarouselOptions(
              height: 238,
              viewportFraction: 0.62,
              enlargeCenterPage: true,
              enableInfiniteScroll: _offers.length > 1,
            ),
          ),
        ),
      ],
    );
  }

  void _showCollectionDetails(StoreCollection collection) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CollectionDetailsPage(
          repository: widget.repository,
          collection: collection,
        ),
      ),
    );
  }

  void _openDiscoverProducts({
    required String title,
    required bool offersOnly,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DiscoverProductsPage(
          repository: widget.repository,
          title: title,
          categoryIds: _selectedCategoryIds.isEmpty
              ? null
              : _selectedCategoryIds.join(','),
          offersOnly: offersOnly,
        ),
      ),
    );
  }

  Widget _buildCategories(ThemeData theme) {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 132,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_categoryError != null) {
      return _ErrorMessage(message: _categoryError!, onRetry: _loadCategories);
    }
    if (_categories.isEmpty) {
      return const _EmptyMessage(message: 'No categories found.');
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategoryIds.contains(category.id);
          return _CategoryCard(
            category: category,
            selected: isSelected,
            onTap: () => _toggleCategory(category.id),
          );
        },
      ),
    );
  }

  Widget _buildProducts(ThemeData theme) {
    if (_productError != null) {
      return _ErrorMessage(
        message: _productError!,
        onRetry: () => _loadProducts(
          categoryIds: _selectedCategoryIds.isEmpty
              ? null
              : _selectedCategoryIds.join(','),
        ),
      );
    }
    if (_isApplyingFilters && _products.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_products.isEmpty) {
      return const _EmptyMessage(
        message: 'No products found for this selection.',
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.67,
      ),
      itemBuilder: (context, index) => _ProductCard(product: _products[index]),
    );
  }
}

class _CollectionBanner extends StatelessWidget {
  const _CollectionBanner({
    required this.collection,
    required this.onTap,
  });

  final StoreCollection collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: collection.imageUrl,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.image_not_supported_outlined, size: 42),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xCC101820), Color(0x00101820)],
                stops: [0, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${collection.discount}% OFF',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  collection.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  collection.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Shop collection'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
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

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.product});

  final StoreProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = product.oldPrice != product.price;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'SALE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (hasDiscount) ...[
                      Text(
                        '\$${product.oldPrice}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.error,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 7),
                    ],
                    Text(
                      '\$${product.price}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
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
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: Theme.of(context).colorScheme.primary,
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ProductCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 104,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox.expand(
                        child: CachedNetworkImage(
                          imageUrl: category.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => ColoredBox(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.checkroom_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (selected)
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final StoreProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox.expand(
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.price,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
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

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(child: Text(message)),
    );
  }
}
