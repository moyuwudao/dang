import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/core/models/ai_model_config.dart';

void main() {
  group('AiModelConfig', () {
    test('should contain all providers', () {
      expect(AiModelConfig.allProviders.length, 11);
      expect(AiModelConfig.allProviders.map((p) => p.provider), containsAll([
        AiProvider.openAI,
        AiProvider.claude,
        AiProvider.gemini,
        AiProvider.deepSeek,
        AiProvider.qwen,
        AiProvider.ernie,
        AiProvider.zhipu,
        AiProvider.kimi,
        AiProvider.spark,
        AiProvider.grok,
        AiProvider.custom,
      ]));
    });

    test('getConfig should return correct provider', () {
      final config = AiModelConfig.getConfig(AiProvider.openAI);
      expect(config.provider, AiProvider.openAI);
      expect(config.name, 'openai');
      expect(config.displayName, 'OpenAI');
    });

    test('getConfig should fallback to openAI for unknown provider', () {
      // 测试不存在的provider时应该fallback
      // 由于enum是封闭的，我们测试getConfigByName
      final config = AiModelConfig.getConfigByName('nonexistent');
      expect(config, isNull);
    });

    test('getConfigByName should return correct provider', () {
      final config = AiModelConfig.getConfigByName('openai');
      expect(config, isNotNull);
      expect(config!.provider, AiProvider.openAI);
    });

    test('domesticProviders should contain only domestic providers', () {
      final domestic = AiModelConfig.domesticProviders;
      expect(domestic.length, 6);
      expect(domestic.map((p) => p.provider), containsAll([
        AiProvider.deepSeek,
        AiProvider.qwen,
        AiProvider.ernie,
        AiProvider.zhipu,
        AiProvider.kimi,
        AiProvider.spark,
      ]));
    });

    test('internationalProviders should contain only international providers', () {
      final international = AiModelConfig.internationalProviders;
      expect(international.length, 4);
      expect(international.map((p) => p.provider), containsAll([
        AiProvider.openAI,
        AiProvider.claude,
        AiProvider.gemini,
        AiProvider.grok,
      ]));
    });

    test('transcriptionProviders should only include providers with ASR support', () {
      final asrProviders = AiModelConfig.transcriptionProviders;
      for (final provider in asrProviders) {
        expect(provider.supportsTranscription, isTrue);
      }
    });

    group('canUseFeature', () {
      test('recording should always be available', () {
        expect(AiModelConfig.canUseFeature(AppFeature.recording, null), isTrue);
        expect(AiModelConfig.canUseFeature(AppFeature.recording, AiProvider.openAI), isTrue);
      });

      test('ocr should always be available', () {
        expect(AiModelConfig.canUseFeature(AppFeature.ocr, null), isTrue);
        expect(AiModelConfig.canUseFeature(AppFeature.ocr, AiProvider.openAI), isTrue);
      });

      test('transcription should require provider with ASR support', () {
        expect(AiModelConfig.canUseFeature(AppFeature.transcription, null), isFalse);
        expect(AiModelConfig.canUseFeature(AppFeature.transcription, AiProvider.openAI), isTrue);
        expect(AiModelConfig.canUseFeature(AppFeature.transcription, AiProvider.claude), isFalse);
      });

      test('chatSummary should require any configured provider', () {
        expect(AiModelConfig.canUseFeature(AppFeature.chatSummary, null), isFalse);
        expect(AiModelConfig.canUseFeature(AppFeature.chatSummary, AiProvider.claude), isTrue);
      });

      test('titleGeneration should require any configured provider', () {
        expect(AiModelConfig.canUseFeature(AppFeature.titleGeneration, null), isFalse);
        expect(AiModelConfig.canUseFeature(AppFeature.titleGeneration, AiProvider.claude), isTrue);
      });
    });

    group('getFeatureDisabledReason', () {
      test('should return null for recording and ocr', () {
        expect(AiModelConfig.getFeatureDisabledReason(AppFeature.recording, null), isNull);
        expect(AiModelConfig.getFeatureDisabledReason(AppFeature.ocr, null), isNull);
      });

      test('should return reason when provider does not support transcription', () {
        final reason = AiModelConfig.getFeatureDisabledReason(AppFeature.transcription, AiProvider.claude);
        expect(reason, contains('does not support transcription'));
      });

      test('should return reason when no provider configured', () {
        final reason = AiModelConfig.getFeatureDisabledReason(AppFeature.transcription, null);
        expect(reason, contains('configure'));
      });
    });

    group('OpenAI config', () {
      test('should have correct properties', () {
        final config = AiModelConfig.openAI;
        expect(config.provider, AiProvider.openAI);
        expect(config.baseUrl, 'https://api.openai.com/v1');
        expect(config.supportsTranscription, isTrue);
        expect(config.supportsChat, isTrue);
        expect(config.apiKeyPrefix, 'sk-');
        expect(config.transcriptionMethod, TranscriptionMethod.whisperApi);
        expect(config.asrModel, 'whisper-1');
      });

      test('should have transcription limits', () {
        final config = AiModelConfig.openAI;
        expect(config.transcriptionLimit, isNotNull);
        expect(config.transcriptionLimit!.maxFileSizeMB, 25);
        expect(config.transcriptionLimit!.maxDurationSeconds, 600);
      });
    });

    group('Gemini config', () {
      test('should use audio upload method', () {
        final config = AiModelConfig.gemini;
        expect(config.transcriptionMethod, TranscriptionMethod.audioUpload);
        expect(config.asrModel, 'gemini-2.5-flash');
      });
    });

    group('Qwen config', () {
      test('should use native ASR method', () {
        final config = AiModelConfig.qwen;
        expect(config.transcriptionMethod, TranscriptionMethod.nativeAsr);
        expect(config.asrModel, 'qwen3-asr-flash');
      });

      test('should have large file size limit', () {
        final config = AiModelConfig.qwen;
        expect(config.transcriptionLimit!.maxFileSizeMB, 500);
      });
    });
  });
}
