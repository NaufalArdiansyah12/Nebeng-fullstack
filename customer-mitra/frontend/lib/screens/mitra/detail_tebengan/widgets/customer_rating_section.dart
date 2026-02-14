import 'dart:io';
import 'package:flutter/material.dart';

class CustomerRatingSection extends StatelessWidget {
  final String status;
  final bool isCheckingRating;
  final bool hasRating;
  final int selectedRating;
  final Set<String> selectedFeedback;
  final File? proofImage;
  final bool isSubmittingRating;
  final String customerName;
  final List<String> feedbackOptions;
  final Function(int) onRatingChanged;
  final Function(String) onFeedbackToggled;
  final VoidCallback onPickImage;
  final VoidCallback onSubmitRating;

  const CustomerRatingSection({
    Key? key,
    required this.status,
    required this.isCheckingRating,
    required this.hasRating,
    required this.selectedRating,
    required this.selectedFeedback,
    required this.proofImage,
    required this.isSubmittingRating,
    required this.customerName,
    required this.feedbackOptions,
    required this.onRatingChanged,
    required this.onFeedbackToggled,
    required this.onPickImage,
    required this.onSubmitRating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only show for completed rides
    if (status != 'completed' && status != 'selesai') {
      return const SizedBox.shrink();
    }

    // Show loading while checking
    if (isCheckingRating) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.white,
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Don't show if already rated
    if (hasRating) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFD1FAE5),
          border: Border.all(color: const Color(0xFF059669)),
        ),
        child: Row(
          children: const [
            Icon(Icons.check_circle, color: Color(0xFF059669)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Customer sudah diberi rating',
                style: TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFBBF24), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Beri Rating Customer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Gimana $customerName ?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => onRatingChanged(index + 1),
                child: Icon(
                  index < selectedRating ? Icons.star : Icons.star_border,
                  size: 48,
                  color: const Color(0xFFFBBF24),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Feedback chips
          const Text(
            'Apa yang kamu suka dari pelanggannya?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: feedbackOptions.map((option) {
              final isSelected = selectedFeedback.contains(option);
              return GestureDetector(
                onTap: () => onFeedbackToggled(option),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1E40AF) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1E40AF)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Photo upload
          const Text(
            'Kirim bukti foto barang yang sudah di kirim',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onPickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: proofImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        proofImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate,
                            size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Tambah Foto',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // Submit button - only show if not rated yet
          if (!hasRating)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isSubmittingRating ? null : onSubmitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isSubmittingRating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'KIRIM RATING',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
