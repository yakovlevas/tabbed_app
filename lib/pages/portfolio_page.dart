
// lib/pages/portfolio_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/brokers_provider.dart';
import '../models/portfolio.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  @override
  void initState() {
    super.initState();
    // Загружаем портфель при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPortfolioData();
    });
  }

  Future<void> _loadPortfolioData() async {
    final provider = Provider.of<BrokersProvider>(
      context,
      listen: false,
    );
    
    // Проверяем, подключен ли Tinkoff
    final tinkoffBroker = provider.getBrokerById('tinkoff');
    if (tinkoffBroker != null && tinkoffBroker.isConnected) {
      await provider.loadTinkoffPortfolio();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BrokersProvider>(
      builder: (context, provider, child) {
        final connectedBrokers = provider.connectedBrokers;
        final hasTinkoffData = provider.tinkoffPortfolio != null;
        final positions = provider.tinkoffPortfolio?.positions ?? [];
        
        return Scaffold(
          body: connectedBrokers.isEmpty
              ? const _EmptyPortfolio()
              : _PortfolioContent(
                  provider: provider,
                  hasTinkoffData: hasTinkoffData,
                  positions: positions,
                ),
          floatingActionButton: connectedBrokers.isNotEmpty
              ? FloatingActionButton(
                  onPressed: () {
                    provider.refreshPortfolio();
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
  final bool hasTinkoffData;
  final List<PortfolioPosition> positions;

  const _PortfolioContent({
    required this.provider,
    required this.hasTinkoffData,
    required this.positions,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingPortfolio) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.portfolioError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                provider.portfolioError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.refreshPortfolio(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshPortfolio(),
      child: ListView(
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
                      if (hasTinkoffData && provider.tinkoffPortfolio != null)
                        _PortfolioChangeIndicator(
                          portfolio: provider.tinkoffPortfolio!,
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

          // Карточка Tinkoff портфеля
          if (hasTinkoffData) ...[
            const SizedBox(height: 20),
            _TinkoffPortfolioCard(
              portfolio: provider.tinkoffPortfolio!,
              onPositionTap: (position) {
                _showPositionDetails(context, position);
              },
            ),
          ],

          const SizedBox(height: 20),

          // ВСЕ ПОЗИЦИИ ПОРТФЕЛЯ
          if (positions.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Все позиции портфеля',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Chip(
                      label: Text('${positions.length} позиций'),
                      backgroundColor: Colors.blue[50],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: positions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final position = positions[index];
                    return _PositionListItem(
                      position: position,
                      onTap: () {
                        _showPositionDetails(context, position);
                      },
                    );
                  },
                ),
              ],
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
                      broker.isConnected ? 'Подключен' : 'Не подключен',
                      style: TextStyle(
                        fontSize: 12,
                        color: broker.isConnected ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Детальный просмотр портфеля брокера
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

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showPositionDetails(BuildContext context, PortfolioPosition position) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => _PositionDetailsSheet(position: position),
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

class _PortfolioChangeIndicator extends StatelessWidget {
  final Portfolio portfolio;

  const _PortfolioChangeIndicator({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final expectedYield = portfolio.expectedYield.toDouble();
    final totalValue = portfolio.getTotalValue();
    final yieldPercent = totalValue > 0 ? (expectedYield / totalValue * 100) : 0;
    final isPositive = expectedYield >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: isPositive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            '${expectedYield >= 0 ? '+' : ''}${yieldPercent.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPositive ? Colors.green[800] : Colors.red[800],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinkoffPortfolioCard extends StatelessWidget {
  final Portfolio portfolio;
  final Function(PortfolioPosition) onPositionTap;

  const _TinkoffPortfolioCard({
    required this.portfolio,
    required this.onPositionTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalValue = portfolio.getTotalValue();
    final expectedYield = portfolio.expectedYield.toDouble();
    final dailyYield = portfolio.dailyYield.toDouble();
    final dailyYieldRelative = portfolio.dailyYieldRelative.toDouble() * 100;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Т',
                      style: TextStyle(
                        color: const Color(0xFF0066FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Тинькофф Инвестиции',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Счёт: ${portfolio.accountId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Доходность
            Row(
              children: [
                Expanded(
                  child: _YieldCard(
                    label: 'Доходность',
                    value: expectedYield,
                    total: totalValue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _YieldCard(
                    label: 'За день',
                    value: dailyYield,
                    percent: dailyYieldRelative,
                    isDaily: true,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Распределение активов
            Text(
              'Распределение активов',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildAssetDistribution(portfolio),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetDistribution(Portfolio portfolio) {
    final total = portfolio.getTotalValue();
    
    return Column(
      children: [
        _buildAssetRow('Акции', portfolio.totalAmountShares, Colors.blue, total),
        const SizedBox(height: 12),
        _buildAssetRow('Облигации', portfolio.totalAmountBonds, Colors.green, total),
        const SizedBox(height: 12),
        _buildAssetRow('ETF', portfolio.totalAmountEtf, Colors.orange, total),
        const SizedBox(height: 12),
        _buildAssetRow('Валюта', portfolio.totalAmountCurrencies, Colors.purple, total),
      ],
    );
  }

  Widget _buildAssetRow(String name, MoneyAmount amount, Color color, double total) {
    final value = amount.toDouble();
    final percent = total > 0 ? (value / total * 100) : 0;
    
    return Column(
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
                name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              '${value.toStringAsFixed(2)} ₽',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent / 100,
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
              '${percent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _YieldCard extends StatelessWidget {
  final String label;
  final double value;
  final double? total;
  final double? percent;
  final bool isDaily;

  const _YieldCard({
    required this.label,
    required this.value,
    this.total,
    this.percent,
    this.isDaily = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = value >= 0;
    final displayPercent = percent ?? (total != null && total! > 0 ? (value / total! * 100) : 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: isPositive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)} ₽',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${displayPercent >= 0 ? '+' : ''}${displayPercent.toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 12,
              color: isPositive ? Colors.green[800] : Colors.red[800],
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionListItem extends StatelessWidget {
  final PortfolioPosition position;
  final VoidCallback onTap;

  const _PositionListItem({
    required this.position,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentValue = position.getPositionValue();
    final yieldValue = position.expectedYield.toDouble();
    final avgPrice = position.averagePositionPrice.toDouble();
    final currentPrice = position.currentPrice.toDouble();
    final isPositive = yieldValue >= 0;
    final yieldPercent = avgPrice > 0 ? (yieldValue / avgPrice * 100) : 0;
    
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Заголовок
              Row(
                children: [
                  // Иконка типа
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getTypeColor(position.instrumentType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        _getTypeIcon(position.instrumentType),
                        color: _getTypeColor(position.instrumentType),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              position.ticker.isNotEmpty ? position.ticker : '---',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getTypeColor(position.instrumentType).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                position.getInstrumentTypeName(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getTypeColor(position.instrumentType),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getInstrumentDescription(position),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${currentValue.toStringAsFixed(2)} ₽',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPositive ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 12,
                              color: isPositive ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${yieldValue >= 0 ? '+' : ''}${yieldValue.toStringAsFixed(2)} ₽',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Статистика
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItem(
                    label: 'Кол-во',
                    value: '${position.quantity.toDouble()} шт',
                  ),
                  _StatItem(
                    label: 'Ср. цена',
                    value: '${avgPrice.toStringAsFixed(2)} ₽',
                  ),
                  _StatItem(
                    label: 'Текущая',
                    value: '${currentPrice.toStringAsFixed(2)} ₽',
                  ),
                  _StatItem(
                    label: 'Доходность',
                    value: '${yieldPercent.toStringAsFixed(1)}%',
                    valueColor: isPositive ? Colors.green : Colors.red,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Прогресс-бар стоимости
              LinearProgressIndicator(
                value: position.quantity.toDouble() * currentPrice / 100000, // Примерная нормализация
                backgroundColor: Colors.grey[200],
                color: _getTypeColor(position.instrumentType),
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getInstrumentDescription(PortfolioPosition position) {
    if (position.ticker.isNotEmpty) {
      return position.figi;
    }
    return position.figi;
  }
  
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'share': return Icons.trending_up;
      case 'bond': return Icons.account_balance;
      case 'etf': return Icons.pie_chart;
      case 'currency': return Icons.currency_ruble;
      default: return Icons.question_mark;
    }
  }
  
  Color _getTypeColor(String type) {
    switch (type) {
      case 'share': return Colors.blue;
      case 'bond': return Colors.green;
      case 'etf': return Colors.orange;
      case 'currency': return Colors.purple;
      default: return Colors.grey;
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}

class _PositionDetailsSheet extends StatelessWidget {
  final PortfolioPosition position;

  const _PositionDetailsSheet({required this.position});

  @override
  Widget build(BuildContext context) {
    final currentValue = position.getPositionValue();
    final yieldValue = position.expectedYield.toDouble();
    final avgPrice = position.averagePositionPrice.toDouble();
    final currentPrice = position.currentPrice.toDouble();
    final quantity = position.quantity.toDouble();
    final isPositive = yieldValue >= 0;
    final yieldPercent = avgPrice > 0 ? (yieldValue / avgPrice * 100) : 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Информация о бумаге
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getTypeColor(position.instrumentType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _getTypeIcon(position.instrumentType),
                    color: _getTypeColor(position.instrumentType),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          position.ticker.isNotEmpty ? position.ticker : '---',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTypeColor(position.instrumentType).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            position.getInstrumentTypeName(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getTypeColor(position.instrumentType),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      position.figi,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Текущая стоимость
          Center(
            child: Column(
              children: [
                const Text(
                  'Текущая стоимость',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currentValue.toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Карточки с основными показателями
          Row(
            children: [
              Expanded(
                child: _DetailCard(
                  title: 'Количество',
                  value: '$quantity шт',
                  icon: Icons.layers,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailCard(
                  title: 'Средняя цена',
                  value: '${avgPrice.toStringAsFixed(2)} ₽',
                  icon: Icons.price_change,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _DetailCard(
                  title: 'Текущая цена',
                  value: '${currentPrice.toStringAsFixed(2)} ₽',
                  icon: Icons.monetization_on,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailCard(
                  title: 'Доходность',
                  value: '${yieldPercent.toStringAsFixed(1)}%',
                  valueColor: isPositive ? Colors.green : Colors.red,
                  icon: isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Подробная таблица
          Text(
            'Детальная информация',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(2),
              },
              children: [
                _buildTableRow('Тикер', position.ticker.isNotEmpty ? position.ticker : '---'),
                _buildTableRow('FIGI', position.figi),
                _buildTableRow('Тип инструмента', position.getInstrumentTypeName()),
                _buildTableRow('Class Code', position.classCode),
                _buildTableRow('Стоимость позиции', '${currentValue.toStringAsFixed(2)} ₽'),
                _buildTableRow('Абсолютная доходность', '${yieldValue >= 0 ? '+' : ''}${yieldValue.toStringAsFixed(2)} ₽',
                    valueColor: isPositive ? Colors.green : Colors.red),
                _buildTableRow('Относительная доходность', '${yieldPercent >= 0 ? '+' : ''}${yieldPercent.toStringAsFixed(2)}%',
                    valueColor: isPositive ? Colors.green : Colors.red),
                _buildTableRow('Инвестировано', '${(quantity * avgPrice).toStringAsFixed(2)} ₽'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Кнопки действий
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Показать график
                  },
                  icon: const Icon(Icons.timeline),
                  label: const Text('График'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Показать новости
                  },
                  icon: const Icon(Icons.article),
                  label: const Text('Новости'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  TableRow _buildTableRow(String label, String value, {Color? valueColor}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black,
            ),
          ),
        ),
      ],
    );
  }
  
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'share': return Icons.trending_up;
      case 'bond': return Icons.account_balance;
      case 'etf': return Icons.pie_chart;
      case 'currency': return Icons.currency_ruble;
      default: return Icons.question_mark;
    }
  }
  
  Color _getTypeColor(String type) {
    switch (type) {
      case 'share': return Colors.blue;
      case 'bond': return Colors.green;
      case 'etf': return Colors.orange;
      case 'currency': return Colors.purple;
      default: return Colors.grey;
    }
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color? valueColor;

  const _DetailCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? color,
            ),
          ),
        ],
      ),
    );
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
