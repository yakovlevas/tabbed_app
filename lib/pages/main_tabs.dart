
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'connection_settings_page.dart';
import 'portfolio_page.dart';
import '../providers/brokers_provider.dart';

class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key});

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildCurrentPage(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final titles = ['Подключения', 'Портфель'];
    
    return AppBar(
      title: Text(
        titles[_currentIndex],
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      centerTitle: true,
      actions: _buildAppBarActions(context),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    if (_currentIndex == 0) { // На вкладке Подключения
      return [
        Consumer<BrokersProvider>(
          builder: (context, provider, child) {
            // Проверяем, есть ли сохраненные брокеры
            final hasSavedBrokers = provider.brokers.any((b) => b.isSaved);
            
            if (hasSavedBrokers) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black),
                onSelected: (value) {
                  if (value == 'clear') {
                    _showClearConfirmationDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Очистить все данные', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ];
    } else if (_currentIndex == 1) { // На вкладке Портфель
      return [
        Consumer<BrokersProvider>(
          builder: (context, provider, child) {
            if (provider.isLoadingPortfolio) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () {
                provider.refreshPortfolio();
              },
              tooltip: 'Обновить портфель',
            );
          },
        ),
      ];
    }
    return [];
  }

  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все данные?'),
        content: const Text('Это действие удалит все сохраненные API ключи и сбросит настройки подключения ко всем брокерам. Вы уверены?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<BrokersProvider>(context, listen: false).clearAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Все данные очищены'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const ConnectionSettingsPage();
      case 1:
        return const PortfolioPage();
      default:
        return const Center(child: Text('Страница не найдена'));
    }
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() => _currentIndex = index);
      },
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      elevation: 2,
      type: BottomNavigationBarType.fixed,
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
    );
  }
}
