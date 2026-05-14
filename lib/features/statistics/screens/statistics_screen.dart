import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/stats_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/stats_charts.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';

final realTimeStatsProvider = FutureProvider<UsageStats>((ref) async {
  final repository = ref.watch(recordRepositoryProvider);
  final records = await repository.getAllRecords();

  int audioCount = 0;
  int ocrCount = 0;
  int textCount = 0;
  int successCount = 0;
  int failedCount = 0;
  int favoriteCount = 0;
  int totalTags = 0;
  Map<String, int> recordsPerDay = {};
  Map<String, int> tagsFrequency = {};

  DateTime? firstDate;
  DateTime? lastDate;
  Set<String> usedDays = {};

  for (final record in records) {
    if (record.type == RecordType.audio) audioCount++;
    if (record.type == RecordType.ocr) ocrCount++;
    if (record.type == RecordType.text) textCount++;
    if (record.transcriptionStatus == TranscriptionStatus.success)
      successCount++;
    if (record.transcriptionStatus == TranscriptionStatus.failed) failedCount++;
    if (record.isFavorite) favoriteCount++;
    totalTags += record.tags.length;

    for (final tag in record.tags) {
      tagsFrequency[tag] = (tagsFrequency[tag] ?? 0) + 1;
    }

    final dateKey =
        '${record.createdAt.year}-${record.createdAt.month.toString().padLeft(2, '0')}-${record.createdAt.day.toString().padLeft(2, '0')}';
    recordsPerDay[dateKey] = (recordsPerDay[dateKey] ?? 0) + 1;

    usedDays.add(dateKey);

    if (firstDate == null || record.createdAt.isBefore(firstDate)) {
      firstDate = record.createdAt;
    }
    if (lastDate == null || record.createdAt.isAfter(lastDate)) {
      lastDate = record.createdAt;
    }
  }

  return UsageStats(
    totalRecords: records.length,
    audioRecords: audioCount,
    ocrRecords: ocrCount,
    successfulTranscriptions: successCount,
    failedTranscriptions: failedCount,
    favoriteRecords: favoriteCount,
    totalTags: totalTags,
    firstUseDate: firstDate ?? DateTime.now(),
    lastUseDate: lastDate ?? DateTime.now(),
    daysUsed: usedDays.length,
    recordsPerDay: recordsPerDay,
    tagsFrequency: tagsFrequency,
  );
});

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(realTimeStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据统计'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: statsAsync.when(
        data: (stats) => StatsChart(stats: stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('加载统计失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(realTimeStatsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
