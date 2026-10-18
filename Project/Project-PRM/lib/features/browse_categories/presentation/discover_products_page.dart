import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/category_repository.dart';
import '../models/product.dart';

class DiscoverProductsPage extends StatefulWidget {
  const DiscoverProductsPage({
    required this.repository,
    required this.title,
    this.categoryIds,
    this.brandId,
    this.offersOnly = false,
    super.key,
  });

  final CategoryRepository repository;
  final String title;
  final String? categoryIds;
  final String? brandId;
  final bool offersOnly;

  @override
  State<DiscoverProductsPage> createState() => _DiscoverProductsPageState();
}

class _DiscoverProductsPageState extends State<DiscoverProductsPage> {
  final ScrollController _scrollController = ScrollController();
  final List<StoreProduct> _products = [];

  bool _isGridView = false;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || !_hasMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await widget.repository.fetchDiscoverProducts(
        page: _page,
        categoryIds: widget.categoryIds,
        brandId: widget.brandId,
        offersOnly: widget.offersOnly,
      );
      if (!mounted) return;
      setState(() {
        _products.addAll(products);
        _page++;
        _hasMore = products.isNotEmpty;
        _isLoading = false;
      });
    } on DioException catch (error) {
      _setError(error.message ?? 'Could not connect to the store.');
    } on FormatException catch (error) {
      _setError(error.message);
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _products.clear();
      _page = 1;
      _hasMore = true;
      _errorMessage = null;
    });
    await _loadNextPage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _products.length + (_isLoading && _products.isNotEmpty ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _products.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty && _errorMessage != null
                ? _DiscoverError(
                    message: _errorMessage!,
                    onRetry: _loadNextPage,
                  )
                : _products.isEmpty
                    ? const _DiscoverEmpty()
                    : _isGridView
                        ? GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: count,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.67,
                            ),
                            itemBuilder: (context, index) {
                              if (index == _products.length) {
                                return const _LoadingCard();
                              }
                              return _ProductGridCard(
                                product: _products[index],
                              );
                            },
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: count,
                            itemBuilder: (context, index) {
                              if (index == _products.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 18),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ProductListCard(
                                  product: _products[index],
                                ),
                              );
                            },
                          ),
      ),
      bottomNavigationBar: _errorMessage != null && _products.isNotEmpty
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Material(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.cloud_off_outlined,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  title: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                  trailing: IconButton(
                    tooltip: 'Try again',
                    onPressed: _loadNextPage,
                    icon: Icon(
                      Icons.refresh,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }
}

class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({required this.product});

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
            child: _ProductText(product: product),
          ),
        ],
      ),
    );
  }
}

class _ProductListCard extends StatelessWidget {
  const _ProductListCard({required this.product});

  final StoreProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 124,
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
              padding: const EdgeInsets.all(14),
              child: _ProductText(product: product),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductText extends StatelessWidget {
  const _ProductText({required this.product});

  final StoreProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = product.oldPrice != product.price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          product.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _DiscoverEmpty extends StatelessWidget {
  const _DiscoverEmpty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 160),
        Icon(Icons.checkroom_outlined, size: 54),
        SizedBox(height: 12),
        Center(child: Text('No products found.')),
      ],
    );
  }
}

class _DiscoverError extends StatelessWidget {
  const _DiscoverError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 140),
        const Icon(Icons.cloud_off_outlined, size: 48),
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
