// Rule-based scholarship eligibility checker (FREE - no AI APIs)

import 'package:flutter/foundation.dart'; // For debugPrint
import '../models/student_profile.dart';
import '../models/scholarship.dart';

class EligibilityService {
  // Check if a student is eligible for a scholarship
  static bool checkEligibility(
    StudentProfile profile,
    Scholarship scholarship,
  ) {
    debugPrint(
      'Checking Eligibility for: ${scholarship.title} vs Student: ${profile.name}',
    );
    final criteria = scholarship.eligibilityCriteria;

    // Check income range
    if (!_checkIncomeEligibility(profile.familyIncome, criteria)) {
      return false;
    }

    // Check category/reservation
    if (!_checkCategoryEligibility(profile.category, criteria)) {
      return false;
    }

    // Check course eligibility
    if (!_checkCourseEligibility(profile.course, criteria)) {
      return false;
    }

    // Check year eligibility
    if (!_checkYearEligibility(profile.year, criteria)) {
      debugPrint(
        'Eligibility Failed: Year mismatch. Student: ${profile.year}, Req: ${criteria.years}',
      );
      return false;
    }

    // Check CGPA eligibility
    debugPrint(
      'Checking CGPA: Student ${profile.cgpa} vs Min ${criteria.minCGPA}',
    );
    if (!_checkCGPAEligibility(profile.cgpa, criteria)) {
      debugPrint('Eligibility Failed: CGPA too low');
      return false;
    }

    // Check Attendance eligibility
    debugPrint(
      'Checking Attendance: Student ${profile.attendance} vs Min ${criteria.minAttendance}',
    );
    if (!_checkAttendanceEligibility(profile.attendance, criteria)) {
      debugPrint('Eligibility Failed: Attendance too low');
      return false;
    }

    debugPrint('Eligibility Passed for ${scholarship.title}');
    return true;
  }

  // Get eligibility details with reasons
  static Map<String, dynamic> getEligibilityDetails(
    StudentProfile profile,
    Scholarship scholarship,
  ) {
    final criteria = scholarship.eligibilityCriteria;
    final List<String> reasons = [];
    final List<String> failedCriteria = [];

    // Income check
    if (_checkIncomeEligibility(profile.familyIncome, criteria)) {
      reasons.add(
        '✓ Income criteria met (₹${profile.familyIncome.toStringAsFixed(0)})',
      );
    } else {
      failedCriteria.add(
        '✗ Income not in range (₹${criteria.minIncome.toStringAsFixed(0)} - ₹${criteria.maxIncome.toStringAsFixed(0)})',
      );
    }

    // Category check
    if (_checkCategoryEligibility(profile.category, criteria)) {
      reasons.add('✓ Category eligible (${profile.category})');
    } else {
      failedCriteria.add(
        '✗ Category not eligible (Required: ${criteria.categories.join(', ')})',
      );
    }

    // Course check
    if (_checkCourseEligibility(profile.course, criteria)) {
      reasons.add('✓ Course eligible (${profile.course})');
    } else {
      failedCriteria.add(
        '✗ Course not eligible (Required: ${criteria.courses.join(', ')})',
      );
    }

    // Year check
    if (_checkYearEligibility(profile.year, criteria)) {
      reasons.add('✓ Year eligible (Year ${profile.year})');
    } else {
      failedCriteria.add(
        '✗ Year not eligible (Required: ${criteria.years.join(', ')})',
      );
    }

    // CGPA check
    if (_checkCGPAEligibility(profile.cgpa, criteria)) {
      if (criteria.minCGPA > 0) {
        reasons.add(
          '✓ CGPA Requirement Met (${profile.cgpa} >= ${criteria.minCGPA})',
        );
      }
    } else {
      failedCriteria.add(
        '✗ CGPA too low (${profile.cgpa} < ${criteria.minCGPA})',
      );
    }

    // Attendance check
    if (_checkAttendanceEligibility(profile.attendance, criteria)) {
      if (criteria.minAttendance > 0) {
        reasons.add(
          '✓ Attendance Requirement Met (${profile.attendance}% >= ${criteria.minAttendance}%)',
        );
      }
    } else {
      failedCriteria.add(
        '✗ Attendance too low (${profile.attendance}% < ${criteria.minAttendance}%)',
      );
    }

    final isEligible = failedCriteria.isEmpty;

    return {
      'isEligible': isEligible,
      'passedCriteria': reasons,
      'failedCriteria': failedCriteria,
      'message': isEligible
          ? 'You are eligible for this scholarship!'
          : 'You are not eligible for this scholarship.',
    };
  }

  // Get recommended scholarships for a student
  static List<Scholarship> getRecommendedScholarships(
    StudentProfile profile,
    List<Scholarship> allScholarships,
  ) {
    return allScholarships
        .where(
          (scholarship) =>
              checkEligibility(profile, scholarship) && !scholarship.isExpired,
        )
        .toList()
      ..sort((a, b) {
        // Sort by deadline (urgent first) and amount (higher first)
        final deadlineCompare = a.deadline.compareTo(b.deadline);
        if (deadlineCompare != 0) return deadlineCompare;
        return b.amount.compareTo(a.amount);
      });
  }

  // Calculate match score (0-100) for better recommendations
  static int calculateMatchScore(
    StudentProfile profile,
    Scholarship scholarship,
  ) {
    int score = 0;

    final criteria = scholarship.eligibilityCriteria;

    // Income match (30 points)
    if (_checkIncomeEligibility(profile.familyIncome, criteria)) {
      score += 30;
    }

    // Category match (15 points)
    if (_checkCategoryEligibility(profile.category, criteria)) {
      score += 15;
    }

    // Course match (15 points)
    if (_checkCourseEligibility(profile.course, criteria)) {
      score += 15;
    }

    // Year match (10 points)
    if (_checkYearEligibility(profile.year, criteria)) {
      score += 10;
    }

    // CGPA match (15 points)
    if (_checkCGPAEligibility(profile.cgpa, criteria)) {
      score += 15;
    }

    // Attendance match (15 points)
    if (_checkAttendanceEligibility(profile.attendance, criteria)) {
      score += 15;
    }

    return score;
  }

  // Private helper methods
  static bool _checkIncomeEligibility(
    double income,
    EligibilityCriteria criteria,
  ) {
    return income >= criteria.minIncome && income <= criteria.maxIncome;
  }

  static bool _checkCategoryEligibility(
    String category,
    EligibilityCriteria criteria,
  ) {
    // If no categories specified, all are eligible
    if (criteria.categories.isEmpty) return true;

    final normalizedCategory = category.trim().toLowerCase();
    return criteria.categories.any(
      (c) => c.trim().toLowerCase() == normalizedCategory,
    );
  }

  static bool _checkCourseEligibility(
    String course,
    EligibilityCriteria criteria,
  ) {
    // If no courses specified, all are eligible
    if (criteria.courses.isEmpty) return true;

    final normalizedCourse = course.trim().toLowerCase();
    return criteria.courses.any(
      (c) => c.trim().toLowerCase() == normalizedCourse,
    );
  }

  static bool _checkYearEligibility(int year, EligibilityCriteria criteria) {
    // If no years specified, all are eligible
    if (criteria.years.isEmpty) return true;
    return criteria.years.contains(year);
  }

  static bool _checkCGPAEligibility(double cgpa, EligibilityCriteria criteria) {
    if (criteria.minCGPA <= 0) return true;
    return cgpa >= criteria.minCGPA;
  }

  static bool _checkAttendanceEligibility(
    double attendance,
    EligibilityCriteria criteria,
  ) {
    if (criteria.minAttendance <= 0) return true;
    return attendance >= criteria.minAttendance;
  }
}
