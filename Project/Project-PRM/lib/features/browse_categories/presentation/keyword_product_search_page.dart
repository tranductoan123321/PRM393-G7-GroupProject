import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/category_repository.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/product.dart';

class KeywordProductSearchPage extends StatefulWidget {
  const KeywordProductSearchPage({required this.repository, super.key});

  final CategoryRepository repository;

  @override
  State<KeywordProductSearchPage> createState() =>
      _KeywordProductSearchPageState();
}

class _KeywordProductSearchPageState extends State<KeywordProductSearchPage> {
  static const _pageSize = 20;

  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<StoreProduct> _products = [];

  Timer? _debounce;
  List<ProductCategory> _categories = [];
  List<ProductBrand> _brands = [];
  Set<String> _selectedCategories = {};
  Set<String> _selectedBrands = {};
  int _minPrice = 0;
  int _maxPrice = 800;
  int _requestVersion = 0;
  int _page = 1;
  bool _isLoading = false;
  bool _isDebouncing = false;
  bool _hasReachedEnd = false;
  bool _isGridView = false;
  bool _isLoadingFilters = true;
  String? _errorMessage;
  String? _filtersError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final categoriesFuture = widget.repository.fetchCategories(genderId: 0);
      final brandsFuture = widget.repository.fetchBrands();
      await Future.wait([categoriesFuture, brandsFuture]);
      final categories = await categoriesFuture;
      final brands = await brandsFuture;
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _brands = brands;
        _isLoadingFilters = false;
      });
    } on DioException catch (error) {
      _setFilterError(error.message ?? 'Could not connect to the store.');
    } on FormatException catch (error) {
      _setFilterError(error.message);
    }
  }

  void _setFilterError(String message) {
    if (!mounted) return;
    setState(() {
      _filtersError = message;
      _isLoadingFilters = false;
    });
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    final version = ++_requestVersion;
    _isLoading = false;
    _isDebouncing = false;

    if (query.isEmpty) {
      setState(() {
        _products.clear();
        _page = 1;
        _hasReachedEnd = false;
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _products.clear();
      _page = 1;
      _hasReachedEnd = false;
      _errorMessage = null;
      _isDebouncing = true;
    });
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || version != _requestVersion) return;
      setState(() => _isDebouncing = false);
      _loadPage(version: version, reset: true);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || _hasReachedEnd) return;
    if (_scrollController.position.extentAfter < 400) {
      _loadPage(version: _requestVersion);
    }
  }

  Future<void> _loadPage({required int version, bool reset = false}) async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _isLoading || (_hasReachedEnd && !reset)) return;

    setState(() {
      _isDebouncing = false;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await widget.repository.searchProducts(
        query: query,
        page: reset ? 1 : _page,
        categoryIds: _selectedCategories.isEmpty
            ? null
            : _selectedCategories.join(','),
        brandIds: _selectedBrands.isEmpty ? null : _selectedBrands.join(','),
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
      if (!mounted || version != _requestVersion) return;
      setState(() {
        if (reset) _products.clear();
        _products.addAll(results);
        _page = (reset ? 1 : _page) + 1;
        _hasReachedEnd = results.length < _pageSize;
        _isLoading = false;
      });
    } on DioException catch (error) {
      _setSearchError(
        version,
        error.message ?? 'Could not connect to the store.',
      );
    } on FormatException catch (error) {
      _setSearchError(version, error.message);
    }
  }

  void _setSearchError(int version, String message) {
    if (!mounted || version != _requestVersion) return;
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    if (_queryController.text.trim().isEmpty) return;
    _debounce?.cancel();
    final version = ++_requestVersion;
    setState(() {
      _products.clear();
      _page = 1;
      _hasReachedEnd = false;
      _errorMessage = null;
      _isLoading = false;
      _isDebouncing = false;
    });
    await _loadPage(version: version, reset: true);
  }

  Future<void> _showFilters() async {
    if (_isLoadingFilters) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading search filters. Try again shortly.'),
        ),
      );
      return;
    }
    if (_filtersError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_filtersError!),
          action: SnackBarAction(label: 'Retry', onPressed: _loadFilterOptions),
        ),
      );
      return;
    }

    final filters = await showModalBottomSheet<_SearchFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SearchFilterSheet(
        categories: _categories,
        brands: _brands,
        selectedCategories: _selectedCategories,
        selectedBrands: _selectedBrands,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      ),
    );
    if (!mounted || filters == null) return;
    _debounce?.cancel();

    setState(() {
      _selectedCategories = filters.categories;
      _selectedBrands = filters.brands;
      _minPrice = filters.minPrice;
      _maxPrice = filters.maxPrice;
      _isLoading = false;
    });
    if (_queryController.text.trim().isNotEmpty) {
      final version = ++_requestVersion;
      setState(() {
        _products.clear();
        _page = 1;
        _hasReachedEnd = false;
        _isLoading = false;
      });
      await _loadPage(version: version, reset: true);
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _queryController.clear();
    _onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search products'),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: _isGridView ? 'Show list' : 'Show grid',
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
                    onSubmitted: (_) {
                      _debounce?.cancel();
                      setState(() => _isDebouncing = false);
                      _loadPage(version: _requestVersion, reset: true);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by product name...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _queryController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Search filters',
                  onPressed: _showFilters,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
          ),
          if (_selectedCategories.isNotEmpty ||
              _selectedBrands.isNotEmpty ||
              _minPrice != 0 ||
              _maxPrice != 800)
            _buildActiveFilters(theme),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(ThemeData theme) {
    final count =
        _selectedCategories.length +
        _selectedBrands.length +
        ((_minPrice != 0 || _maxPrice != 800) ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text('$count filters applied', style: theme.textTheme.labelMedium),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategories.clear();
                _selectedBrands.clear();
                _minPrice = 0;
                _maxPrice = 800;
              });
              if (_queryController.text.trim().isNotEmpty) {
                final version = ++_requestVersion;
                setState(() {
                  _products.clear();
                  _page = 1;
                  _hasReachedEnd = false;
                });
                _loadPage(version: version, reset: true);
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_queryController.text.trim().isEmpty) {
      return const _SearchPrompt();
    }
    if (_products.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_products.isEmpty && _isDebouncing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_products.isEmpty && _errorMessage != null) {
      return _SearchError(
        message: _errorMessage!,
        onRetry: () => _loadPage(version: _requestVersion, reset: true),
      );
    }
    if (_products.isEmpty) {
      return const _SearchEmpty();
    }

    final itemCount = _products.length + (_isLoading ? 1 : 0);
    if (_isGridView) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: itemCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            if (index == _products.length) return const _GridLoadingCard();
            return _SearchGridCard(product: _products[index]);
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SearchListCard(product: _products[index]),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }
}

class _SearchFilters {
  const _SearchFilters({
    required this.categories,
    required this.brands,
    required this.minPrice,
    required this.maxPrice,
  });

  final Set<String> categories;
  final Set<String> brands;
  final int minPrice;
  final int maxPrice;
}

class _SearchFilterSheet extends StatefulWidget {
  const _SearchFilterSheet({
    required this.categories,
    required this.brands,
    required this.selectedCategories,
    required this.selectedBrands,
    required this.minPrice,
    required this.maxPrice,
  });

  final List<ProductCategory> categories;
  final List<ProductBrand> brands;
  final Set<String> selectedCategories;
  final Set<String> selectedBrands;
  final int minPrice;
  final int maxPrice;

  @override
  State<_SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<_SearchFilterSheet> {
  late Set<String> _categories;
  late Set<String> _brands;
  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    _categories = {...widget.selectedCategories};
    _brands = {...widget.selectedBrands};
    _priceRange = RangeValues(
      widget.minPrice.toDouble(),
      widget.maxPrice.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Search filters',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _categories.clear();
                      _brands.clear();
                      _priceRange = const RangeValues(0, 800);
                    }),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  _FilterSection(
                    title: 'Brands',
                    children: widget.brands
                        .map(
                          (brand) => _FilterChip(
                            label: brand.name,
                            selected: _brands.contains(brand.id),
                            onSelected: (selected) => setState(() {
                              selected
                                  ? _brands.add(brand.id)
                                  : _brands.remove(brand.id);
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 22),
                  _FilterSection(
                    title: 'Categories',
                    children: widget.categories
                        .map(
                          (category) => _FilterChip(
                            label: category.name,
                            selected: _categories.contains(category.id),
                            onSelected: (selected) => setState(() {
                              selected
                                  ? _categories.add(category.id)
                                  : _categories.remove(category.id);
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Price range',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('\$${_priceRange.start.round()}'),
                      const Spacer(),
                      Text('\$${_priceRange.end.round()}'),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    labels: RangeLabels(
                      '\$${_priceRange.start.round()}',
                      '\$${_priceRange.end.round()}',
                    ),
                    onChanged: (values) => setState(() => _priceRange = values),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    _SearchFilters(
                      categories: _categories,
                      brands: _brands,
                      minPrice: _priceRange.start.round(),
                      maxPrice: _priceRange.end.round(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Apply filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Divider(),
        if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No $title available.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          Wrap(spacing: 6, runSpacing: 4, children: children),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: true,
    );
  }
}

class _SearchGridCard extends StatelessWidget {
  const _SearchGridCard({required this.product});

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
            child: _SearchProductInfo(product: product),
          ),
        ],
      ),
    );
  }
}

class _SearchListCard extends StatelessWidget {
  const _SearchListCard({required this.product});

  final StoreProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 132,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: double.infinity,
            child: CachedNetworkImage(
              imageUrl: product.imageUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _SearchProductInfo(product: product),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchProductInfo extends StatelessWidget {
  const _SearchProductInfo({required this.product});

  final StoreProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = product.price != product.oldPrice;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          children: [
            Text(
              '\$${product.price}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (hasDiscount)
              Text(
                '\$${product.oldPrice}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.error,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _GridLoadingCard extends StatelessWidget {
  const _GridLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.search_rounded, size: 70, color: theme.colorScheme.primary),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Search for a product to get started.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  const _SearchEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(
          Icons.search_off_rounded,
          size: 70,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'No products match your search.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.cloud_off_outlined, size: 54),
        const SizedBox(height: 12),
        Center(child: Text(message, textAlign: TextAlign.center)),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}
