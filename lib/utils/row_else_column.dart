import 'package:flutter/material.dart';

class RowElseColumn extends StatelessWidget {
  final bool isRow;
  final List<Widget> children;
  final MainAxisAlignment? mainAxisAlignment;

  const RowElseColumn(
      {super.key,
      required this.isRow,
      required this.children,
      this.mainAxisAlignment});

  @override
  Widget build(BuildContext context) {
    return isRow
        ? Row(
            mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
            children: children)
        : Column(
            mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
            children: children);
  }
}
