import 'package:flutter/material.dart';

class ResponsiveView extends StatelessWidget {
  final Widget mobileCards;
  final Widget desktopTable;
  final double breakpoint;

  const ResponsiveView({
    super.key,
    required this.mobileCards,
    required this.desktopTable,
    this.breakpoint = 768.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return mobileCards;
        }
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: desktopTable,
          ),
        );
      },
    );
  }
}
