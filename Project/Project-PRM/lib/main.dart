import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'features/browse_categories/data/category_repository.dart';
import 'features/browse_categories/presentation/browse_categories_page.dart';

void main() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://efashion-backend.onrender.com/api',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  runApp(ProjectPrmApp(repository: CategoryRepository(dio)));
}

class ProjectPrmApp extends StatelessWidget {
  const ProjectPrmApp({required this.repository, super.key});

  final CategoryRepository repository;

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF526070);

    return MaterialApp(
      title: 'Browse Product Categories',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          surface: const Color(0xFFF8F8F6),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F8F6),
        useMaterial3: true,
      ),
      home: BrowseCategoriesPage(repository: repository),
    );
  }
}
