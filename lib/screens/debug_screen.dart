// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../services/youtube_service.dart';
// import '../utils/app_colors.dart';
//
// class DebugScreen extends StatefulWidget {
//   @override
//   _DebugScreenState createState() => _DebugScreenState();
// }
//
// class _DebugScreenState extends State<DebugScreen> {
//   final YouTubeService _youtubeService = YouTubeService();
//   Map<String, dynamic>? _testResult;
//   bool _isLoading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('API Debug'),
//         backgroundColor: AppColors.primaryAccent,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           children: [
//             ElevatedButton(
//               onPressed: _isLoading ? null : _testApi,
//               child: _isLoading
//                   ? CircularProgressIndicator(color: Colors.white)
//                   : Text('Test YouTube API'),
//             ),
//             SizedBox(height: 20),
//             if (_testResult != null)
//               Expanded(
//                 child: Container(
//                   padding: EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: SingleChildScrollView(
//                     child: Text(
//                       _testResult.toString(),
//                       style: GoogleFonts.robotoMono(fontSize: 12),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _testApi() async {
//     setState(() {
//       _isLoading = true;
//       _testResult = null;
//     });
//
//     try {
//       final result = await _youtubeService.testApiAndGetChannelId();
//       setState(() {
//         _testResult = result;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _testResult = {'error': e.toString()};
//         _isLoading = false;
//       });
//     }
//   }
// }