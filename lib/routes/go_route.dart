import 'package:accountify/features/banks/screens/all_banks_screen.dart';
import 'package:accountify/home_screen.dart';
import 'package:accountify/main_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const MainScreen();
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) {
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: '/all_banks',
          builder: (BuildContext context, GoRouterState state) {
            return const AllBanksScreen();
          },
        ),
      ],
    ),
  ],
);