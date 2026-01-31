import 'package:flutter/material.dart';
import 'package:goldfinch_crm/theme.dart';

class SkeletonDashboard extends StatefulWidget {
  const SkeletonDashboard({super.key});

  @override
  State<SkeletonDashboard> createState() => _SkeletonDashboardState();
}

class _SkeletonDashboardState extends State<SkeletonDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1, milliseconds: 500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header skeleton
      _Shimmer(controller: _controller, height: 40, width: 200),
      const SizedBox(height: 8),
      _Shimmer(controller: _controller, height: 20, width: 300),
      const SizedBox(height: 24),
      
      // Cards skeleton
      Wrap(spacing: 12, runSpacing: 12, children: List.generate(4, (i) => 
        _Shimmer(controller: _controller, height: 100, width: 220)
      )),
      
      const SizedBox(height: 24),
      
      // Chart skeleton
      _Shimmer(controller: _controller, height: 300, width: double.infinity),
    ]);
  }
}

class _Shimmer extends StatelessWidget {
  final AnimationController controller;
  final double height;
  final double width;

  const _Shimmer({required this.controller, required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Color.lerp(Colors.grey.shade200, Colors.grey.shade100, controller.value),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        );
      },
    );
  }
}
