import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  static const _tabs = ['Flights', 'Hotels', 'Cars'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carlton Leisure')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final selected = i == _tabIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accent : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _tabs[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.textOnAccent : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: Center(
              child: Text('${_tabs[_tabIndex]} search form goes here'),
            ),
          ),
        ],
      ),
    );
  }
}
