import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/student_profile.dart';
import '../../theme/premium_theme.dart';

class StudentIDCardScreen extends StatefulWidget {
  final StudentProfile profile;

  const StudentIDCardScreen({super.key, required this.profile});

  @override
  State<StudentIDCardScreen> createState() => _StudentIDCardScreenState();
}

class _StudentIDCardScreenState extends State<StudentIDCardScreen> {
  bool _isRevealed = false;

  void _toggleReveal() {
    setState(() {
      _isRevealed = !_isRevealed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'University Portal ID',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: PremiumTheme.textPrimary,
          ),
        ),
        backgroundColor: const Color.fromARGB(0, 244, 0, 0),
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final rotate = Tween(begin: 3.14 / 2, end: 0.0).animate(animation);
                  return AnimatedBuilder(
                    animation: rotate,
                    child: child,
                    builder: (context, child) {
                      return Transform(
                        transform: Matrix4.rotationY(rotate.value),
                        alignment: Alignment.center,
                        child: child,
                      );
                    },
                  );
                },
                child: _isRevealed
                    ? _buildPhysicalCard(context)
                    : _buildDigitalCard(context),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _toggleReveal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: PremiumTheme.primary,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: PremiumTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isRevealed ? Icons.qr_code : Icons.visibility,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRevealed ? 'Show Digital QR' : 'Scan to Reveal ID',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
              const SizedBox(height: 24),
              Text(
                'Confidential Document • For Campus Use Only',
                style: GoogleFonts.inter(
                  color: const Color.fromARGB(255, 39, 37, 37),
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalCard(BuildContext context) {
    final profile = widget.profile;
    return Container(
      key: const ValueKey('digital'),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340, minHeight: 480),
      decoration: BoxDecoration(
        gradient: PremiumTheme.heroGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: PremiumTheme.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Decorative Path Element (Orange Glow)
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      PremiumTheme.secondary.withValues(alpha: 0.12),
                      PremiumTheme.secondary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            // Decorative Path Element (Green Glow)
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      PremiumTheme.tertiary.withValues(alpha: 0.1),
                      PremiumTheme.tertiary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'XYZ',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'COLLEGE OF ENGG. & TECH.',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.nfc, 
                          color: Colors.white, 
                          size: 24,
                        ).animate(onPlay: (controller) => controller.repeat())
                         .shimmer(duration: 3.seconds, color: PremiumTheme.secondary.withValues(alpha: 0.3)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Profile Image
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      backgroundImage: profile.profilePhoto.isNotEmpty
                          ? CachedNetworkImageProvider(profile.profilePhoto)
                          : null,
                      child: profile.profilePhoto.isEmpty
                          ? Text(
                              profile.name.isNotEmpty
                                  ? profile.name[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.outfit(
                                fontSize: 42,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 20),

                  // Identity
                  Text(
                    profile.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: PremiumTheme.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PremiumTheme.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      profile.studentUID,
                      style: GoogleFonts.inter(
                        color: PremiumTheme.secondaryLight,
                        fontSize: 13,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Data Grid (Glassmorphism)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildVibrantDetailItem(
                          'COURSE / BRANCH',
                          profile.course.isEmpty ? 'N/A' : profile.course.toUpperCase(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                            thickness: 1,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildVibrantDetailItem(
                                'YEAR',
                                'YEAR ${profile.year}',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withValues(alpha: 0.1),
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            Expanded(
                              child: _buildVibrantDetailItem(
                                'SHIFT',
                                profile.shift.toUpperCase(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Small QR at bottom
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: profile.studentUID,
                      version: QrVersions.auto,
                      size: 70,
                      padding: EdgeInsets.zero,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: PremiumTheme.primary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: PremiumTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVibrantDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // --- Side B: Physical Replica ID (Sample Design) ---
  Widget _buildPhysicalCard(BuildContext context) {
    const accentColor = Color(0xFF96724B); // Brownish-gold from the image

    return Container(
      key: const ValueKey('physical'),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 350, minHeight: 520),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Mock Logo
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                    gradient: const RadialGradient(
                      colors: [Color(0xFFF39C12), Color(0xFFD35400)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.school, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'XYZ',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'College of Engg. & Technology',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Brown Accent Bar
          Container(
            height: 14,
            width: double.infinity,
            color: accentColor,
          ),

          // ID Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // UID & Shift Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'UID No. :  ${widget.profile.studentUID}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Shift :  ${widget.profile.shift.toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Profile Image with Black Border
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Container(
                    width: 110,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: widget.profile.profilePhoto.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.profile.profilePhoto,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          )
                        : Icon(Icons.person, size: 60, color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(height: 16),

                // Name (Bold & Large)
                Text(
                  widget.profile.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Detailed Info
                _buildInfoRow('Branch', widget.profile.course.toUpperCase()),
                _buildInfoRow(
                  'Valid from',
                  '${widget.profile.validFrom} to 01.06.${widget.profile.passoutYear}',
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow('Blood Gr.', widget.profile.bloodGroup),
                    ),
                    Expanded(
                      child: _buildInfoRow('DOB', widget.profile.dateOfBirth),
                    ),
                  ],
                ),
                _buildInfoRow('Contact No.', widget.profile.contactNumber),
                
                const SizedBox(height: 24),

                // Signatures removed as per user request
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label : ',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }


}

