import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../services/firestore_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HighPriorityAlertsWidget extends StatelessWidget {
  const HighPriorityAlertsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: context.read<FirestoreService>().getUrgentGrievancesCountStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == 0) {
          // Show a success state when no alerts
          return Container(
            margin: const EdgeInsets.only(bottom: 20, left: 0, right: 0),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2A14B4).withValues(alpha: 0.04), // Soft Indigo Tonal Background
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A14B4).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF2A14B4),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Operational',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: const Color(0xFF0D1C2E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No urgent grievances require attention.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF464554),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
        }

        final count = snapshot.data!;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFBA1A1A).withValues(alpha: 0.06),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // Animated alert icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFBA1A1A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.report_gmailerrorred_rounded,
                  color: Color(0xFFBA1A1A),
                  size: 28,
                ),
              )
                  .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.seconds),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$count Urgent ${count == 1 ? 'Case' : 'Cases'}',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: const Color(0xFF0D1C2E),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _PulseChip(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'High-priority grievances require immediate review.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF464554),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 28,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
      },
    );
  }
}

class _PulseChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFBA1A1A).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFBA1A1A),
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (ctrl) => ctrl.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 1.seconds).fadeOut(),
          const SizedBox(width: 6),
          Text(
            'URGENT',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFBA1A1A),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
