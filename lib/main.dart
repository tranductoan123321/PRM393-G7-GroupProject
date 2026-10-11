import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'components/productComponent/data/repositories/home_repository_impl.dart';
import 'components/productComponent/domain/usecases/home/get_home_data_usecase.dart';
import 'presentation/product/bloc/home_bloc/home_cubit.dart';
import 'presentation/product/screens/home_screen.dart';

void main() {
  runApp(const ProjectApp());
}

class ProjectApp extends StatelessWidget {
  const ProjectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          HomeCubit(GetHomeDataUseCase(HomeRepositoryImpl()))..loadHome(),
      child: MaterialApp(
        title: 'Project App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Montserrat',
          scaffoldBackgroundColor: const Color(0xFFF1F0F4),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00629D),
            primary: const Color(0xFF00629D),
            secondary: const Color(0xFF526070),
            surface: const Color(0xFFF9F9FC),
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
