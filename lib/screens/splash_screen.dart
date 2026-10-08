import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/dineflow_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DineFlowMark(
              size: 96,
              style: DineFlowMarkStyle.appTile,
            ),
            SizedBox(height: 24),
            DineFlowLogo(
              markSize: 0,
              fontSize: 32,
              tagline: 'Serve. Send. Flow. · Restaurant Operations',
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
            SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
