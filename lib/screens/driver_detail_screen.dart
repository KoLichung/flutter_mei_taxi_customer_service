import 'package:flutter/material.dart';
import 'recharge_form_screen.dart';
import '../services/api_service.dart';
import '../models/recharge_record_model.dart';

class DriverDetailScreen extends StatefulWidget {
  final int driverId;
  final String driverName;
  final String driverPhone;
  final double balance;

  const DriverDetailScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.balance,
  });

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  double _currentBalance = 0;
  List<RechargeRecordModel> _rechargeHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentBalance = widget.balance;
    _loadRechargeRecords();
  }

  Future<void> _loadRechargeRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getDriverRechargeRecords(
        driverId: widget.driverId,
        page: 1,
        pageSize: 20,
      );

      final recordsJson = response['records'] as List;
      final records = recordsJson
          .map((json) => RechargeRecordModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // 更新餘額
      if (response['driver_left_money'] != null) {
        _currentBalance = (response['driver_left_money'] as num).toDouble();
      }

      setState(() {
        _rechargeHistory = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToRecharge() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RechargeFormScreen(
          driverId: widget.driverId,
          driverName: widget.driverName,
          currentBalance: _currentBalance,
        ),
      ),
    );

    if (result != null && result is double) {
      setState(() {
        _currentBalance = result;
      });
      // 重新載入儲值記錄
      _loadRechargeRecords();
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.driverName),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 司機資訊卡片
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue,
                          child: Text(
                            widget.driverName.isNotEmpty ? widget.driverName[0] : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.driverName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.driverPhone,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${widget.driverId.toString()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '現有儲值',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'NT\$ ${_currentBalance.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _navigateToRecharge,
                          icon: const Icon(Icons.add),
                          label: const Text('儲值'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 儲值記錄標題
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    '儲值記錄',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 儲值記錄列表
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                '錯誤: $_errorMessage',
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadRechargeRecords,
                                child: const Text('重試'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _rechargeHistory.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('暫無儲值記錄'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _rechargeHistory.length,
                            itemBuilder: (context, index) {
                              final record = _rechargeHistory[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: record.increaseMoney >= 0
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                    child: Icon(
                                      record.increaseMoney >= 0
                                          ? Icons.add_circle
                                          : Icons.remove_circle,
                                      color: record.increaseMoney >= 0
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                                  ),
                                  title: Text(
                                    'NT\$ ${record.increaseMoney >= 0 ? '+' : ''}${record.increaseMoney.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: record.increaseMoney >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('時間: ${_formatTime(record.date)}'),
                                  ),
                                ),
                              );
                            },
                          ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
