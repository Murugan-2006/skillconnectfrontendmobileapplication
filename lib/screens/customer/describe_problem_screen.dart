import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/location_service.dart';
import '../../services/upload_service.dart';

class DescribeProblemScreen extends StatefulWidget {
  final String category;
  final String? workerId;
  final String? workerName;
  final bool isBroadcast;

  const DescribeProblemScreen({
    super.key,
    required this.category,
    this.workerId,
    this.workerName,
    this.isBroadcast = true,
  });

  @override
  State<DescribeProblemScreen> createState() => _DescribeProblemScreenState();
}

class _DescribeProblemScreenState extends State<DescribeProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final UploadService _uploadService = UploadService();

  final List<XFile> _selectedImages = [];
  XFile? _selectedVideo;
  VideoPlayerController? _videoPlayerController;
  bool _isEmergency = false;
  bool _isSubmitting = false;
  String _uploadProgressText = '';

  // Standard example problems requested by specs
  final List<String> _exampleProblems = [
    'AC is leaking water when turned on.',
    'AC is not cooling.',
    'AC is making unusual noise.',
    'Fan is not rotating.',
    'Refrigerator is not cooling.',
    'Washing machine is vibrating heavily.',
    'Electrical switchboard is sparking.',
    'House wiring issue.',
    'Water motor is not working.',
    'Plumbing pipe leakage.',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _initVideoPlayer(XFile file) async {
    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.file(File(file.path));
    await _videoPlayerController!.initialize();
    setState(() {});
  }

  Future<void> _pickImageSource() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppConstants.primaryColor),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final images = await _uploadService.pickImages(currentCount: _selectedImages.length);
                  if (images.isNotEmpty) {
                    setState(() {
                      _selectedImages.addAll(images);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppConstants.primaryColor),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final image = await _uploadService.captureImage();
                  if (image != null) {
                    setState(() {
                      _selectedImages.add(image);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickVideoSource() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.video_library_rounded, color: AppConstants.primaryColor),
                title: const Text('Choose Video from Gallery (Max 30s)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final video = await _uploadService.pickVideo(source: ImageSource.gallery);
                  if (video != null) {
                    setState(() {
                      _selectedVideo = video;
                    });
                    _initVideoPlayer(video);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_rounded, color: AppConstants.primaryColor),
                title: const Text('Record Video (Max 30s)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final video = await _uploadService.pickVideo(source: ImageSource.camera);
                  if (video != null) {
                    setState(() {
                      _selectedVideo = video;
                    });
                    _initVideoPlayer(video);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeVideo() {
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    setState(() {
      _selectedVideo = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final bookingService = Provider.of<BookingService>(context, listen: false);

    if (authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit your request')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgressText = 'Preparing attachments...';
    });

    try {
      // 1. Get current location (with 4s timeout for high accuracy)
      Position? currentPosition;
      try {
        currentPosition = await LocationService().getCurrentLocation().timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Location error or timeout: $e');
      }

      // 2. Upload images and video to Cloudinary in PARALLEL
      if (_selectedImages.isNotEmpty || _selectedVideo != null) {
        setState(() {
          _uploadProgressText = 'Uploading media to Cloudinary...';
        });
      }

      final List<Future<String?>> imageFutures = _selectedImages
          .map((img) => _uploadService.uploadToCloudinary(img, resourceType: 'image'))
          .toList();

      final Future<String?> videoFuture = _selectedVideo != null
          ? _uploadService.uploadToCloudinary(_selectedVideo!, resourceType: 'video')
          : Future.value(null);

      final results = await Future.wait([...imageFutures, videoFuture]);

      final List<String> imageUrls = results
          .sublist(0, _selectedImages.length)
          .whereType<String>()
          .toList();
      final String? videoUrl = results.last;

      // 3. Create booking via API
      setState(() {
        _uploadProgressText = 'Submitting request to service providers...';
      });

      final success = await bookingService.createBooking(
        customerId: authService.currentUser!.id,
        workerId: widget.workerId,
        service: widget.category,
        date: DateTime.now(),
        token: authService.token ?? '',
        latitude: currentPosition?.latitude,
        longitude: currentPosition?.longitude,
        description: _descriptionController.text.trim(),
        problemImages: imageUrls,
        problemVideo: videoUrl,
        isEmergency: _isEmergency,
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        bookingService.fetchBookings(authService.currentUser!.id, authService.token ?? '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isBroadcast
                ? 'Request broadcasted successfully! Nearby providers are being notified.'
                : 'Booking request sent to ${widget.workerName ?? "provider"}!'),
            backgroundColor: AppConstants.successColor,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.popUntil(context, ModalRoute.withName('/customer-home'));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit request. Please try again.'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting request: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Describe Your Problem',
          style: TextStyle(color: AppConstants.textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppConstants.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service category banner card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.build_circle_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.category,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.isBroadcast
                                    ? 'Broadcast Request to all nearby providers'
                                    : 'Direct Request to ${widget.workerName ?? "Worker"}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppConstants.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Emergency SOS Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isEmergency ? AppConstants.errorColor.withValues(alpha: 0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _isEmergency ? AppConstants.errorColor : Colors.grey.shade300, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.emergency_rounded, color: _isEmergency ? AppConstants.errorColor : AppConstants.textSecondaryColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEmergency ? 'Emergency SOS Mode 🚨' : 'Normal Service Booking',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _isEmergency ? AppConstants.errorColor : AppConstants.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isEmergency
                                    ? 'Parallel dispatch to top 3 nearest workers. First to accept locks job.'
                                    : 'Standard booking request.',
                                style: const TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _isEmergency,
                          activeColor: AppConstants.errorColor,
                          onChanged: (val) {
                            setState(() {
                              _isEmergency = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Problem description input
                  const Text(
                    'Problem Description *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Explain what is happening so the technician comes prepared with tools.',
                    style: TextStyle(fontSize: 13, color: AppConstants.textSecondaryColor),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please provide a description of the problem';
                      }
                      if (value.trim().length < 5) {
                        return 'Description must be at least 5 characters long';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. AC is leaking water when turned on, or making an unusual noise...',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Example problem quick chips
                  const Text(
                    'Quick suggestions:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.textSecondaryColor),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _exampleProblems.map((problem) {
                      return ChoiceChip(
                        label: Text(problem, style: const TextStyle(fontSize: 12)),
                        selected: _descriptionController.text.contains(problem),
                        selectedColor: AppConstants.primaryColor.withValues(alpha: 0.18),
                        onSelected: (selected) {
                          setState(() {
                            if (_descriptionController.text.trim().isEmpty) {
                              _descriptionController.text = problem;
                            } else {
                              _descriptionController.text = '${_descriptionController.text.trim()} $problem';
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Image attachments section (max 5)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upload Images (Optional)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
                      ),
                      Text(
                        '${_selectedImages.length} / 5',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.textSecondaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Attach up to 5 photos showing the issue or equipment label.',
                    style: TextStyle(fontSize: 13, color: AppConstants.textSecondaryColor),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length + (_selectedImages.length < 5 ? 1 : 0),
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        if (index == _selectedImages.length) {
                          return GestureDetector(
                            onTap: _pickImageSource,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.4), style: BorderStyle.solid),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, color: AppConstants.primaryColor, size: 28),
                                  SizedBox(height: 6),
                                  Text('Add Photo', style: TextStyle(fontSize: 12, color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        }

                        final imageFile = _selectedImages[index];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(imageFile.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Video attachment section (1 video, max 30s)
                  const Text(
                    'Upload Video (Optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Record or upload a short video (max 30 seconds) demonstrating noise or behavior.',
                    style: TextStyle(fontSize: 13, color: AppConstants.textSecondaryColor),
                  ),
                  const SizedBox(height: 12),

                  if (_selectedVideo == null) ...[
                    OutlinedButton.icon(
                      onPressed: _pickVideoSource,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: AppConstants.primaryColor.withValues(alpha: 0.5)),
                      ),
                      icon: const Icon(Icons.videocam_rounded, color: AppConstants.primaryColor),
                      label: const Text('Record or Choose Video (Max 30s)', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized)
                            AspectRatio(
                              aspectRatio: _videoPlayerController!.value.aspectRatio > 0
                                  ? _videoPlayerController!.value.aspectRatio
                                  : 16 / 9,
                              child: VideoPlayer(_videoPlayerController!),
                            )
                          else
                            const SizedBox(
                              height: 180,
                              child: Center(child: CircularProgressIndicator(color: Colors.white)),
                            ),
                          IconButton(
                            iconSize: 50,
                            icon: Icon(
                              _videoPlayerController?.value.isPlaying == true
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            onPressed: () {
                              setState(() {
                                if (_videoPlayerController!.value.isPlaying) {
                                  _videoPlayerController!.pause();
                                } else {
                                  _videoPlayerController!.play();
                                }
                              });
                            },
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                              style: IconButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.8)),
                              onPressed: _removeVideo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Loading Overlay during submit/upload
          if (_isSubmitting)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppConstants.primaryColor),
                        const SizedBox(height: 20),
                        Text(
                          _uploadProgressText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
          ),
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: Text(
            widget.isBroadcast ? 'Confirm & Broadcast Request' : 'Confirm & Request Service',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
