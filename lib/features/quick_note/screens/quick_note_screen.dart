import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/expandable_text_field.dart';
import '../../../core/widgets/tag_selector.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../records/providers/record_provider.dart';
import '../providers/quick_note_provider.dart';

class QuickNoteScreen extends ConsumerStatefulWidget {
  const QuickNoteScreen({super.key});

  @override
  ConsumerState<QuickNoteScreen> createState() => _QuickNoteScreenState();
}

class _QuickNoteScreenState extends ConsumerState<QuickNoteScreen> {
  final _contentController = TextEditingController();
  final List<String> _tags = [];
  late AppLocalizations _l10n;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final content = _contentController.text;
    if (content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.pleaseEnterContent)),
      );
      return;
    }

    try {
      await ref.read(quickNoteProvider.notifier).saveNote(content, _tags);

      // 刷新首页列表
      ref.invalidate(paginatedRecordsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l10n.quickNoteSaved),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_l10n.saveFailed}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _l10n = AppLocalizations.of(context)!;
    final quickNoteAsync = ref.watch(quickNoteProvider);

    final isSaving = quickNoteAsync.when(
      data: (state) => state.isSaving,
      loading: () => true,
      error: (_, __) => false,
    );

    final error = quickNoteAsync.when(
      data: (state) => state.error,
      loading: () => null,
      error: (e, _) => e.toString(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_l10n.quickNote),
        actions: [
          TextButton.icon(
            onPressed: isSaving ? null : _saveNote,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: Text(
              isSaving ? _l10n.saving : _l10n.saveButton,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ExpandableTextField(
                controller: _contentController,
                hintText: _l10n.inputYourThoughts,
                minLines: 10,
                maxLines: 50,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _l10n.tags,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TagSelector(
                  selectedTags: _tags,
                  onTagsChanged: (tags) {
                    setState(() {
                      _tags.clear();
                      _tags.addAll(tags);
                    });
                  },
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
