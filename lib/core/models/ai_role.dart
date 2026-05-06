class AiRole {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  final bool isBuiltIn;
  final DateTime createdAt;

  const AiRole({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    this.isBuiltIn = false,
    required this.createdAt,
  });

  AiRole copyWith({
    String? id,
    String? name,
    String? description,
    String? systemPrompt,
    bool? isBuiltIn,
    DateTime? createdAt,
  }) {
    return AiRole(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'systemPrompt': systemPrompt,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AiRole.fromJson(Map<String, dynamic> json) {
    return AiRole(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      systemPrompt: json['systemPrompt'] as String,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Built-in roles
  static final List<AiRole> builtInRoles = [
    AiRole(
      id: 'summarizer',
      name: '会议总结',
      description: '提取会议要点、行动项和决策',
      systemPrompt: '你是一位专业的会议记录整理专家。请分析以下会议录音转写文本，提取：\n1. 会议核心议题\n2. 关键决策和结论\n3. 行动项（负责人+截止日期）\n4. 待跟进事项\n\n请用清晰的结构输出，便于后续查阅和执行。',
      isBuiltIn: true,
      createdAt: DateTime(2024, 1, 1),
    ),
    AiRole(
      id: 'idea_polisher',
      name: '想法打磨',
      description: '帮助完善和扩展创意想法',
      systemPrompt: '你是一位创意顾问和产品经理。请分析以下想法/灵感记录，帮助用户：\n1. 梳理核心思路\n2. 补充可能遗漏的角度\n3. 提出可行性建议\n4. 列出下一步可以探索的方向\n\n请保持鼓励性的语气，同时给出实际可行的建议。',
      isBuiltIn: true,
      createdAt: DateTime(2024, 1, 1),
    ),
    AiRole(
      id: 'todo_extractor',
      name: '待办提取',
      description: '从文本中提取待办事项',
      systemPrompt: '你是一位高效的任务管理专家。请从以下文本中提取所有待办事项，并按以下格式输出：\n\n【紧急且重要】\n- [ ] 任务1\n\n【重要不紧急】\n- [ ] 任务2\n\n【紧急不重要】\n- [ ] 任务3\n\n【其他】\n- [ ] 任务4\n\n每个任务请尽量包含：做什么、什么时候做、和谁相关。',
      isBuiltIn: true,
      createdAt: DateTime(2024, 1, 1),
    ),
    AiRole(
      id: 'knowledge_organizer',
      name: '知识整理',
      description: '将零散信息整理成结构化知识',
      systemPrompt: '你是一位知识管理专家。请分析以下文本内容，将其整理成结构化的知识笔记：\n1. 核心概念定义\n2. 关键信息点（用 bullet points）\n3. 逻辑关系和分类\n4. 可以关联的其他知识点\n\n输出格式清晰，便于后续复习和检索。',
      isBuiltIn: true,
      createdAt: DateTime(2024, 1, 1),
    ),
    AiRole(
      id: 'writing_assistant',
      name: '写作助手',
      description: '优化文案、邮件、报告等写作',
      systemPrompt: '你是一位资深文案和商务写作专家。请分析以下文本，帮助用户：\n1. 优化表达，使其更专业、简洁\n2. 检查逻辑是否通顺\n3. 提供不同风格的改写版本（正式/轻松/简洁）\n4. 指出可以补充的内容\n\n如果是邮件，请检查是否有遗漏的要素（主题、称呼、正文、行动项、结尾）。',
      isBuiltIn: true,
      createdAt: DateTime(2024, 1, 1),
    ),
  ];
}
