import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/constants.dart';
import '../config/api_config.dart';

class ProblemDetailsView extends StatelessWidget {
  final String? description;
  final List<String>? images;
  final String? videoUrl;

  const ProblemDetailsView({
    super.key,
    this.description,
    this.images,
    this.videoUrl,
  });

  void _showImageDialog(BuildContext context, String imageUrl) {
    final resolvedUrl = ApiConfig.resolveUrl(imageUrl);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  resolvedUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 250,
                      child: Center(child: CircularProgressIndicator(color: Colors.white)),
                    );
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoDialog(BuildContext context, String videoUrl) {
    showDialog(
      context: context,
      builder: (ctx) => NetworkVideoPlayerDialog(videoUrl: videoUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDescription = description != null && description!.trim().isNotEmpty;
    final hasImages = images != null && images!.isNotEmpty;
    final hasVideo = videoUrl != null && videoUrl!.trim().isNotEmpty;

    if (!hasDescription && !hasImages && !hasVideo) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.assignment_outlined, size: 18, color: AppConstants.primaryColor),
              SizedBox(width: 6),
              Text(
                'Problem Details:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.textPrimaryColor),
              ),
            ],
          ),
          if (hasDescription) ...[
            const SizedBox(height: 6),
            Text(
              description!,
              style: const TextStyle(fontSize: 14, color: AppConstants.textPrimaryColor, height: 1.3),
            ),
          ],
          if (hasImages) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.collections_outlined, size: 14, color: AppConstants.textSecondaryColor),
                const SizedBox(width: 4),
                Text(
                  'Images (${images!.length}):',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.textSecondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images!.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final url = images![index];
                  final resolved = ApiConfig.resolveUrl(url);
                  return GestureDetector(
                    onTap: () => _showImageDialog(context, url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        resolved,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          width: 64,
                          height: 64,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image_rounded, size: 24, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (hasVideo) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _showVideoDialog(context, videoUrl!),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.play_circle_fill_rounded, color: AppConstants.primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Watch Problem Video (30s max)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class NetworkVideoPlayerDialog extends StatefulWidget {
  final String videoUrl;

  const NetworkVideoPlayerDialog({super.key, required this.videoUrl});

  @override
  State<NetworkVideoPlayerDialog> createState() => _NetworkVideoPlayerDialogState();
}

class _NetworkVideoPlayerDialogState extends State<NetworkVideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final resolvedVideoUrl = ApiConfig.resolveUrl(widget.videoUrl);
    _controller = VideoPlayerController.networkUrl(Uri.parse(resolvedVideoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.play();
        }
      }).catchError((err) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text('Problem Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          if (_hasError) ...[
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Failed to load video player', style: TextStyle(color: Colors.redAccent)),
            ),
          ] else if (_isInitialized) ...[
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio > 0 ? _controller.value.aspectRatio : 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  IconButton(
                    iconSize: 50,
                    icon: Icon(
                      _controller.value.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    onPressed: () {
                      setState(() {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            VideoProgressIndicator(_controller, allowScrubbing: true, colors: const VideoProgressColors(playedColor: AppConstants.primaryColor)),
            const SizedBox(height: 12),
          ] else ...[
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}
