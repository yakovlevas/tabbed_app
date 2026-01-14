import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/main_tabs.dart';
import 'providers/brokers_provider.dart';

void main() {
  runApp(const BrokerPortfolioApp());
}

class BrokerPortfolioApp extends StatelessWidget {
  const BrokerPortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BrokersProvider()),
      ],
      child: MaterialApp(
        title: 'Multi-Broker Portfolio',
        theme: ThemeData(
          primaryColor: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          appBarTheme: const AppBarTheme(
            color: Colors.white,
            elevation: 1,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        home: const MainTabsPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}