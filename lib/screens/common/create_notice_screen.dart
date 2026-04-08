import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../theme/premium_theme.dart';
import '../../widgets/premium_widgets.dart';

class CreateNoticeScreen extends StatefulWidget {
  const CreateNoticeScreen({super.key});

  @override
  State<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends State<CreateNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _linkController = TextEditingController();
  bool _isPinned = false;
  String _priority = 'Low';
  String _type = 'General';
  bool _isLoading = false;

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];
  final List<String> _types = ['General', 'Holiday', 'Urgent'];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submitNotice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final firestoreService = context.read<FirestoreService>();
      final user = authService.currentUser;

      if (user == null) throw Exception('User not logged in');

      final userData = await authService.getUserData(user.uid);
      final postedByName = userData != null
          ? (userData.email.split('@').first)
          : 'Staff';

      String noticeType = _type.toLowerCase();
      if (_priority == 'Urgent') {
        noticeType = 'urgent';
      }

      await firestoreService.createNotice(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        postedBy: user.uid,
        postedByName: postedByName,
        type: noticeType,
        isPinned: _isPinned,
        priority: _priority,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notice posted successfully!'),
            backgroundColor: PremiumTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: PremiumTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Theme(
      data: PremiumTheme.lightTheme,
      child: Scaffold(
        backgroundColor: PremiumTheme.background,
        appBar: AppBar(
          title: Text(
            'Post New Notice',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: PremiumTheme.textPrimary,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: PremiumTheme.textPrimary,
                size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Notice Details'),
                const SizedBox(height: 16),

                NeoGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TechInput(
                        controller: _titleController,
                        label: 'Notice Title',
                        icon: Icons.title_rounded,
                        validator: (v) =>
                            v?.isNotEmpty == true ? null : 'Required',
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Type',
                              value: _type,
                              items: _types,
                              onChanged: (val) => setState(() => _type = val!),
                              icon: Icons.category_rounded,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Priority',
                              value: _priority,
                              items: _priorities,
                              onChanged: (val) =>
                                  setState(() => _priority = val!),
                              icon: Icons.flag_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      TechInput(
                        controller: _contentController,
                        label: 'Content',
                        icon: Icons.description_outlined,
                        validator: (v) =>
                            v?.isNotEmpty == true ? null : 'Required',
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 24),

                NeoGlassCard(
                  padding: const EdgeInsets.all(20),
                  child: SwitchListTile(
                    value: _isPinned,
                    onChanged: (val) => setState(() => _isPinned = val),
                    title: Text(
                      'Pin to Dashboard',
                      style: GoogleFonts.plusJakartaSans(
                        color: PremiumTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Keep this notice at the top of the list',
                      style: GoogleFonts.inter(
                        color: PremiumTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    thumbColor: WidgetStateProperty.all(PremiumTheme.primary),
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isPinned
                            ? PremiumTheme.primary.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.push_pin_rounded,
                        color: _isPinned ? PremiumTheme.primary : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 100.milliseconds).slideY(begin: 0.1),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: FutureButton(
                    text: 'Post Notice',
                    onPressed: _submitNotice,
                    isLoading: _isLoading,
                    icon: Icons.send_rounded,
                  ),
                ).animate().fadeIn(delay: 200.milliseconds).slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: PremiumTheme.primary,
        letterSpacing: 1.5,
      ),
    ).animate().fadeIn();
  }
 
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: PremiumTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: PremiumTheme.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: PremiumTheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: PremiumTheme.surface,
              style: GoogleFonts.inter(
                color: PremiumTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: PremiumTheme.textSecondary),
              items: items.map((item) {
                Color itemColor = PremiumTheme.textPrimary;
                if (label == 'Priority') {
                  if (item == 'Urgent') itemColor = PremiumTheme.error;
                  if (item == 'High') itemColor = Colors.orange;
                }
                return DropdownMenuItem(
                  value: item,
                  child: Row(
                    children: [
                      if (label == 'Priority') ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: itemColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(item),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
