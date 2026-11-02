import 'package:flutter/material.dart';
import '../models/incident.dart';

// Colors and icons in one place, so every screen looks consistent
class StatusStyle {
  static Color color(String status) {
    switch (status) {
      case IncidentStatus.inProgress:
        return Colors.orange;
      case IncidentStatus.resolved:
        return Colors.green;
      case IncidentStatus.rejected:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  static IconData icon(String status) {
    switch (status) {
      case IncidentStatus.inProgress:
        return Icons.build_circle_outlined;
      case IncidentStatus.resolved:
        return Icons.check_circle_outline;
      case IncidentStatus.rejected:
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }
}

class CategoryStyle {
  static IconData icon(String category) {
    switch (category) {
      case 'Water':
        return Icons.water_drop_outlined;
      case 'Electricity':
        return Icons.bolt;
      case 'Facilities':
        return Icons.apartment;
      case 'Furniture':
        return Icons.chair_outlined;
      case 'Sanitation':
        return Icons.cleaning_services_outlined;
      case 'Safety':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.report_outlined;
    }
  }
}

class PriorityStyle {
  static Color color(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}