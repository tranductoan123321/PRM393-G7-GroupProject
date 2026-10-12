import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/productComponent/data/repositories/home_repository_impl.dart';
import '../../../components/productComponent/domain/entities/brand.dart';
import '../../../components/productComponent/domain/entities/category.dart';
import '../../../components/productComponent/domain/entities/product.dart';
import '../bloc/search_bloc/search_cubit.dart';
import '../bloc/search_bloc/search_state.dart';
import '../../shared/widgets/home_network_image.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({
    required this.categories,
    required this.brands,
    super.key,
  });

  final List<HomeCategory> categories;
  final List<HomeBrand> brands;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SearchCubit(HomeRepositoryImpl()),
    child: _SearchScreenView(categories: categories, brands: brands),
  );
}

class _SearchScreenView extends StatefulWidget {
  const _SearchScreenView({required this.categories, required this.brands});

  final List<HomeCategory> categories;
  final List<HomeBrand> brands;

  @override
  State<_SearchScreenView> createState() => _SearchScreenViewState();
}

class _SearchScreenViewState extends State<_SearchScreenView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  bool _showGrid = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNearEnd);
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      context.read<SearchCubit>().search(query);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => context.read<SearchCubit>().search(query),
    );
  }

  void _loadMoreWhenNearEnd() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 400) {
      context.read<SearchCubit>().loadMore();
    }
  }

  Future<void> _openFilters(SearchState state) async {
    final filters = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SearchFilterSheet(
        categories: widget.categories,
        brands: widget.brands,
        initialFilters: state.filters,
      ),
    );
    if (!mounted || filters == null) return;
    context.read<SearchCubit>().search(
      _searchController.text,
      filters: filters,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Search')),
    body: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          BlocBuilder<SearchCubit, SearchState>(
            builder: (context, state) => Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
                    onSubmitted: (query) {
                      _debounce?.cancel();
                      context.read<SearchCubit>().search(query);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                context.read<SearchCubit>().search('');
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Filter products',
                  onPressed: () => _openFilters(state),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BlocBuilder<SearchCubit, SearchState>(
            builder: (context, state) => Row(
              children: [
                Expanded(
                  child: Text(
                    state.products.isEmpty
                        ? 'Search by product name'
                        : '${state.products.length} products',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'List view',
                  onPressed: () => setState(() => _showGrid = false),
                  isSelected: !_showGrid,
                  icon: const Icon(Icons.view_list_rounded),
                ),
                IconButton(
                  tooltip: 'Grid view',
                  onPressed: () => setState(() => _showGrid = true),
                  isSelected: _showGrid,
                  icon: const Icon(Icons.grid_view_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state.status == SearchStatus.initial) {
                  return const _SearchMessage(
                    icon: Icons.search_rounded,
                    message: 'Enter a product name to start searching.',
                  );
                }
                if (state.status == SearchStatus.loading &&
                    state.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == SearchStatus.failure &&
                    state.products.isEmpty) {
                  return _SearchMessage(
                    icon: Icons.cloud_off_outlined,
                    message: state.error ?? 'Could not search products.',
                    action: FilledButton.icon(
                      onPressed: () => context.read<SearchCubit>().search(
                        _searchController.text,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  );
                }
                if (state.products.isEmpty) {
                  return const _SearchMessage(
                    icon: Icons.search_off_rounded,
                    message: 'No products found.',
                  );
                }

                return Column(
                  children: [
                    if (state.error != null)
                      MaterialBanner(
                        content: Text(state.error!),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                context.read<SearchCubit>().loadMore(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    Expanded(
                      child: _showGrid
                          ? _buildGrid(state.products, state.isLoadingMore)
                          : _buildList(state.products, state.isLoadingMore),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildList(List<HomeProduct> products, bool isLoadingMore) =>
      ListView.builder(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: products.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) => index == products.length
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            : _SearchListCard(product: products[index]),
      );

  Widget _buildGrid(List<HomeProduct> products, bool isLoadingMore) =>
      GridView.builder(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemCount: products.length + (isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) => index >= products.length
            ? const Center(child: CircularProgressIndicator())
            : _SearchGridCard(product: products[index]),
      );

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController
      ..removeListener(_loadMoreWhenNearEnd)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}

class _SearchListCard extends StatelessWidget {
  const _SearchListCard({required this.product});

  final HomeProduct product;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      height: 124,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: HomeNetworkImage(
              product.imageUrl,
              fit: BoxFit.cover,
              fallbackIcon: Icons.checkroom_outlined,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _ProductPrice(product: product),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SearchGridCard extends StatelessWidget {
  const _SearchGridCard({required this.product});

  final HomeProduct product;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: HomeNetworkImage(
              product.imageUrl,
              fit: BoxFit.cover,
              fallbackIcon: Icons.checkroom_outlined,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _ProductPrice(product: product),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProductPrice extends StatelessWidget {
  const _ProductPrice({required this.product});

  final HomeProduct product;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        '\$${product.price}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      if (product.oldPrice > product.price) ...[
        const SizedBox(width: 8),
        Text(
          '\$${product.oldPrice}',
          style: const TextStyle(
            color: Colors.grey,
            decoration: TextDecoration.lineThrough,
            fontSize: 12,
          ),
        ),
      ],
    ],
  );
}

class _SearchFilterSheet extends StatefulWidget {
  const _SearchFilterSheet({
    required this.categories,
    required this.brands,
    required this.initialFilters,
  });

  final List<HomeCategory> categories;
  final List<HomeBrand> brands;
  final SearchFilters initialFilters;

  @override
  State<_SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<_SearchFilterSheet> {
  final _formKey = GlobalKey<FormState>();
  late final Set<String> _categoryIds;
  late final Set<String> _brandIds;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _categoryIds = {...widget.initialFilters.categoryIds};
    _brandIds = {...widget.initialFilters.brandIds};
    _minPriceController = TextEditingController(
      text: widget.initialFilters.minPrice?.toString() ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.initialFilters.maxPrice?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter products',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (widget.categories.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _FilterHeading('Categories'),
                Wrap(
                  spacing: 8,
                  children: widget.categories
                      .map(
                        (category) => FilterChip(
                          label: Text(category.name),
                          selected: _categoryIds.contains(category.id),
                          onSelected: (selected) => setState(
                            () => selected
                                ? _categoryIds.add(category.id)
                                : _categoryIds.remove(category.id),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              if (widget.brands.isNotEmpty) ...[
                const SizedBox(height: 12),
                const _FilterHeading('Brands'),
                Wrap(
                  spacing: 8,
                  children: widget.brands
                      .map(
                        (brand) => FilterChip(
                          label: Text(brand.name),
                          selected: _brandIds.contains(brand.id),
                          onSelected: (selected) => setState(
                            () => selected
                                ? _brandIds.add(brand.id)
                                : _brandIds.remove(brand.id),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: 12),
              const _FilterHeading('Price range'),
              Row(
                children: [
                  Expanded(
                    child: _priceField(
                      controller: _minPriceController,
                      label: 'Minimum',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _priceField(
                      controller: _maxPriceController,
                      label: 'Maximum',
                      validateMaximum: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _priceField({
    required TextEditingController controller,
    required String label,
    bool validateMaximum = false,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      labelText: label,
      prefixText: '\$ ',
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return null;
      final price = int.tryParse(text);
      if (price == null || price < 0) return 'Enter a valid price';
      if (validateMaximum) {
        final minimum = int.tryParse(_minPriceController.text.trim());
        if (minimum != null && price < minimum) {
          return 'Must be at least the minimum';
        }
      }
      return null;
    },
  );

  void _applyFilters() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      SearchFilters(
        categoryIds: _categoryIds.toList(growable: false),
        brandIds: _brandIds.toList(growable: false),
        minPrice: int.tryParse(_minPriceController.text.trim()),
        maxPrice: int.tryParse(_maxPriceController.text.trim()),
      ),
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }
}

class _FilterHeading extends StatelessWidget {
  const _FilterHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}
