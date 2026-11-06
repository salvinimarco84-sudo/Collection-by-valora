import 'package:flutter/material.dart';

class DashboardCategoryLoadingNotice extends StatelessWidget {
  const DashboardCategoryLoadingNotice({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(14),
        child: LinearProgressIndicator(),
      );
}
