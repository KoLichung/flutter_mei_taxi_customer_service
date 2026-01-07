import 'package:flutter/material.dart';
import 'message_list_screen.dart';
import 'recharge_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mei派車客服'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.message), text: '司機訊息'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: '儲值管理'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MessageListScreen(),
          RechargeScreen(),
        ],
      ),
    );
  }
}

