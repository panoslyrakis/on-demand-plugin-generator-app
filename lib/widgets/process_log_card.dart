import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/app_colors.dart';

class ProcessLogCard extends StatelessWidget {
  const ProcessLogCard({
    super.key,
    required this.logContent,
    this.isLoading = false,
  });

  final String logContent;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.terminal, color: AppColors.infoMain),
                const SizedBox(width: 8),
                const Text(
                  'Process Log:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLoading) ...[
                  const Spacer(),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(color: AppColors.grey300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  logContent.isEmpty ? 'Process log will appear here...' : logContent,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: logContent.isEmpty ? AppColors.grey500 : AppColors.grey900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}