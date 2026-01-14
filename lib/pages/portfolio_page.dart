import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/brokers_provider.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BrokersProvider>(
      builder: (context, provider, child) {
        final connectedBrokers = provider.connectedBrokers;

        return Scaffold(
          body: connectedBrokers.isEmpty
              ? const _EmptyPortfolio()
              : _PortfolioContent(provider: provider),
          floatingActionButton: connectedBrokers.isNotEmpty
              ? FloatingActionButton(
                  onPressed: () {
                    // Обновить данные портфеля
                  },
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.refresh),
                )
              : null,
        );
      },
    );
  }
}

class _PortfolioContent extends StatelessWidget {
  final BrokersProvider provider;

  const _PortfolioContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Общая стоимость портфеля
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Общая стоимость портфеля',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${provider.totalPortfolioValue.toStringAsFixed(2)} ₽',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_upward,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+2.4%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Распределение по брокерам',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ...provider.portfolioByBroker.entries.map((entry) {
                  final percentage = (entry.value / provider.totalPortfolioValue * 100);
                  return _BrokerAllocationItem(
                    brokerName: _getBrokerName(entry.key),
                    amount: entry.value,
                    percentage: percentage,
                    color: _getBrokerColor(entry.key),
                  );
                }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Список подключенных брокеров
        Text(
          'Подключенные брокеры',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),

        ...provider.connectedBrokers.map((broker) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: broker.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    broker.name[0],
                    style: TextStyle(
                      color: broker.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              title: Text(
                broker.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Подключен • ${provider.portfolioByBroker[broker.id]?.toStringAsFixed(0) ?? '0'} ₽',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () {
                  // Переход к детальному просмотру портфеля брокера
                },
              ),
              onTap: () {
                // Детальный просмотр портфеля брокера
              },
            ),
          );
        }),

        const SizedBox(height: 20),

        // Быстрые действия
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Быстрые действия',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ActionButton(
                      icon: Icons.add,
                      label: 'Добавить брокера',
                      onTap: () {
                        // TODO: Добавить брокера
                      },
                    ),
                    _ActionButton(
                      icon: Icons.download,
                      label: 'Экспорт данных',
                      onTap: () {
                        // TODO: Экспорт данных
                      },
                    ),
                    _ActionButton(
                      icon: Icons.analytics,
                      label: 'Аналитика',
                      onTap: () {
                        // TODO: Аналитика
                      },
                    ),
                    _ActionButton(
                      icon: Icons.notifications,
                      label: 'Уведомления',
                      onTap: () {
                        // TODO: Уведомления
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 80), // Отступ для FAB
      ],
    );
  }

  String _getBrokerName(String id) {
    switch (id) {
      case 'tinkoff':
        return 'Тинькофф';
      case 'bcs':
        return 'БКС';
      case 'finam':
        return 'ФИНАМ';
      default:
        return id;
    }
  }

  Color _getBrokerColor(String id) {
    switch (id) {
      case 'tinkoff':
        return const Color(0xFF0066FF);
      case 'bcs':
        return const Color(0xFF00A86B);
      case 'finam':
        return const Color(0xFF0D47A1);
      default:
        return Colors.blue;
    }
  }
}

class _BrokerAllocationItem extends StatelessWidget {
  final String brokerName;
  final double amount;
  final double percentage;
  final Color color;

  const _BrokerAllocationItem({
    required this.brokerName,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  brokerName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${amount.toStringAsFixed(0)} ₽',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPortfolio extends StatelessWidget {
  const _EmptyPortfolio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pie_chart_outline,
                size: 60,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Портфель пуст',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Подключите брокеров на вкладке "Подключения",\nчтобы начать отслеживать ваш портфель',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Переход к настройкам подключения
                // TODO: Реализовать навигацию
              },
              icon: const Icon(Icons.add),
              label: const Text('Добавить брокера'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}