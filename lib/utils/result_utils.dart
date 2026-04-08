import 'package:flutter/material.dart';
import '../theme/premium_theme.dart';

class ResultUtils {
  // ──────────────────────────────────────────────
  // Formatting SGPA (Standard numeric output)
  // ──────────────────────────────────────────────
  static String formatSGPA(dynamic value) {
    if (value == null || value.toString() == '-') return '-';
    
    final numVal = double.tryParse(value.toString());
    if (numVal != null) {
      // Round to 2 decimal places as standard for SGPA
      return numVal.toStringAsFixed(2);
    }
    
    // Map letter grades if not yet converted
    switch (value.toString().toUpperCase()) {
      case 'O': return '10.00';
      case 'A+': return '9.00';
      case 'A': return '8.00';
      case 'A-': return '7.50';
      case 'B+': return '7.00';
      case 'B': return '6.00';
      case 'B-': return '5.50';
      case 'C': return '5.00';
      case 'P': return '4.00';
      case 'F': 
      case 'ABSENT':
      case 'FAIL': return '0.00';
      default: return '-';
    }
  }

  // ──────────────────────────────────────────────
  // Grade Point Mapping (Letter -> Numeric)
  // ──────────────────────────────────────────────
  static double getGradePoint(dynamic value) {
    if (value == null) return 0.0;
    
    final numVal = double.tryParse(value.toString());
    if (numVal != null) return numVal;
    
    switch (value.toString().toUpperCase()) {
      case 'O': return 10.0;
      case 'A+': return 9.0;
      case 'A': return 8.0;
      case 'A-': return 7.5;
      case 'B+': return 7.0;
      case 'B': return 6.0;
      case 'B-': return 5.5;
      case 'C': return 5.0;
      case 'P': return 4.0;
      case 'F':
      case 'ABSENT':
      case 'FAIL': return 0.0;
      default: return 0.0;
    }
  }

  // ──────────────────────────────────────────────
  // Color code based on results
  // ──────────────────────────────────────────────
  static Color getGradeColor(dynamic value) {
    if (value == null) return PremiumTheme.textSecondary;

    final numVal = getGradePoint(value);
    
    if (numVal >= 8.0) return PremiumTheme.success;
    if (numVal >= 4.0) return PremiumTheme.primary;
    if (numVal > 0.0) return Colors.orange; // Needs more effort
    if (numVal == 0.0 && (value.toString().toUpperCase() == 'F' || 
                           value.toString().toUpperCase() == 'ABSENT' ||
                           value.toString().toUpperCase() == 'FAIL')) {
      return PremiumTheme.error;
    }
    
    return PremiumTheme.textSecondary;
  }

  // ──────────────────────────────────────────────
  // Passing Status check
  // ──────────────────────────────────────────────
  static bool isPassing(dynamic value) {
    if (value == null) return false;
    final numVal = getGradePoint(value);
    return numVal >= 4.0;
  }
}
