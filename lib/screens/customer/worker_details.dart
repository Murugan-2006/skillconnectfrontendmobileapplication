import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../models/worker_model.dart';
import '../../widgets/custom_button.dart';

class WorkerDetailsScreen extends StatelessWidget {
  const WorkerDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service Provider Profile')),
        body: const Center(child: Text('No worker data provided')),
      );
    }

    final worker = routeArgs is WorkerModel
        ? routeArgs
        : WorkerModel.fromJson(routeArgs as Map<String, dynamic>);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Service Provider Profile',
          style: TextStyle(
            color: AppConstants.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppConstants.textPrimaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Profile Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 32,
                horizontal: AppConstants.paddingLarge,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                    child: Text(
                      worker.name.isNotEmpty ? worker.name[0] : 'W',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    worker.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    worker.skill,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Rating & Experience pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              worker.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryLightColor.withOpacity(
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.work_history_outlined,
                              color: AppConstants.primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              worker.experience,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Contact & Info
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade100,
                      child: const Icon(
                        Icons.phone_outlined,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    title: const Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    subtitle: Text(
                      worker.phone.isNotEmpty ? worker.phone : 'Not Available',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge,
              ),
              child: CustomButton(
                text: 'Book Service',
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/booking-screen',
                    arguments: worker,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
