import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: AppConstants.textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppConstants.errorColor),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Analytics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard('Total Users', '142', Icons.people, Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard('Verified Workers', '48', Icons.verified_user, Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard('Total Bookings', '812', Icons.receipt_long, Colors.purple),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard('Pending Approvals', '5', Icons.pending, Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Pending Worker Approvals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 2,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final names = ['Rajesh Kumar', 'Amit Patel'];
                  final skills = ['Electrician (3 yrs exp)', 'Plumber (5 yrs exp)'];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                      child: Text(names[index][0], style: const TextStyle(color: AppConstants.primaryColor)),
                    ),
                    title: Text(names[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(skills[index]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.successColor,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () {},
                          child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppConstants.errorColor,
                            side: const BorderSide(color: AppConstants.errorColor),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () {},
                          child: const Text('Reject', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppConstants.textSecondaryColor, fontSize: 12)),
              const SizedBox(height: 4),
              Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor)),
            ],
          ),
        ],
      ),
    );
  }
}
