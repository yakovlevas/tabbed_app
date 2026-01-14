import 'package:flutter/material.dart';
import 'connection_settings_page.dart';
import 'portfolio_page.dart';

class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key});

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ConnectionSettingsPage(),
    PortfolioPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Broker Portfolio'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              // Обновление данных
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        elevation: 2,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Подключения',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Портфель',
          ),
        ],
      ),
    );
  }
}