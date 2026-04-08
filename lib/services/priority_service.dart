// Keyword-based grievance priority scorer (FREE - no AI APIs)

import '../models/grievance.dart';
import '../utils/constants.dart';

class PriorityService {
  // Urgency keywords
  static const List<String> urgentKeywords = [
    'urgent',
    'emergency',
    'critical',
    'immediate',
    'asap',
    'help',
    'serious',
    'severe',
    'danger',
    'threat',
  ];

  // High priority keywords
  static const List<String> highPriorityKeywords = [
    'harassment',
    'discrimination',
    'abuse',
    'safety',
    'health',
    'medical',
    'accident',
    'injury',
  ];

  // Negative sentiment keywords
  static const List<String> negativeSentimentKeywords = [
    'terrible',
    'horrible',
    'worst',
    'awful',
    'unacceptable',
    'frustrated',
    'disappointed',
    'angry',
    'upset',
  ];

  // Calculate priority score for a grievance (0-100)
  static int calculatePriorityScore(String category, String description) {
    int score = 0;

    // Base score by category (20 points)
    score += _getCategoryBaseScore(category);

    // Urgency keywords (30 points max)
    score += _checkKeywords(description, urgentKeywords, 30);

    // High priority keywords (30 points max)
    score += _checkKeywords(description, highPriorityKeywords, 30);

    // Negative sentiment (20 points max)
    score += _checkKeywords(description, negativeSentimentKeywords, 20);

    // Cap at 100
    return score > 100 ? 100 : score;
  }

  // Get category-based base score
  static int _getCategoryBaseScore(String category) {
    switch (category) {
      case GrievanceCategory.discrimination:
        return 20; // Highest priority
      case GrievanceCategory.hostel:
        return 15;
      case GrievanceCategory.academic:
        return 10;
      case GrievanceCategory.financial:
        return 10;
      case GrievanceCategory.infrastructure:
        return 5;
      default:
        return 5;
    }
  }

  // Check for keywords and return score contribution
  static int _checkKeywords(String text, List<String> keywords, int maxPoints) {
    final lowerText = text.toLowerCase();
    int matches = 0;

    for (final keyword in keywords) {
      if (lowerText.contains(keyword)) {
        matches++;
      }
    }

    // Each match contributes proportionally to max points
    if (matches == 0) return 0;

    final pointsPerMatch = maxPoints / keywords.length;
    final score = (matches * pointsPerMatch * 2)
        .round(); // Multiply by 2 for weight

    return score > maxPoints ? maxPoints : score;
  }

  // Get priority level string
  static String getPriorityLevel(int score) {
    if (score >= 70) return 'Critical';
    if (score >= 50) return 'High';
    if (score >= 30) return 'Medium';
    return 'Low';
  }

  // Simple sentiment analysis (FREE - keyword based)
  static String analyzeSentiment(String text) {
    final lowerText = text.toLowerCase();

    // Negative keywords
    const negativeKeywords = [
      'bad',
      'terrible',
      'horrible',
      'worst',
      'hate',
      'angry',
      'frustrated',
      'disappointed',
      'poor',
      'awful',
      'unacceptable',
    ];

    // Positive keywords
    const positiveKeywords = [
      'good',
      'great',
      'excellent',
      'happy',
      'satisfied',
      'thank',
      'appreciate',
      'wonderful',
      'amazing',
    ];

    int negativeCount = 0;
    int positiveCount = 0;

    for (final keyword in negativeKeywords) {
      if (lowerText.contains(keyword)) negativeCount++;
    }

    for (final keyword in positiveKeywords) {
      if (lowerText.contains(keyword)) positiveCount++;
    }

    if (negativeCount > positiveCount) return 'Negative';
    if (positiveCount > negativeCount) return 'Positive';
    return 'Neutral';
  }

  // Auto-escalation check
  static bool shouldEscalate(Grievance grievance) {
    // Escalate if:
    // 1. High priority and pending for > 12 hours
    // 2. SLA about to be breached (< 6 hours remaining)
    // 3. Already breached SLA

    if (grievance.isResolved) return false;

    // Check if SLA is breached
    if (grievance.isSLABreached) return true;

    // Check if SLA is critical (< 6 hours)
    final hoursRemaining = grievance.slaDeadline
        .difference(DateTime.now())
        .inHours;
    if (hoursRemaining < 6) return true;

    // Check high priority + pending time
    if (grievance.priorityScore >= 70) {
      final hoursPending = DateTime.now()
          .difference(grievance.submittedAt)
          .inHours;
      if (hoursPending > 12) return true;
    }

    return false;
  }

  // Get escalation reason
  static String getEscalationReason(Grievance grievance) {
    if (grievance.isSLABreached) {
      return 'SLA breached';
    }

    final hoursRemaining = grievance.slaDeadline
        .difference(DateTime.now())
        .inHours;
    if (hoursRemaining < 6) {
      return 'SLA critical (< 6 hours)';
    }

    if (grievance.priorityScore >= 70) {
      final hoursPending = DateTime.now()
          .difference(grievance.submittedAt)
          .inHours;
      if (hoursPending > 12) {
        return 'High priority grievance pending > 12 hours';
      }
    }

    return 'Unknown';
  }

  // Sort grievances by priority (for committee/admin)
  static List<Grievance> sortByPriority(List<Grievance> grievances) {
    return grievances..sort((a, b) {
      // First, sort by escalation need
      final aEscalate = shouldEscalate(a) ? 1 : 0;
      final bEscalate = shouldEscalate(b) ? 1 : 0;
      if (aEscalate != bEscalate) return bEscalate.compareTo(aEscalate);

      // Then by priority score
      final scoreCompare = b.priorityScore.compareTo(a.priorityScore);
      if (scoreCompare != 0) return scoreCompare;

      // Finally by submission date (older first)
      return a.submittedAt.compareTo(b.submittedAt);
    });
  }
}
