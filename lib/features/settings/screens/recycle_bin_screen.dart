import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class RecycleBinScreen extends ConsumerStatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  ConsumerState<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends ConsumerState<RecycleBinScreen> {
  List<RecycledRecord> _deletedNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedNotes();
  }

  Future<void> _loadDeletedNotes() async {
    final notes = await StorageServiceRecycleBin.getRecycleBinItems();
    setState(() {
      _deletedNotes = notes;
      _isLoading = false;
    });
  }

  Future<void> _restoreNote(RecycledRecord note) async {
    final l10n = AppLocalizations.of(context)!;
    await StorageServiceRecycleBin.restoreFromRecycleBin(note.originalId);
    await _loadDeletedNotes();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.restoreSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _permanentlyDelete(RecycledRecord note) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmPermanentDelete),
        content: Text(l10n.permanentDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await StorageServiceRecycleBin.permanentDeleteFromRecycleBin(note.originalId);
    await _loadDeletedNotes();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.permanentlyDeleted),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _emptyRecycleBin() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.emptyRecycleBin),
        content: Text(l10n.emptyRecycleBinMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(l10n.emptyRecycleBin),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await StorageServiceRecycleBin.clearRecycleBin();
    await _loadDeletedNotes();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.emptyRecycleBinSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recycleBin),
        actions: [
          if (_deletedNotes.isNotEmpty)
            TextButton(
              onPressed: _emptyRecycleBin,
              child: Text(
                l10n.emptyRecycleBin,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deletedNotes.isEmpty
              ? _buildEmptyState()
              : _buildNotesList(),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noDeletedNotes,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.deletedNotesHint,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    final l10n = AppLocalizations.of(context)!;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _deletedNotes.length,
      itemBuilder: (context, index) {
        final note = _deletedNotes[index];
        final deleteDate = note.deletedAt;
        final remainingDays = 7 - DateTime.now().difference(deleteDate).inDays;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.delete, color: AppColors.error),
            title: Text(
              _getNoteTitle(note),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getNoteContent(note),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.deletedAt}: ${DateFormat('yyyy-MM-dd HH:mm').format(deleteDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (remainingDays > 0)
                  Text(
                    l10n.remainingDays(remainingDays),
                    style: TextStyle(
                      fontSize: 12,
                      color: remainingDays <= 2 ? AppColors.error : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restore, color: AppColors.success),
                  onPressed: () => _restoreNote(note),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: AppColors.error),
                  onPressed: () => _permanentlyDelete(note),
                ),
              ],
            ),
            onTap: () => _showNoteDetail(note),
          ),
        );
      },
    );
  }

  String _getNoteTitle(RecycledRecord note) {
    if (note.content != null && note.content!.isNotEmpty) {
      final lines = note.content!.split('\n');
      if (lines.isNotEmpty && lines.first.isNotEmpty) {
        return lines.first.length > 30 ? '${lines.first.substring(0, 30)}...' : lines.first;
      }
    }
    final l10n = AppLocalizations.of(context)!;
    return l10n.untitledNote;
  }

  String _getNoteContent(RecycledRecord note) {
    if (note.content != null && note.content!.isNotEmpty) {
      final lines = note.content!.split('\n');
      if (lines.length > 1) {
        final content = lines.sublist(1).join('\n').trim();
        if (content.isNotEmpty) {
          return content.length > 50 ? '${content.substring(0, 50)}...' : content;
        }
      }
    }
    if (note.audioPath != null) {
      return '[Audio Record]';
    }
    if (note.imagePath != null) {
      return '[Image Record]';
    }
    final l10n = AppLocalizations.of(context)!;
    return l10n.noContent;
  }

  void _showNoteDetail(RecycledRecord note) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _getNoteTitle(note),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.deletedAt}: ${DateFormat('yyyy-MM-dd HH:mm').format(note.deletedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Text(note.content ?? l10n.noContent),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _restoreNote(note);
                        },
                        icon: const Icon(Icons.restore),
                        label: Text(l10n.restore),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _permanentlyDelete(note);
                        },
                        icon: const Icon(Icons.delete_forever),
                        label: Text(l10n.deleteButton),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
