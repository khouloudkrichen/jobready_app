import 'package:flutter/material.dart';
import '../../services/face_detection_service.dart';

class FaceStatusChip extends StatelessWidget {
  final InterviewFaceResult result;

  const FaceStatusChip({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (result.status) {
      case 'valid':
        bg = Colors.green.withOpacity(0.14);
        fg = Colors.green.shade700;
        icon = Icons.check_circle;
        label = 'Visage bien détecté';
        break;
      case 'multiple':
        bg = Colors.orange.withOpacity(0.14);
        fg = Colors.orange.shade800;
        icon = Icons.groups;
        label = 'Plusieurs visages';
        break;
      case 'partial':
        bg = Colors.orange.withOpacity(0.14);
        fg = Colors.orange.shade800;
        icon = Icons.warning_amber_rounded;
        label = 'Visage partiellement visible';
        break;
      default:
        bg = Colors.red.withOpacity(0.14);
        fg = Colors.red.shade700;
        icon = Icons.cancel;
        label = 'Visage absent';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label • ${result.score.toStringAsFixed(0)}%',
              style: TextStyle(color: fg, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
