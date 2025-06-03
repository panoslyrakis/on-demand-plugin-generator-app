import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class InstructionCard extends StatelessWidget {
  const InstructionCard({
    super.key,
    required this.title,
    required this.instructions,
    this.warningMessage,
  });

  final String title;
  final List<String> instructions;
  final String? warningMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.infoLight,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.infoMain),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.infoDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Instructions
            ...instructions.asMap().entries.map((entry) {
              int index = entry.key;
              String instruction = entry.value;
              return _buildInstructionStep((index + 1).toString(), instruction);
            }),
            
            // Warning message if provided
            if (warningMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(color: AppColors.warningMain),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.warningDark, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warningMessage!,
                        style: const TextStyle(
                          color: AppColors.warningDark,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.infoMain,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}