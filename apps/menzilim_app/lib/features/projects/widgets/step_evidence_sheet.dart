import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../models/user_project.dart';

/// Adımın çıktısını girme formu. İki alan: bağlantı ve kısa not; ikisi de
/// boş bırakılabilir. Kaydedilirse güncel proje döner.
Future<UserProject?> showStepEvidenceSheet({
  required BuildContext context,
  required UserProjectStep step,
  required Future<UserProject> Function(String? url, String? note) onSave,
}) {
  return showModalBottomSheet<UserProject>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _StepEvidenceSheet(step: step, onSave: onSave),
  );
}

class _StepEvidenceSheet extends StatefulWidget {
  final UserProjectStep step;
  final Future<UserProject> Function(String? url, String? note) onSave;

  const _StepEvidenceSheet({required this.step, required this.onSave});

  @override
  State<_StepEvidenceSheet> createState() => _StepEvidenceSheetState();
}

class _StepEvidenceSheetState extends State<_StepEvidenceSheet> {
  late final TextEditingController _urlController =
      TextEditingController(text: widget.step.evidenceUrl ?? '');

  late final TextEditingController _noteController =
      TextEditingController(text: widget.step.note ?? '');

  bool _isSaving = false;
  String? _urlError;

  @override
  void dispose() {
    _urlController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Sunucuyla aynı kural: boş olabilir, doluysa mutlak http/https.
  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);

    return uri != null &&
        uri.isAbsolute &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> _submit() async {
    final url = _urlController.text.trim();
    final note = _noteController.text.trim();

    if (url.isNotEmpty && !_isValidUrl(url)) {
      setState(() {
        _urlError = context.l10n.evidenceInvalidUrl;
      });

      return;
    }

    setState(() {
      _isSaving = true;
      _urlError = null;
    });

    try {
      final updated = await widget.onSave(
        url.isEmpty ? null : url,
        note.isEmpty ? null : note,
      );

      if (!mounted) return;

      Navigator.of(context).pop(updated);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.evidenceSaveError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.evidenceTitle, style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.evidenceSubtitle,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.evidenceUrlLabel,
              style: context.textStyles.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: l10n.evidenceUrlHint,
                errorText: _urlError,
                prefixIcon: const Icon(Icons.link),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.evidenceNoteLabel,
              style: context.textStyles.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(hintText: l10n.evidenceNoteHint),
            ),
            const SizedBox(height: AppSpacing.xl),
            MenzilimButton(
              label: l10n.evidenceSave,
              icon: Icons.check,
              isLoading: _isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
