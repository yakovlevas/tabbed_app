import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/brokers_provider.dart';
import '../models/broker.dart';

class ConnectionSettingsPage extends StatefulWidget {
  const ConnectionSettingsPage({super.key});

  @override
  State<ConnectionSettingsPage> createState() => _ConnectionSettingsPageState();
}

class _ConnectionSettingsPageState extends State<ConnectionSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BrokersProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.brokers.length,
          itemBuilder: (context, index) {
            final broker = provider.brokers[index];
            return _BrokerCard(broker: broker, provider: provider);
          },
        );
      },
    );
  }
}

class _BrokerCard extends StatefulWidget {
  final Broker broker;
  final BrokersProvider provider;

  const _BrokerCard({
    required this.broker,
    required this.provider,
  });

  @override
  State<_BrokerCard> createState() => __BrokerCardState();
}

class __BrokerCardState extends State<_BrokerCard> {
  final _apiKeyController = TextEditingController();
  bool _isTesting = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = widget.broker.apiKey;
    _isSaved = widget.broker.apiKey.isNotEmpty && widget.broker.isEnabled;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final broker = widget.broker;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок брокера
            Row(
              children: [
                // Иконка брокера
                Container(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        broker.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'API интеграция',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                // Переключатель
                Switch(
                  value: broker.isEnabled,
                  onChanged: (value) {
                    widget.provider.toggleEnabled(broker.id, value);
                    if (!value) {
                      setState(() => _isSaved = false);
                    }
                  },
                  activeColor: broker.primaryColor,
                ),
              ],
            ),

            const Divider(height: 24),

            // Поле для API ключа
            if (broker.isEnabled) ...[
              TextField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: 'API Ключ',
                  hintText: 'Введите ваш API ключ',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.visibility_off),
                    onPressed: () {
                      // TODO: Показать/скрыть ключ
                    },
                  ),
                ),
                obscureText: true,
                onChanged: (value) {
                  widget.provider.updateApiKey(broker.id, value);
                  setState(() => _isSaved = false);
                },
              ),

              const SizedBox(height: 16),

              // Кнопка тестирования
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: broker.apiKey.isEmpty || _isTesting
                      ? null
                      : () async {
                          setState(() => _isTesting = true);
                          await widget.provider.testConnection(broker.id);
                          setState(() => _isSaved = true);
                          setState(() => _isTesting = false);
                        },
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.wifi_tethering, size: 18),
                  label: _isTesting
                      ? const Text('Проверка...')
                      : const Text('Проверить подключение'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: broker.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Информация о подключении
              if (broker.connectionInfo != null) _ConnectionInfo(broker: broker),

              const SizedBox(height: 16),

              // Чекбокс сохранения
              if (broker.isConnected)
                Row(
                  children: [
                    Checkbox(
                      value: _isSaved,
                      onChanged: (value) {
                        if (value == true) {
                          widget.provider.saveBroker(broker.id);
                        }
                        setState(() => _isSaved = value ?? false);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Сохранить настройки подключения',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),

              const SizedBox(height: 8),
            ] else ...[
              // Сообщение когда брокер отключен
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Включите интеграцию для настройки подключения',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Статус подключения
            if (broker.isEnabled)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: broker.isConnected
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: broker.isConnected
                        ? Colors.green[100]!
                        : Colors.red[100]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      broker.isConnected
                          ? Icons.check_circle
                          : Icons.error_outline,
                      color: broker.isConnected
                          ? Colors.green
                          : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            broker.isConnected
                                ? 'Подключено'
                                : 'Не подключено',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: broker.isConnected
                                  ? Colors.green[800]
                                  : Colors.red[800],
                            ),
                          ),
                          if (broker.lastConnection != null)
                            Text(
                              'Последняя проверка: ${_formatDate(broker.lastConnection!)}',
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
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

class _ConnectionInfo extends StatelessWidget {
  final Broker broker;

  const _ConnectionInfo({required this.broker});

  @override
  Widget build(BuildContext context) {
    if (broker.connectionInfo == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Информация о подключении',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...broker.connectionInfo!.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${_formatKey(entry.key)}:',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatValue(entry.value),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    final map = {
      'userId': 'ID пользователя',
      'premStatus': 'Премиум статус',
      'qualStatus': 'Квалиф. инвестор',
      'tariff': 'Тариф',
      'riskLevel': 'Уровень риска',
      'status': 'Статус',
      'message': 'Сообщение',
      'error': 'Ошибка',
    };
    return map[key] ?? key;
  }

  String _formatValue(dynamic value) {
    if (value is bool) {
      return value ? 'Да' : 'Нет';
    }
    return value.toString();
  }
}