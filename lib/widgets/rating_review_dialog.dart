import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/constants.dart';
import '../models/booking_model.dart';

class RatingReviewDialog extends StatefulWidget {
  final BookingModel booking;
  final VoidCallback? onSubmitted;

  const RatingReviewDialog({
    super.key,
    required this.booking,
    this.onSubmitted,
  });

  @override
  State<RatingReviewDialog> createState() => _RatingReviewDialogState();
}

class _RatingReviewDialogState extends State<RatingReviewDialog> {
  int _selectedRating = 5;
  final TextEditingController _commentController = TextEditingController();
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  final List<String> _availableTags = [
    'Fast Service ⚡',
    'Punctual ⏰',
    'Polite & Respectful 😊',
    'Clean Work 🧹',
    'Fair Price 💰',
    'Expert Work 🛠️',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.reviews),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'bookingId': widget.booking.id,
          'customerId': widget.booking.customerId,
          'workerId': widget.booking.workerId,
          'rating': _selectedRating,
          'comment': _commentController.text.trim(),
          'tags': _selectedTags,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Thank you! Your feedback has been submitted.'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        Navigator.pop(context);
        widget.onSubmitted?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit review. Please try again.'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    } catch (e) {
      debugPrint('Submit review error: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Icon Header
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 38),
              ),
              const SizedBox(height: 12),
              const Text(
                'Rate Your Experience',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'How was the service for ${widget.booking.service}?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppConstants.textSecondaryColor),
              ),
              const SizedBox(height: 20),

              // 5 Star Rating Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    iconSize: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(
                      starIndex <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: starIndex <= _selectedRating ? Colors.amber : Colors.grey[400],
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedRating = starIndex;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                _selectedRating == 5
                    ? 'Excellent! ⭐⭐⭐⭐⭐'
                    : _selectedRating == 4
                        ? 'Very Good ⭐⭐⭐⭐'
                        : _selectedRating == 3
                            ? 'Good ⭐⭐⭐'
                            : _selectedRating == 2
                                ? 'Fair ⭐⭐'
                                : 'Poor ⭐',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor, fontSize: 13),
              ),
              const SizedBox(height: 18),

              // Feedback Quick Chips
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'What stood out?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.textSecondaryColor),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppConstants.primaryColor : AppConstants.textPrimaryColor,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppConstants.primaryColor.withOpacity(0.15),
                    checkmarkColor: AppConstants.primaryColor,
                    backgroundColor: Colors.grey[100],
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Feedback Comments Box
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share more details about your service experience...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppConstants.primaryColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit & Cancel Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Skip', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : _submitReview,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Submit Review',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
