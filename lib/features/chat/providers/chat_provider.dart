import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_logger.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/record_repository.dart';
import '../../memory/services/memory_service.dart';
import '../../workbench/models/workbench_tool.dart';
import '../../workbench/tools/tool_executor.dart';
import '../models/chat_conversation.dart' show ChatConversationModel, ConversationType;
import '../models/chat_message.dart' show ChatMessageModel, MessageRole, MessageStatus;
import '../services/chat_service.dart';

// 当前活跃会话ID
final activeConversationIdProvider = StateProvider<String?>((ref) => null);

/// 从数据库 attachments 字段中分离图片路径、音频路径与普通附件。
/// 约定：以 `img:` 前缀存储的项为图片路径，以 `audio:` 前缀存储的项为音频路径。
/// 返回 (attachmentsWithoutMedia, imagePaths, audioPath)。
(List<String>, List<String>, String?) _splitAttachments(List<String> raw) {
  final attachments = <String>[];
  final images = <String>[];
  String? audioPath;
  for (final item in raw) {
    if (item.startsWith('img:')) {
      images.add(item.substring(4));
    } else if (item.startsWith('audio:')) {
      audioPath = item.substring(6);
    } else {
      attachments.add(item);
    }
  }
  return (attachments, images, audioPath);
}

/// 解码数据库 attachments JSON 字段为字符串列表。
List<String> _decodeAttachments(String json) {
  if (json.isEmpty) return const [];
  try {
    return (jsonDecode(json) as List<dynamic>).cast<String>();
  } catch (_) {
    return const [];
  }
}

// 是否正在输入中
final isTypingProvider = StateProvider<bool>((ref) => false);

// 联网搜索开关状态
final webSearchEnabledProvider = StateProvider<bool>((ref) => false);

// 当前流式响应文本
final streamingResponseProvider = StateProvider<String>((ref) => '');

// 会话列表 Provider
final chatConversationsProvider = AsyncNotifierProvider<ChatConversationsNotifier, List<ChatConversationModel>>(() {
  return ChatConversationsNotifier();
});

class ChatConversationsNotifier extends AsyncNotifier<List<ChatConversationModel>> {
  @override
  Future<List<ChatConversationModel>> build() async {
    final db = ref.read(appDatabaseProvider);
    final dbConversations = await db.getAllConversations();
    return dbConversations.map((c) => ChatConversationModel(
      id: c.id,
      title: c.title,
      systemPrompt: c.systemPrompt,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
      messageCount: c.messageCount,
      isPinned: c.isPinned,
      aiProvider: c.aiProvider,
      model: c.model,
      sourceRecordId: c.sourceRecordId,
      type: ConversationType.values.firstWhere(
        (e) => e.name == c.type,
        orElse: () => ConversationType.general,
      ),
    )).toList();
  }

  Future<String> createConversation({
    String? title,
    String? systemPrompt,
    int? sourceRecordId,
    ConversationType type = ConversationType.general,
    String? aiProvider,
    String? model,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final conversation = ChatConversationModel.create(
      title: title,
      systemPrompt: systemPrompt,
      sourceRecordId: sourceRecordId,
      type: type,
      aiProvider: aiProvider,
      model: model,
    );

    await db.insertConversation(ChatConversationsCompanion(
      id: Value(conversation.id),
      title: Value(conversation.title),
      systemPrompt: Value(conversation.systemPrompt),
      createdAt: Value(conversation.createdAt),
      updatedAt: Value(conversation.updatedAt),
      messageCount: Value(conversation.messageCount),
      isPinned: Value(conversation.isPinned),
      aiProvider: Value(conversation.aiProvider),
      model: Value(conversation.model),
      sourceRecordId: Value(conversation.sourceRecordId),
      type: Value(conversation.type.name),
    ));
    ref.invalidateSelf();
    return conversation.id;
  }

  Future<void> deleteConversation(String id) async {
    final db = ref.read(appDatabaseProvider);
    await db.deleteConversation(id);
    await db.deleteMessagesByConversationId(id);
    ref.invalidateSelf();
  }

  Future<void> pinConversation(String id, bool isPinned) async {
    final db = ref.read(appDatabaseProvider);
    await db.updateConversationPin(id, isPinned);
    ref.invalidateSelf();
  }

  Future<void> updateConversationTitle(String id, String title) async {
    final db = ref.read(appDatabaseProvider);
    await db.updateConversationTitle(id, title);
    ref.invalidateSelf();
  }

  Future<void> updateConversationSystemPrompt(String id, String? systemPrompt) async {
    final db = ref.read(appDatabaseProvider);
    await db.updateConversationSystemPrompt(id, systemPrompt);
    ref.invalidateSelf();
  }

  Future<void> updateMessageCount(String id, int count) async {
    final db = ref.read(appDatabaseProvider);
    await db.updateConversationMessageCount(id, count);
    ref.invalidateSelf();
  }
}

// 消息列表 Provider（按会话ID）
final chatMessagesProvider = StreamProvider.family<List<ChatMessageModel>, String>((ref, conversationId) {
  final db = ref.read(appDatabaseProvider);
  return db.watchMessagesByConversationId(conversationId).map((messages) =>
    messages.map((m) {
      final raw = _decodeAttachments(m.attachments);
      final (attachments, imagePaths, audioPath) = _splitAttachments(raw);
      return ChatMessageModel(
        id: m.id,
        conversationId: m.conversationId,
        role: MessageRole.values.firstWhere(
          (e) => e.name == m.role,
          orElse: () => MessageRole.user,
        ),
        content: m.content,
        status: MessageStatus.values.firstWhere(
          (e) => e.name == m.status,
          orElse: () => MessageStatus.sent,
        ),
        createdAt: m.createdAt,
        model: m.model,
        tokensUsed: m.tokensUsed,
        attachments: attachments,
        imagePaths: imagePaths,
        audioPath: audioPath,
        sourceRecordId: m.sourceRecordId,
        contextSnapshot: m.contextSnapshot,
      );
    }).toList()
  );
});

// 发送消息 Notifier
final sendMessageProvider = StateNotifierProvider<SendMessageNotifier, AsyncValue<void>>((ref) {
  return SendMessageNotifier(ref);
});

class SendMessageNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  StreamSubscription<String>? _streamSubscription;

  SendMessageNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> sendMessage({
    required String conversationId,
    required String content,
    int? sourceRecordId,
    String? contextSnapshot,
    List<String> imagePaths = const [],
    String? audioPath,
    String? agentSystemPrompt,
    String? skillSystemPrompt,
    WorkbenchTool? selectedSkill,
  }) async {
    state = const AsyncValue.loading();
    final enableSearch = _ref.read(webSearchEnabledProvider);
    AppLogger().i('ChatProvider', '▶ sendMessage 开始 conv=$conversationId contentLen=${content.length} imgCount=${imagePaths.length} enableSearch=$enableSearch');

    try {
      final db = _ref.read(appDatabaseProvider);
      final chatService = _ref.read(chatServiceProvider);
      final memoryService = _ref.read(memoryServiceProvider);

      // 1. 保存用户消息（图片路径用 img: 前缀、音频路径用 audio: 前缀存储在 attachments 中持久化）
      final userMessage = ChatMessageModel.createUserMessage(
        conversationId: conversationId,
        content: content,
        sourceRecordId: sourceRecordId,
        contextSnapshot: contextSnapshot,
        imagePaths: imagePaths,
        audioPath: audioPath,
      );
      // 将图片/音频路径用前缀编码到 attachments 中持久化（避免数据库迁移）
      final combinedAttachments = <String>[
        ...userMessage.attachments,
        ...imagePaths.map((p) => 'img:$p'),
        if (audioPath != null) 'audio:$audioPath',
      ];
      await db.insertMessage(ChatMessagesCompanion(
        id: Value(userMessage.id),
        conversationId: Value(userMessage.conversationId),
        role: Value(userMessage.role.name),
        content: Value(userMessage.content),
        status: Value(userMessage.status.name),
        createdAt: Value(userMessage.createdAt),
        model: Value(userMessage.model),
        tokensUsed: Value(userMessage.tokensUsed),
        attachments: Value(jsonEncode(combinedAttachments)),
        sourceRecordId: Value(userMessage.sourceRecordId),
        contextSnapshot: Value(userMessage.contextSnapshot),
      ));

      // 2. 获取历史消息并转换为 ChatMessageModel
      final dbMessages = await db.getMessagesByConversationId(conversationId);
      final history = dbMessages.map((m) {
        final raw = _decodeAttachments(m.attachments);
        final (attachments, imagePaths, audioPath) = _splitAttachments(raw);
        return ChatMessageModel(
          id: m.id,
          conversationId: m.conversationId,
          role: MessageRole.values.firstWhere(
            (e) => e.name == m.role,
            orElse: () => MessageRole.user,
          ),
          content: m.content,
          status: MessageStatus.values.firstWhere(
            (e) => e.name == m.status,
            orElse: () => MessageStatus.sent,
          ),
          createdAt: m.createdAt,
          model: m.model,
          tokensUsed: m.tokensUsed,
          attachments: attachments,
          imagePaths: imagePaths,
          audioPath: audioPath,
          sourceRecordId: m.sourceRecordId,
          contextSnapshot: m.contextSnapshot,
        );
      }).toList();

      // 3. 获取会话配置
      final conversation = await db.getConversation(conversationId);
      final systemPrompt = conversation?.systemPrompt;

      // 4. SKILL 多步执行分支
      if (selectedSkill != null && selectedSkill.steps.isNotEmpty) {
        AppLogger().i('ChatProvider', '▶ 检测到 SKILL 调用 skillId=${selectedSkill.id} name=${selectedSkill.name} steps=${selectedSkill.steps.length}');
        _ref.read(isTypingProvider.notifier).state = true;
        _ref.read(streamingResponseProvider.notifier).state = '准备执行 SKILL：${selectedSkill.name}';

        final assistantMessage = ChatMessageModel.createAssistantMessage(
          conversationId: conversationId,
          content: '',
          model: conversation?.model,
        );
        final streamingMessage = assistantMessage.copyWith(status: MessageStatus.streaming);
        await db.insertMessage(ChatMessagesCompanion(
          id: Value(streamingMessage.id),
          conversationId: Value(streamingMessage.conversationId),
          role: Value(streamingMessage.role.name),
          content: Value(streamingMessage.content),
          status: Value(streamingMessage.status.name),
          createdAt: Value(streamingMessage.createdAt),
          model: Value(streamingMessage.model),
          tokensUsed: Value(streamingMessage.tokensUsed),
          attachments: Value(jsonEncode(streamingMessage.attachments)),
          sourceRecordId: Value(streamingMessage.sourceRecordId),
          contextSnapshot: Value(streamingMessage.contextSnapshot),
        ));

        try {
          final toolExecutor = _ref.read(toolExecutorProvider);
          final config = selectedSkill.toToolConfig();
          final result = await toolExecutor.execute(
            input: content,
            config: config,
            onProgress: (current, total, name) {
              final progress = '步骤 $current/$total：$name';
              AppLogger().i('ChatProvider', '  SKILL 进度 $progress');
              _ref.read(streamingResponseProvider.notifier).state = progress;
            },
          );

          _ref.read(isTypingProvider.notifier).state = false;
          _ref.read(streamingResponseProvider.notifier).state = result;
          await db.updateMessageContent(assistantMessage.id, result, MessageStatus.sent.name);
          AppLogger().i('ChatProvider', '◀ SKILL 执行完成 outputLen=${result.length}');
        } catch (e, stack) {
          AppLogger().e('ChatProvider', '✗ SKILL 执行失败: $e');
          _ref.read(isTypingProvider.notifier).state = false;
          _ref.read(streamingResponseProvider.notifier).state = '';
          await db.updateMessageContent(assistantMessage.id, 'SKILL 执行失败：$e', MessageStatus.error.name);
          state = AsyncValue.error(e, stack);
          return;
        }

        // SKILL 完成后统一收尾
        final allDbMessages = await db.getMessagesByConversationId(conversationId);
        await db.updateConversationMessageCount(conversationId, allDbMessages.length);
        await db.updateConversationUpdatedAt(conversationId, DateTime.now());

        try {
          final allMessages = allDbMessages.map((m) {
            final raw = _decodeAttachments(m.attachments);
            final (attachments, imagePaths, audioPath) = _splitAttachments(raw);
            return ChatMessageModel(
              id: m.id,
              conversationId: m.conversationId,
              role: MessageRole.values.firstWhere(
                (e) => e.name == m.role,
                orElse: () => MessageRole.user,
              ),
              content: m.content,
              status: MessageStatus.values.firstWhere(
                (e) => e.name == m.status,
                orElse: () => MessageStatus.sent,
              ),
              createdAt: m.createdAt,
              model: m.model,
              tokensUsed: m.tokensUsed,
              attachments: attachments,
              imagePaths: imagePaths,
              audioPath: audioPath,
              sourceRecordId: m.sourceRecordId,
              contextSnapshot: m.contextSnapshot,
            );
          }).toList();
          memoryService.buildShortTermMemoryFromMessages(conversationId, allMessages);

          final assistantContent = allDbMessages
              .lastWhere((m) => m.role == MessageRole.assistant.name)
              .content;
          await memoryService.extractAndSaveFact(conversationId, assistantContent);
        } catch (e) {
          AppLogger().w('ChatProvider', 'Memory extraction failed: $e');
        }

        state = const AsyncValue.data(null);
        return;
      }

      // 5. 设置输入中状态
      _ref.read(isTypingProvider.notifier).state = true;
      _ref.read(streamingResponseProvider.notifier).state = '';

      // 6. 创建 assistant 消息占位
      final assistantMessage = ChatMessageModel.createAssistantMessage(
        conversationId: conversationId,
        content: '',
        model: conversation?.model,
      );
      final streamingMessage = assistantMessage.copyWith(status: MessageStatus.streaming);
      await db.insertMessage(ChatMessagesCompanion(
        id: Value(streamingMessage.id),
        conversationId: Value(streamingMessage.conversationId),
        role: Value(streamingMessage.role.name),
        content: Value(streamingMessage.content),
        status: Value(streamingMessage.status.name),
        createdAt: Value(streamingMessage.createdAt),
        model: Value(streamingMessage.model),
        tokensUsed: Value(streamingMessage.tokensUsed),
        attachments: Value(jsonEncode(streamingMessage.attachments)),
        sourceRecordId: Value(streamingMessage.sourceRecordId),
        contextSnapshot: Value(streamingMessage.contextSnapshot),
      ));

      // 7. 流式接收响应（传入图片路径支持多模态）
      final buffer = StringBuffer();
      _streamSubscription?.cancel();
      _streamSubscription = chatService.sendMessageStream(
        conversationId: conversationId,
        userMessage: content,
        history: history,
        systemPrompt: systemPrompt,
        agentSystemPrompt: agentSystemPrompt,
        skillSystemPrompt: skillSystemPrompt,
        sourceRecordId: sourceRecordId,
        contextSnapshot: contextSnapshot,
        imagePaths: imagePaths,
        enableSearch: enableSearch,
      ).listen(
        (chunk) {
          buffer.write(chunk);
          _ref.read(streamingResponseProvider.notifier).state = buffer.toString();
        },
        onError: (error, stackTrace) {
          AppLogger().e('ChatProvider', '✗ 流式响应错误: $error');
          _ref.read(isTypingProvider.notifier).state = false;
          // 更新消息为错误状态（保留已收到的内容）
          db.updateMessageContent(assistantMessage.id, buffer.toString(), MessageStatus.error.name);
          state = AsyncValue.error(error, stackTrace ?? StackTrace.current);
        },
        onDone: () async {
          _ref.read(isTypingProvider.notifier).state = false;
          final finalContent = buffer.toString();
          AppLogger().i('ChatProvider', '◀ sendMessage 流结束 contentLen=${finalContent.length}');

          // 更新 assistant 消息
          await db.updateMessageContent(assistantMessage.id, finalContent, MessageStatus.sent.name);

          // 更新会话消息数和标题
          final allDbMessages = await db.getMessagesByConversationId(conversationId);
          await db.updateConversationMessageCount(conversationId, allDbMessages.length);
          await db.updateConversationUpdatedAt(conversationId, DateTime.now());

          // 构建消息模型列表（用于标题生成与短期记忆）
          final allMessages = allDbMessages.map((m) {
            final raw = _decodeAttachments(m.attachments);
            final (attachments, imagePaths, audioPath) = _splitAttachments(raw);
            return ChatMessageModel(
              id: m.id,
              conversationId: m.conversationId,
              role: MessageRole.values.firstWhere(
                (e) => e.name == m.role,
                orElse: () => MessageRole.user,
              ),
              content: m.content,
              status: MessageStatus.values.firstWhere(
                (e) => e.name == m.status,
                orElse: () => MessageStatus.sent,
              ),
              createdAt: m.createdAt,
              model: m.model,
              tokensUsed: m.tokensUsed,
              attachments: attachments,
              imagePaths: imagePaths,
              audioPath: audioPath,
              sourceRecordId: m.sourceRecordId,
              contextSnapshot: m.contextSnapshot,
            );
          }).toList();

          // 更新短期记忆（与当前对话绑定）
          memoryService.buildShortTermMemoryFromMessages(conversationId, allMessages);

          // 如果是第一条回复，生成标题
          if (allDbMessages.length <= 2 && (conversation?.title == '新对话' || conversation?.title == null)) {
            final title = await chatService.generateTitle(allMessages);
            await db.updateConversationTitle(conversationId, title);
            _ref.read(chatConversationsProvider.notifier).updateConversationTitle(conversationId, title);
          }

          // 提取长期记忆事实
          try {
            await memoryService.extractAndSaveFact(conversationId, finalContent);
          } catch (e) {
            AppLogger().w('ChatProvider', 'Memory extraction failed: $e');
          }

          state = const AsyncValue.data(null);
        },
      );
    } catch (e, stack) {
      AppLogger().e('ChatProvider', '✗ sendMessage 异常: $e');
      _ref.read(isTypingProvider.notifier).state = false;
      state = AsyncValue.error(e, stack);
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

// 从记录创建对话 Provider
final createConversationFromRecordProvider = Provider<Future<String> Function({
  required int recordId,
  required String recordContent,
  String? systemPrompt,
  String? initialMessage,
})>((ref) {
  return ({
    required int recordId,
    required String recordContent,
    String? systemPrompt,
    String? initialMessage,
  }) async {
    final db = ref.read(appDatabaseProvider);

    // 创建会话
    final conversationId = await ref.read(chatConversationsProvider.notifier).createConversation(
      title: '记录分析',
      systemPrompt: systemPrompt,
      sourceRecordId: recordId,
      type: ConversationType.recordAnalysis,
    );

    // 添加上下文系统消息
    final contextMessage = ChatMessageModel.createSystemMessage(
      conversationId: conversationId,
      content: '以下是对话关联的记录内容：\n\n$recordContent',
    );
    await db.insertMessage(ChatMessagesCompanion(
      id: Value(contextMessage.id),
      conversationId: Value(contextMessage.conversationId),
      role: Value(contextMessage.role.name),
      content: Value(contextMessage.content),
      status: Value(contextMessage.status.name),
      createdAt: Value(contextMessage.createdAt),
      model: Value(contextMessage.model),
      tokensUsed: Value(contextMessage.tokensUsed),
      attachments: Value(jsonEncode(contextMessage.attachments)),
      sourceRecordId: Value(contextMessage.sourceRecordId),
      contextSnapshot: Value(contextMessage.contextSnapshot),
    ));

    // 如果有初始消息，发送
    if (initialMessage != null && initialMessage.isNotEmpty) {
      await ref.read(sendMessageProvider.notifier).sendMessage(
        conversationId: conversationId,
        content: initialMessage,
        sourceRecordId: recordId,
        contextSnapshot: recordContent,
      );
    }

    return conversationId;
  };
});
