import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../models/worker_model.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../widgets/custom_button.dart';
import 'describe_problem_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedWorkType;

  final List<String> _workTypes = ['Electrician', 'Plumber', 'AC Repair', 'Electronic Repair'];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppConstants.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _confirmBooking(WorkerModel worker) {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book service')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DescribeProblemScreen(
          category: _selectedWorkType ?? worker.skill,
          workerId: worker.id,
          workerName: worker.name,
          isBroadcast: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final worker = ModalRoute.of(context)!.settings.arguments as WorkerModel;
    final bookingService = Provider.of<BookingService>(context);

    // Set initial value for dropdown based on worker skill if not set yet
    if (_selectedWorkType == null) {
      if (_workTypes.contains(worker.skill)) {
        _selectedWorkType = worker.skill;
      } else {
        _selectedWorkType = _workTypes.first;
      }
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Book Service',
          style: TextStyle(color: AppConstants.textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppConstants.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Booking Info Header
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                      child: Text(worker.name.isNotEmpty ? worker.name[0] : 'W', style: const TextStyle(color: AppConstants.primaryColor)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking for ${worker.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.textPrimaryColor),
                        ),
                        const SizedBox(height: 4),
                        Text(worker.skill, style: const TextStyle(color: AppConstants.primaryColor, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Dropdown to select kind of work
              const Text(
                'What kind of work do you need?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppConstants.textPrimaryColor),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedWorkType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _workTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWorkType = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Date Picker Select
              const Text(
                'Select Date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppConstants.textPrimaryColor),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.toLocal()}'.split(' ')[0],
                        style: const TextStyle(fontSize: 16, color: AppConstants.textPrimaryColor),
                      ),
                      const Icon(Icons.calendar_month, color: AppConstants.primaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Book Button
              bookingService.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                  : CustomButton(
                      text: 'Confirm Booking',
                      onPressed: () => _confirmBooking(worker),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
