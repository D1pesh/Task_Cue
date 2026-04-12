// import 'package:flutter/material.dart';

// class ErrorScreen extends StatefulWidget {
//   final String message;
//   final VoidCallback? onRetry;

//   const ErrorScreen({
//     super.key,
//     this.message = 'An error occurred',
//     this.onRetry,
//   });

//   @override
//   State<ErrorScreen> createState() => _ErrorScreenState();
// }

// class _ErrorScreenState extends State<ErrorScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.error_outline,
//               color: Colors.red,
//               size: 64,
//             ),
//             const SizedBox(height: 24),
//             Text(
//               'Something went wrong',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             const SizedBox(height: 12),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: Text(
//                 widget.message,
//                 textAlign: TextAlign.center,
//                 style: Theme.of(context).textTheme.bodyMedium,
//               ),
//             ),
//             const SizedBox(height: 32),
//             if (widget.onRetry != null)
//               ElevatedButton.icon(
//                 onPressed: widget.onRetry,
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('Retry'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
