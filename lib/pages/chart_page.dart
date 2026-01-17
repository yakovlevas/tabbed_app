// lib/pages/chart_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/portfolio.dart';
import '../models/candle_interval.dart';
import '../providers/brokers_provider.dart';

class ChartPage extends StatefulWidget {
  final PortfolioPosition position;

  const ChartPage({super.key, required this.position});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List<Map<String, dynamic>> _candles = [];
  bool _isLoading = false;
  CandleInterval _selectedInterval = CandleInterval.day;
  String _selectedPeriod = '1M';
  Map<String, dynamic> _instrumentInfo = {};
  String _lastApiError = '';
  
  // Периоды для выбора
  final Map<String, Duration> _periods = {
    '1D': const Duration(days: 1),
    '1W': const Duration(days: 7),
    '1M': const Duration(days: 30),
    '3M': const Duration(days: 90),
    '6M': const Duration(days: 180),
    '1Y': const Duration(days: 365),
    'ALL': const Duration(days: 365 * 3),
  };

  // Информация о поддерживаемых интервалах для разных периодов
  final Map<String, List<CandleInterval>> _supportedIntervalsForPeriod = {
    '1D': [CandleInterval.minute1, CandleInterval.minute5, CandleInterval.minute15, 
           CandleInterval.minute30, CandleInterval.hour],
    '1W': [CandleInterval.hour, CandleInterval.day],
    '1M': [CandleInterval.day, CandleInterval.week],
    '3M': [CandleInterval.day, CandleInterval.week],
    '6M': [CandleInterval.week, CandleInterval.month],
    '1Y': [CandleInterval.week, CandleInterval.month],
    'ALL': [CandleInterval.month],
  };

  @override
  void initState() {
    super.initState();
    _loadChartData();
    _loadInstrumentInfo();
  }

  Future<void> _loadInstrumentInfo() async {
    try {
      final provider = Provider.of<BrokersProvider>(
        context,
        listen: false,
      );
      
      final tinkoffApiService = provider.tinkoffApiService;
      if (tinkoffApiService != null && widget.position.figi.isNotEmpty) {
        _instrumentInfo = await tinkoffApiService.getInstrumentInfo(widget.position.figi);
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('Ошибка загрузки информации об инструменте: $e');
    }
  }

  Future<void> _loadChartData() async {
    final ticker = widget.position.ticker;
    if (ticker.isEmpty) {
      _showErrorMessage('У позиции нет тикера');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _lastApiError = '';
    });
    _candles.clear(); // Очищаем предыдущие данные
    
    try {
      final provider = Provider.of<BrokersProvider>(
        context,
        listen: false,
      );
      
      final tinkoffApiService = provider.tinkoffApiService;
      if (tinkoffApiService != null) {
        final to = DateTime.now();
        final from = to.subtract(_periods[_selectedPeriod]!);
        
        print('🔄 Загрузка графика для тикера: $ticker');
        print('📅 Период: $from - $to');
        print('⏱️ Интервал: ${_selectedInterval.displayName} (${_selectedInterval.value})');
        
        // Получаем реальные данные из Tinkoff API
        _candles = await tinkoffApiService.getCandles(
          ticker: ticker,
          from: from,
          to: to,
          interval: _selectedInterval,
        );
        
        print('✅ Получено свечей: ${_candles.length}');
        
        // Проверяем данные и анализируем их
        await _analyzeCandlesData();
        
        // Если данных нет или мало, показываем предупреждение
        if (_candles.isEmpty) {
          print('❌ Список свечей пуст!');
          _showNoDataMessage();
        } else if (_candles.length <= 1) {
          print('⚠️ Получено слишком мало свечей: ${_candles.length}');
          _showWarningMessage('Получено слишком мало данных для построения графика');
        }
      } else {
        _showNoConnectionMessage();
      }
    } catch (e, stackTrace) {
      print('❌ Ошибка загрузки графика: $e');
      print('❌ Stack trace: $stackTrace');
      _lastApiError = e.toString();
      _showErrorLoadingMessage(e.toString());
      
      // Если ошибка, пробуем получить данные для дневного интервала
      if (e.toString().contains('интервал') || 
          e.toString().contains('interval') ||
          _selectedInterval != CandleInterval.day) {
        print('🔄 Пробуем загрузить дневной интервал...');
        await _tryDayIntervalAsFallback(ticker);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _analyzeCandlesData() async {
    if (_candles.isEmpty) return;
    
    print('📊 Анализ полученных данных:');
    print('📊 Количество свечей: ${_candles.length}');
    
    // Проверяем временные интервалы между свечами
    final times = _candles.map((c) => DateTime.parse(c['time'])).toList();
    if (times.length >= 2) {
      final timeDiffs = <Duration>[];
      for (int i = 1; i < times.length; i++) {
        timeDiffs.add(times[i].difference(times[i-1]));
      }
      
      final avgDiff = Duration(
        microseconds: timeDiffs.fold(0, (sum, d) => sum + d.inMicroseconds) ~/ timeDiffs.length
      );
      
      print('📊 Средний интервал между свечами: $avgDiff');
      print('📊 Ожидаемый интервал: ${_selectedInterval.displayName}');
      
      // Проверяем, соответствуют ли интервалы ожидаемым
      if (_selectedInterval == CandleInterval.day && avgDiff.inHours < 20) {
        print('⚠️ Получены свечи меньшего интервала, чем запрошено!');
      } else if (_selectedInterval == CandleInterval.hour && avgDiff.inMinutes < 50) {
        print('⚠️ Получены свечи меньшего интервала, чем запрошено!');
      }
    }
    
    // Выводим информацию о первой и последней свече
    print('📊 Первая свеча: ${times.first} - Цена: ${_candles.first['close']}');
    print('📊 Последняя свеча: ${times.last} - Цена: ${_candles.last['close']}');
    
    // Проверяем диапазон цен
    final prices = _candles.map((c) => c['close'] as double).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    print('📊 Диапазон цен: $minPrice - $maxPrice (разброс: ${((maxPrice-minPrice)/minPrice*100).toStringAsFixed(2)}%)');
  }

  Future<void> _tryDayIntervalAsFallback(String ticker) async {
    try {
      final provider = Provider.of<BrokersProvider>(
        context,
        listen: false,
      );
      
      final tinkoffApiService = provider.tinkoffApiService;
      if (tinkoffApiService != null) {
        final to = DateTime.now();
        final from = to.subtract(_periods[_selectedPeriod]!);
        
        print('🔄 Загружаем дневные свечи как fallback...');
        final dayCandles = await tinkoffApiService.getCandles(
          ticker: ticker,
          from: from,
          to: to,
          interval: CandleInterval.day,
        );
        
        if (dayCandles.isNotEmpty) {
          setState(() {
            _candles = dayCandles;
            _selectedInterval = CandleInterval.day;
          });
          print('✅ Загружены дневные свечи: ${dayCandles.length}');
          _showSuccessMessage('Загружены дневные данные (другие интервалы недоступны)');
        }
      }
    } catch (e) {
      print('❌ Ошибка при загрузке дневных данных: $e');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showWarningMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showNoDataMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Нет исторических данных для этого инструмента'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showNoConnectionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Нет подключения к Tinkoff API'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorLoadingMessage(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ошибка загрузки данных: ${error.length > 50 ? '${error.substring(0, 50)}...' : error}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _getInstrumentName() {
    if (_instrumentInfo.isNotEmpty) {
      return _instrumentInfo['name'] ?? widget.position.ticker;
    }
    return widget.position.ticker.isNotEmpty 
        ? widget.position.ticker 
        : widget.position.getInstrumentTypeName();
  }

  // Быстрые кнопки для смены интервала
  Widget _buildIntervalButton(CandleInterval interval) {
    final isSelected = _selectedInterval == interval;
    // Проверяем, поддерживается ли интервал для текущего периода
    final supportedIntervals = _supportedIntervalsForPeriod[_selectedPeriod] ?? [];
    final isSupported = supportedIntervals.contains(interval);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: isSupported ? () {
          setState(() => _selectedInterval = interval);
          _loadChartData();
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue[700] : 
                         isSupported ? Colors.blue : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          interval.shortName,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPrice = widget.position.currentPrice.toDouble();
    final avgPrice = widget.position.averagePositionPrice.toDouble();
    final yieldValue = widget.position.expectedYield.toDouble();
    final isPositive = yieldValue >= 0;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getInstrumentName(),
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'График цены - ${_selectedInterval.displayName}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChartData,
            tooltip: 'Обновить данные',
          ),
          if (_lastApiError.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.warning, color: Colors.orange),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Информация об ошибке'),
                    content: Text(_lastApiError),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Закрыть'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Показать ошибку',
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Заголовок с ценой
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${currentPrice.toStringAsFixed(2)} ₽',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
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
                                  '${yieldValue >= 0 ? '+' : ''}${yieldValue.toStringAsFixed(2)} ₽',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isPositive ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Средняя цена покупки: ${avgPrice.toStringAsFixed(2)} ₽',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_instrumentInfo.isNotEmpty && _instrumentInfo['currency'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Валюта: ${_instrumentInfo['currency']} | Лот: ${_instrumentInfo['lot']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      if (_candles.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Период: ${DateTime.parse(_candles.first['time']).toString().substring(0, 10)} - '
                            '${DateTime.parse(_candles.last['time']).toString().substring(0, 10)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Быстрый выбор интервала с подсказкой
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Интервал свечей:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildIntervalButton(CandleInterval.minute1),
                            _buildIntervalButton(CandleInterval.minute5),
                            _buildIntervalButton(CandleInterval.minute15),
                            _buildIntervalButton(CandleInterval.minute30),
                            _buildIntervalButton(CandleInterval.hour),
                            _buildIntervalButton(CandleInterval.day),
                            _buildIntervalButton(CandleInterval.week),
                            _buildIntervalButton(CandleInterval.month),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Период
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Период
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedPeriod,
                          items: _periods.keys.map((period) {
                            return DropdownMenuItem(
                              value: period,
                              child: Text(period),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedPeriod = value;
                                // Автоматически подбираем подходящий интервал для периода
                                final supportedIntervals = _supportedIntervalsForPeriod[value] ?? [CandleInterval.day];
                                if (!supportedIntervals.contains(_selectedInterval)) {
                                  _selectedInterval = supportedIntervals.first;
                                }
                                _loadChartData();
                              });
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Период',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          isExpanded: true,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // График
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildChart(),
                  ),
                ),
                
                // Статистика
                if (_candles.isNotEmpty) _buildStatistics(),
                
                // Легенда
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(Colors.green, 'Текущая цена'),
                      const SizedBox(width: 16),
                      _buildLegendItem(Colors.blue, 'Цена закрытия'),
                      const SizedBox(width: 16),
                      _buildLegendItem(Colors.orange, 'Средняя цена'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChart() {
    if (_candles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет данных для отображения',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Попробуйте изменить период или интервал',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final currentPrice = widget.position.currentPrice.toDouble();
    final avgPrice = widget.position.averagePositionPrice.toDouble();
    
    // Находим min и max для масштабирования
    final prices = _candles.map((c) => c['close'] as double).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final padding = priceRange * 0.1; // 10% padding
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 300),
        painter: _ChartPainter(
          candles: _candles,
          currentPrice: currentPrice,
          avgPrice: avgPrice,
          minPrice: minPrice - padding,
          maxPrice: maxPrice + padding,
          interval: _selectedInterval,
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    if (_candles.isEmpty) return const SizedBox();
    
    final firstCandle = _candles.first;
    final lastCandle = _candles.last;
    final firstPrice = firstCandle['close'] as double;
    final lastPrice = lastCandle['close'] as double;
    final change = lastPrice - firstPrice;
    final changePercent = firstPrice != 0 ? (change / firstPrice * 100) : 0;
    final isPositiveChange = change >= 0;
    
    // Объем торгов
    final totalVolume = _candles.fold<int>(0, (sum, candle) => sum + (candle['volume'] as int));
    
    // Максимальная и минимальная цена за период
    final maxPrice = _candles.map((c) => c['high'] as double).reduce((a, b) => a > b ? a : b);
    final minPrice = _candles.map((c) => c['low'] as double).reduce((a, b) => a < b ? a : b);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Изменение',
                    '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} ₽',
                    isPositiveChange ? Colors.green : Colors.red,
                  ),
                  _buildStatItem(
                    'Изменение %',
                    '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                    isPositiveChange ? Colors.green : Colors.red,
                  ),
                  _buildStatItem(
                    'Объём',
                    '${(totalVolume / 1000000).toStringAsFixed(1)}M',
                    Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Макс цена',
                    '${maxPrice.toStringAsFixed(2)} ₽',
                    Colors.green,
                  ),
                  _buildStatItem(
                    'Мин цена',
                    '${minPrice.toStringAsFixed(2)} ₽',
                    Colors.red,
                  ),
                  _buildStatItem(
                    'Свечей',
                    '${_candles.length}',
                    Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

// Кастомный painter для рисования графика с улучшенной шкалой
class _ChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> candles;
  final double currentPrice;
  final double avgPrice;
  final double minPrice;
  final double maxPrice;
  final CandleInterval interval;

  _ChartPainter({
    required this.candles,
    required this.currentPrice,
    required this.avgPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.interval,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final priceRange = maxPrice - minPrice;
    
    // Отрисовываем фон
    _drawBackground(canvas, width, height);
    
    // Отрисовываем сетку
    _drawGrid(canvas, width, height);
    
    // Отрисовываем линию графика
    _drawPriceLine(canvas, width, height, priceRange);
    
    // Отрисовываем горизонтальные линии (текущая и средняя цена)
    _drawPriceLevels(canvas, width, height, priceRange);
    
    // Отрисовываем оси и шкалы
    _drawAxes(canvas, width, height, priceRange);
    
    // Отрисовываем свечи (японские свечи)
    _drawCandles(canvas, width, height, priceRange);
  }

  void _drawBackground(Canvas canvas, double width, double height) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(0, 0, width, height), paint);
  }

  void _drawGrid(Canvas canvas, double width, double height) {
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.5;
    
    // Вертикальные линии (время)
    for (int i = 0; i <= 5; i++) {
      final x = width * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, height), paint);
    }
    
    // Горизонтальные линии (цена)
    for (int i = 0; i <= 5; i++) {
      final y = height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(width, y), paint);
    }
  }

  void _drawPriceLine(Canvas canvas, double width, double height, double priceRange) {
    if (candles.length < 2) return;
    
    final path = Path();
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Первая точка
    final firstPrice = candles.first['close'] as double;
    final firstX = width * 0.05; // Отступ от левого края
    final firstY = height - ((firstPrice - minPrice) / priceRange * (height * 0.9)) - (height * 0.05);
    path.moveTo(firstX, firstY);
    
    // Промежуточные точки
    final availableWidth = width * 0.9; // 90% ширины для графика
    final step = availableWidth / (candles.length - 1);
    for (int i = 1; i < candles.length; i++) {
      final price = candles[i]['close'] as double;
      final x = firstX + step * i;
      final y = height - ((price - minPrice) / priceRange * (height * 0.9)) - (height * 0.05);
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
    
    // Заполняем под графиком
    final fillPath = Path()..addPath(path, Offset.zero);
    fillPath.lineTo(width * 0.95, height - height * 0.05);
    fillPath.lineTo(firstX, height - height * 0.05);
    fillPath.close();
    
    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(fillPath, fillPaint);
  }

  void _drawCandles(Canvas canvas, double width, double height, double priceRange) {
    if (candles.length > 50) return; // Слишком много свечей - показываем только линию
    
    final candleWidth = (width * 0.9) / candles.length * 0.7;
    final startX = width * 0.05;
    final availableWidth = width * 0.9;
    final step = availableWidth / candles.length;
    final chartHeight = height * 0.9;
    final chartBottom = height - height * 0.05;
    
    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final open = candle['open'] as double;
      final high = candle['high'] as double;
      final low = candle['low'] as double;
      final close = candle['close'] as double;
      final isBullish = close >= open;
      
      final x = startX + step * i + step / 2;
      
      // Высота свечи
      final openY = chartBottom - ((open - minPrice) / priceRange * chartHeight);
      final closeY = chartBottom - ((close - minPrice) / priceRange * chartHeight);
      final highY = chartBottom - ((high - minPrice) / priceRange * chartHeight);
      final lowY = chartBottom - ((low - minPrice) / priceRange * chartHeight);
      
      // Тело свечи
      final bodyPaint = Paint()
        ..color = isBullish ? Colors.green : Colors.red
        ..style = PaintingStyle.fill;
      
      final bodyTop = closeY < openY ? closeY : openY;
      final bodyBottom = closeY < openY ? openY : closeY;
      final bodyHeight = (bodyBottom - bodyTop).abs();
      
      if (bodyHeight > 0) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, (bodyTop + bodyBottom) / 2),
            width: candleWidth,
            height: bodyHeight,
          ),
          bodyPaint
        );
      }
      
      // Тени (high-low)
      final shadowPaint = Paint()
        ..color = isBullish ? Colors.green : Colors.red
        ..strokeWidth = 1.0;
      
      canvas.drawLine(
        Offset(x, highY),
        Offset(x, lowY),
        shadowPaint
      );
      
      // Верхняя тень
      if (high > (close > open ? close : open)) {
        canvas.drawLine(
          Offset(x - candleWidth / 2, highY),
          Offset(x + candleWidth / 2, highY),
          shadowPaint
        );
      }
      
      // Нижняя тень
      if (low < (close < open ? close : open)) {
        canvas.drawLine(
          Offset(x - candleWidth / 2, lowY),
          Offset(x + candleWidth / 2, lowY),
          shadowPaint
        );
      }
    }
  }

  void _drawPriceLevels(Canvas canvas, double width, double height, double priceRange) {
    // Текущая цена
    _drawPriceLevel(canvas, width, height, priceRange, currentPrice, Colors.green, 'Текущая');
    
    // Средняя цена
    _drawPriceLevel(canvas, width, height, priceRange, avgPrice, Colors.orange, 'Средняя');
  }

  void _drawPriceLevel(Canvas canvas, double width, double height, double priceRange, 
                       double price, Color color, String label) {
    final y = height - ((price - minPrice) / priceRange * (height * 0.9)) - (height * 0.05);
    
    final linePaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Пунктирная линия
    final dashPath = Path();
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double startX = width * 0.05;
    
    while (startX < width * 0.95) {
      dashPath.moveTo(startX, y);
      dashPath.lineTo(startX + dashWidth, y);
      startX += dashWidth + dashSpace;
    }
    
    canvas.drawPath(dashPath, linePaint);
    
    // Метка
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$label: ${price.toStringAsFixed(2)}',
        style: TextStyle(color: color, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    
    textPainter.paint(canvas, Offset(width * 0.05, y - 15));
  }

  void _drawAxes(Canvas canvas, double width, double height, double priceRange) {
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;
    
    // Ось X (с отступами)
    canvas.drawLine(
      Offset(width * 0.05, height - height * 0.05), 
      Offset(width * 0.95, height - height * 0.05), 
      axisPaint
    );
    
    // Ось Y (с отступами)
    canvas.drawLine(
      Offset(width * 0.05, height * 0.05), 
      Offset(width * 0.05, height - height * 0.05), 
      axisPaint
    );
    
    // Подписи к оси Y (цены) - только 3 подписи для читаемости
    final textStyle = const TextStyle(color: Colors.grey, fontSize: 9);
    final priceLevels = [
      maxPrice,
      minPrice + priceRange * 0.66,
      minPrice + priceRange * 0.33,
      minPrice,
    ];
    
    for (int i = 0; i < priceLevels.length; i++) {
      final price = priceLevels[i];
      final y = height - ((price - minPrice) / priceRange * (height * 0.9)) - (height * 0.05);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: price.toStringAsFixed(price < 10 ? 2 : 0),
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      textPainter.paint(canvas, Offset(2, y - 6));
    }
    
    // Подписи к оси X (время) - 5 подписей
    if (candles.isNotEmpty) {
      final timeLabels = _getTimeLabels();
      
      for (int i = 0; i < timeLabels.length; i++) {
        final x = width * 0.05 + (width * 0.9) * i / (timeLabels.length - 1);
        final label = timeLabels[i];
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: textStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, height - height * 0.05 + 5));
      }
    }
  }

  List<String> _getTimeLabels() {
    if (candles.isEmpty) return [];
    
    final times = candles.map((c) => DateTime.parse(c['time'])).toList();
    final List<String> labels = [];
    
    // Определяем формат в зависимости от интервала
    String format = 'HH:mm';
    if (interval == CandleInterval.day || interval == CandleInterval.week || interval == CandleInterval.month) {
      format = 'dd.MM';
    }
    
    // Берем 5 равномерно распределенных меток
    final step = (times.length - 1) ~/ 4;
    for (int i = 0; i < 5; i++) {
      final index = i * step;
      if (index < times.length) {
        final time = times[index];
        if (format == 'HH:mm') {
          labels.add('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
        } else {
          labels.add('${time.day.toString().padLeft(2, '0')}.${time.month.toString().padLeft(2, '0')}');
        }
      } else {
        labels.add('');
      }
    }
    
    return labels;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Вспомогательный класс для генерации случайных чисел
class _Random {
  final int seed;
  int _state;
  
  _Random(this.seed) : _state = seed;
  
  double nextDouble() {
    _state = _state * 1103515245 + 12345;
    return ((_state >> 16) & 0x7FFF) / 32767.0;
  }
}