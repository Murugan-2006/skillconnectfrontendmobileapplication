import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/worker_model.dart';

class WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback? onTap;

  const WorkerCard({
    super.key,
    required this.worker,
    this.onTap,
  });

  Color _getAvatarBgColor(String name) {
    final colors = [
      const Color(0xFFE0F2F1),
      const Color(0xFFE3F2FD),
      const Color(0xFFF3E5F5),
      const Color(0xFFFFF8E1),
      const Color(0xFFE8F5E9),
    ];
    final index = name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  Color _getAvatarTextColor(String name) {
    final colors = [
      const Color(0xFF00695C),
      const Color(0xFF1565C0),
      const Color(0xFF7B1FA2),
      const Color(0xFFF57F17),
      const Color(0xFF2E7D32),
    ];
    final index = name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.12), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Modern Clean Pastel Avatar with Active Dot Indicator
            Stack(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: _getAvatarBgColor(worker.name),
                    shape: BoxShape.circle,
                    border: Border.all(color: _getAvatarTextColor(worker.name).withOpacity(0.25), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      worker.name.isNotEmpty ? worker.name[0].toUpperCase() : 'W',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _getAvatarTextColor(worker.name),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppConstants.successColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Worker Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          worker.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: AppConstants.primaryColor, size: 16),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    worker.skill,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                            const SizedBox(width: 3),
                            Text(
                              worker.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.work_history_outlined, color: AppConstants.textSecondaryColor, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            worker.experience,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppConstants.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action Icon Pill
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
