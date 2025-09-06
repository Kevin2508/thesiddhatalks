// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import '../utils/app_colors.dart';
// import '../models/video_models.dart';
// import '../screens/player_screen.dart';

// class LiveStreamBanner extends StatefulWidget {
//   const LiveStreamBanner({Key? key}) : super(key: key);

//   @override
//   State<LiveStreamBanner> createState() => _LiveStreamBannerState();
// }

// class _LiveStreamBannerState extends State<LiveStreamBanner>
//     with TickerProviderStateMixin {
//   Video? _liveStream;
//   bool _isLoading = true;

//   late AnimationController _pulseController;
//   late AnimationController _shimmerController;
//   late Animation<double> _pulseAnimation;
//   late Animation<double> _shimmerAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _setupAnimations();
//     _checkForLiveStream();
//   }

//   void _setupAnimations() {
//     _pulseController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     );

//     _shimmerController = AnimationController(
//       duration: const Duration(seconds: 1),
//       vsync: this,
//     );

//     _pulseAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.1,
//     ).animate(CurvedAnimation(
//       parent: _pulseController,
//       curve: Curves.easeInOut,
//     ));

//     _shimmerAnimation = Tween<double>(
//       begin: -1.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _shimmerController,
//       curve: Curves.easeInOut,
//     ));

//     _pulseController.repeat(reverse: true);
//     _shimmerController.repeat();
//   }

//   void _checkForLiveStream() async {
//     // TODO: Check Firestore for active live streams
//     // For now, simulate no live stream
//     setState(() {
//       _liveStream = null;
//       _isLoading = false;
//     });
//   }

//   @override
//   void dispose() {
//     _pulseController.dispose();
//     _shimmerController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return _buildLoadingBanner();
//     }

//     if (_liveStream == null) {
//       return const SizedBox.shrink(); // No live stream, hide banner
//     }

//     return _buildLiveBanner(_liveStream!);
//   }

//   Widget _buildLoadingBanner() {
//     return Container(
//       height: 60,
//       margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//       decoration: BoxDecoration(
//         color: AppColors.cardBackground,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.shadowLight,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: AnimatedBuilder(
//         animation: _shimmerAnimation,
//         builder: (context, child) {
//           return Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   AppColors.cardBackground,
//                   AppColors.surfaceBackground,
//                   AppColors.cardBackground,
//                 ],
//                 stops: [
//                   (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
//                   _shimmerAnimation.value.clamp(0.0, 1.0),
//                   (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildLiveBanner(Video liveStream) {
//     return GestureDetector(
//       onTap: () => _playLiveStream(liveStream),
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Colors.red.shade600,
//               Colors.red.shade700,
//             ],
//           ),
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.red.withOpacity(0.3),
//               blurRadius: 15,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: Stack(
//             children: [
//               // Background pattern
//               Positioned.fill(
//                 child: CustomPaint(
//                   painter: LivePatternPainter(),
//                 ),
//               ),

//               // Content
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     // Live indicator
//                     AnimatedBuilder(
//                       animation: _pulseAnimation,
//                       builder: (context, child) {
//                         return Transform.scale(
//                           scale: _pulseAnimation.value,
//                           child: Container(
//                             width: 12,
//                             height: 12,
//                             decoration: const BoxDecoration(
//                               color: Colors.white,
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                         );
//                       },
//                     ),

//                     const SizedBox(width: 12),

//                     // Live text
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Text(
//                         'LIVE',
//                         style: GoogleFonts.rajdhani(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                           letterSpacing: 1.2,
//                         ),
//                       ),
//                     ),

//                     const SizedBox(width: 16),

//                     // Stream info
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             liveStream.title,
//                             style: GoogleFonts.lato(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           Text(
//                             'Tap to join live stream',
//                             style: GoogleFonts.lato(
//                               fontSize: 12,
//                               color: Colors.white.withOpacity(0.9),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     // Play button
//                     Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(
//                         Icons.play_arrow,
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _playLiveStream(Video liveStream) {
//     HapticFeedback.mediumImpact();
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => PlayerScreen(video: liveStream),
//       ),
//     );
//   }
// }

// class LivePatternPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white.withOpacity(0.1)
//       ..style = PaintingStyle.fill;

//     // Create subtle wave pattern
//     final path = Path();
//     path.moveTo(0, size.height * 0.7);
    
//     for (double x = 0; x <= size.width; x += 20) {
//       final y = size.height * 0.7 + 
//                (size.height * 0.1) * 
//                (0.5 + 0.5 * (x / size.width));
//       path.lineTo(x, y);
//     }
    
//     path.lineTo(size.width, size.height);
//     path.lineTo(0, size.height);
//     path.close();

//     canvas.drawPath(path, paint);

//     // Add dots pattern
//     paint.color = Colors.white.withOpacity(0.05);
//     for (double x = 10; x < size.width; x += 25) {
//       for (double y = 10; y < size.height; y += 15) {
//         canvas.drawCircle(Offset(x, y), 1, paint);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(LivePatternPainter oldDelegate) => false;
// }
