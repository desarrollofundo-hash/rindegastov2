import 'package:flutter/material.dart';

class TabbedScreen extends StatelessWidget {
  final List<String> tabLabels;
  final List<Color> tabColors;
  final List<Widget> tabViews;

  const TabbedScreen({
    super.key,
    required this.tabLabels,
    required this.tabColors,
    required this.tabViews,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabLabels.length,
      child: Column(
        children: [
          TabBar(
            labelColor: tabColors.isNotEmpty ? tabColors[0] : Colors.indigo,
            tabs: tabLabels.map((label) => Tab(text: label)).toList(),
          ),
          Expanded(child: TabBarView(children: tabViews)),
        ],
      ),
    );
  }
}
