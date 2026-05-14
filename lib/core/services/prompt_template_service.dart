import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

final promptTemplateServiceProvider =
    Provider((ref) => PromptTemplateService(ref));

class PromptTemplate {
  final String id;
  final String name;
  final String description;
  final String template;
  final String category;
  final bool isBuiltIn;
  final int useCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  PromptTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.template,
    this.category = 'general',
    this.isBuiltIn = false,
    this.useCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  PromptTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? template,
    String? category,
    bool? isBuiltIn,
    int? useCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromptTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      template: template ?? this.template,
      category: category ?? this.category,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      useCount: useCount ?? this.useCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'template': template,
      'category': category,
      'isBuiltIn': isBuiltIn,
      'useCount': useCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PromptTemplate.fromJson(Map<String, dynamic> json) {
    return PromptTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      template: json['template'],
      category: json['category'] ?? 'general',
      isBuiltIn: json['isBuiltIn'] ?? false,
      useCount: json['useCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class PromptTemplateService {
  final Ref ref;
  final List<PromptTemplate> _templates = [];
  bool _initialized = false;
  static const _storageKey = 'custom_prompt_templates';
  static const _useCountKey = 'template_use_counts';

  PromptTemplateService(this.ref);

  Future<void> initialize() async {
    if (_initialized) return;

    _templates.addAll(_getBuiltInTemplates());
    await _loadCustomTemplates();
    await _loadUseCounts();
    _initialized = true;
  }

  Future<void> _loadCustomTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        for (final item in jsonList) {
          final template =
              PromptTemplate.fromJson(item as Map<String, dynamic>);
          if (!_templates.any((t) => t.id == template.id)) {
            _templates.add(template);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveCustomTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customTemplates = _templates.where((t) => !t.isBuiltIn).toList();
      final jsonList = customTemplates.map((t) => t.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> _loadUseCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final countsJson = prefs.getString(_useCountKey);
      if (countsJson != null) {
        final Map<String, dynamic> counts = jsonDecode(countsJson);
        for (int i = 0; i < _templates.length; i++) {
          final count = counts[_templates[i].id];
          if (count != null) {
            _templates[i] = _templates[i].copyWith(useCount: count as int);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveUseCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final counts = <String, int>{};
      for (final t in _templates) {
        if (t.useCount > 0) {
          counts[t.id] = t.useCount;
        }
      }
      await prefs.setString(_useCountKey, jsonEncode(counts));
    } catch (_) {}
  }

  Future<void> incrementUseCount(String templateId) async {
    final index = _templates.indexWhere((t) => t.id == templateId);
    if (index >= 0) {
      _templates[index] = _templates[index].copyWith(
        useCount: _templates[index].useCount + 1,
      );
      await _saveUseCounts();
    }
  }

  List<PromptTemplate> getAllTemplates() {
    return List.unmodifiable(_templates);
  }

  List<PromptTemplate> getTemplatesByCategory(String category) {
    if (category == 'frequently_used') {
      return _templates
          .where((t) => t.useCount > 0)
          .sorted((a, b) => b.useCount.compareTo(a.useCount))
          .toList();
    }
    return _templates.where((t) => t.category == category).toList();
  }

  List<PromptTemplate> getFrequentlyUsedTemplates({int limit = 10}) {
    return _templates
        .where((t) => t.useCount > 0)
        .sorted((a, b) => b.useCount.compareTo(a.useCount))
        .take(limit)
        .toList();
  }

  PromptTemplate? getTemplateById(String id) {
    return _templates.firstWhereOrNull((t) => t.id == id);
  }

  void addTemplate(PromptTemplate template) {
    final existing = _templates.indexWhere((t) => t.id == template.id);
    if (existing >= 0) {
      _templates[existing] = template;
    } else {
      _templates.add(template);
    }
    _saveCustomTemplates();
  }

  void deleteTemplate(String id) {
    _templates.removeWhere((t) => t.id == id && !t.isBuiltIn);
    _saveCustomTemplates();
  }

  void updateTemplate(PromptTemplate template) {
    final existing = _templates.indexWhere((t) => t.id == template.id);
    if (existing >= 0) {
      _templates[existing] = template;
      _saveCustomTemplates();
    }
  }

  Future<String> applyTemplate(String templateId, String content) async {
    final template = getTemplateById(templateId);
    if (template == null) {
      throw Exception('模板不存在');
    }

    await incrementUseCount(templateId);

    final prompt = template.template.replaceAll('{{content}}', content);
    final apiService = ref.read(apiServiceProvider);

    final response = await apiService.chatCompletionWithSystem(
      prompt,
      systemPrompt: prompt,
      toolId: 'prompt_template',
    );

    return response;
  }

  List<String> getCategories() {
    final categories = _templates.map((t) => t.category).toSet().toList();
    if (_templates.any((t) => t.useCount > 0)) {
      categories.insert(0, 'frequently_used');
    }
    return categories;
  }

  List<PromptTemplate> _getBuiltInTemplates() {
    final now = DateTime.now();
    return [
      // ===== 通用 (general) =====
      PromptTemplate(
        id: 'template_business_idea',
        name: '商业构思评估',
        description: '评估商业构思的可行性和潜在价值',
        template: '''你是一位经验丰富的商业顾问。请评估以下商业构思：

{{content}}

请从以下几个方面进行分析：
1. 市场需求：目标用户是谁？需求有多强烈？
2. 竞争分析：是否有类似产品？差异化在哪里？
3. 商业模式：如何盈利？
4. 可行性：技术难度、资金需求、团队要求
5. 建议：是否值得继续深入？改进建议是什么？

请用简洁的语言给出专业评估。''',
        category: 'general',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_retrospective',
        name: '经验复盘框架',
        description: '对项目或事件进行深度复盘总结',
        template: '''请对以下内容进行深度复盘：

{{content}}

请按照以下框架进行分析：
1. 目标回顾：原定目标是什么？是否达成？
2. 成功因素：哪些做法带来了好的结果？
3. 失败原因：哪些地方做得不好？为什么？
4. 经验教训：学到了什么？
5. 改进计划：下一步怎么做？

请给出具体、可执行的建议。''',
        category: 'general',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_meeting_notes',
        name: '会议纪要整理',
        description: '将会议记录整理成清晰的纪要',
        template: '''请整理以下会议记录：

{{content}}

请输出：
1. 会议主题
2. 参会人员
3. 讨论要点（分点列出）
4. 决定事项
5. 待办事项（负责人、截止日期）

请保持简洁明了。''',
        category: 'general',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_creative_writing',
        name: '创意写作助手',
        description: '激发创意，扩展写作思路',
        template: '''请帮助我扩展以下创意：

{{content}}

请提供：
1. 5个扩展方向
2. 每个方向的核心创意点
3. 可能的故事线或场景

请发挥想象力，给出具体的建议。''',
        category: 'general',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_problem_solving',
        name: '问题分析解决',
        description: '系统性分析问题并提供解决方案',
        template: '''请分析以下问题并提供解决方案：

{{content}}

请按照以下步骤分析：
1. 问题定义：问题的本质是什么？
2. 根本原因：问题产生的根本原因是什么？
3. 解决方案：列出3-5个可能的解决方案
4. 方案评估：每个方案的优缺点
5. 推荐方案：最佳选择是什么？

请给出结构化的分析结果。''',
        category: 'general',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_summary',
        name: '内容摘要提取',
        description: '提取长文核心要点',
        template: '''请对以下内容提取核心摘要：

{{content}}

请输出：
1. 一句话总结
2. 3-5个核心要点
3. 关键结论或行动建议

保持简洁，每点不超过30字。''',
        category: 'general',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_action_items',
        name: '行动项提取',
        description: '从记录中提取可执行的行动项',
        template: '''请从以下内容中提取所有行动项：

{{content}}

请按以下格式输出：
| 优先级 | 行动项 | 负责人 | 截止日期 |
|--------|--------|--------|----------|

如果信息不完整，标注"待确认"。''',
        category: 'general',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_qa_generator',
        name: '问答生成器',
        description: '将内容转化为问答形式',
        template: '''请将以下内容转化为问答形式：

{{content}}

请生成：
1. 5个核心问题及答案
2. 每个答案控制在100字以内
3. 问题要有层次，从基础到深入

适合用于FAQ或知识库。''',
        category: 'general',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),

      // ===== 一人公司 (solopreneur) =====
      PromptTemplate(
        id: 'template_customer_debrief',
        name: '客户沟通复盘',
        description: '从客户沟通中提取需求、意向度和跟进计划',
        template: '''你是一位资深的销售顾问。请分析以下客户沟通记录：

{{content}}

请从以下维度进行深度提取：
1. 客户需求：客户明确提到的需求有哪些？隐含的需求是什么？
2. 意向度评估：1-10分，给出评分理由
3. 痛点信号：客户反复提到的问题或不满意的地方
4. 决策人信息：谁是决策者？决策流程是什么？
5. 竞品信息：客户是否提到竞品？对比态度如何？
6. 跟进计划：下次沟通的时间、方式、需要准备的材料
7. 风险信号：可能导致流失的信号有哪些？

请用表格或结构化格式输出，便于后续跟进。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_idea_eval',
        name: '灵感快速评估',
        description: '快速评估一个商业灵感的可行性',
        template: '''你是一位创业导师，擅长快速评估商业灵感。请评估以下灵感：

{{content}}

请用以下格式快速评估：
1. 一句话概括：这个灵感本质上是什么？
2. 目标用户：最可能买单的3类人
3. 市场大小：小众/中等/大众，判断依据
4. 竞品扫描：市面上有类似产品吗？最大竞品是谁？
5. 差异化：与竞品相比，独特之处在哪里？
6. 最小验证：验证这个灵感，最快需要做什么？花多少钱？
7. 致命风险：最可能导致失败的一个原因
8. 推荐行动：如果要做，第一步应该做什么？

请简洁直接，不要废话。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_competitor_analysis',
        name: '竞品分析笔记',
        description: '体验竞品后快速提取对比洞察',
        template: '''你是一位产品战略分析师。请分析以下竞品体验记录：

{{content}}

请从以下维度进行对比分析：
1. 产品定位：竞品的目标用户和核心场景是什么？
2. 核心功能：竞品最重要的3个功能是什么？做得如何？
3. 用户体验：交互设计、视觉风格、操作流畅度评价
4. 定价策略：免费/付费模式，价格区间，转化点在哪？
5. 我方优势：我们做得更好的地方
6. 我方劣势：我们需要补齐的短板
7. 可借鉴点：值得学习的设计或功能（具体描述）
8. 差异化建议：如何与竞品拉开差距？

请给出具体、可操作的结论。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_weekly_report',
        name: '周报生成器',
        description: '从本周记录中自动生成结构化周报',
        template: '''你是一位高效的个人助理。请根据以下本周的工作记录，生成一份结构化的周报：

{{content}}

请按以下格式输出周报：

## 本周成果
- 列出本周完成的主要工作（3-5条）

## 关键数据
- 提取记录中的关键数字：客户数、收入、用户反馈等

## 遇到的问题
- 本周遇到的主要障碍和挑战

## 学到的经验
- 从本周工作中获得的有价值的认知

## 下周计划
- 基于本周情况，下周最重要的3件事是什么？为什么？

## 需要关注的风险
- 可能影响后续进展的风险点

请语言简洁，重点突出，适合发给投资人或合作伙伴。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_finance_quick',
        name: '财务快记整理',
        description: '从收支/报价/合同沟通中提取财务要点',
        template: '''你是一位细心的财务助手。请从以下记录中提取财务相关信息：

{{content}}

请提取并整理：
1. 金额信息：所有提到的金额、币种、含税/不含税
2. 付款条件：付款方式、付款周期、定金比例
3. 到期日：合同到期、付款截止、发票截止等
4. 风险条款：违约金、退款条件、知识产权归属
5. 收支分类：这笔属于收入/支出/投资/退款
6. 待办事项：需要跟进的财务行动（如"开发票"、"催款"等）

如果信息不完整，请明确标注"待确认"。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_product_requirement',
        name: '产品需求提取',
        description: '从用户反馈或需求讨论中提取结构化需求',
        template: '''你是一位经验丰富的产品经理。请从以下内容中提取产品需求：

{{content}}

请按以下格式输出：

## 用户故事
对每个需求，用以下格式描述：
作为[用户角色]，我希望[功能描述]，以便[价值/目的]

## 需求列表
| 编号 | 需求描述 | 优先级 | 来源 | 验收标准 |
|------|---------|--------|------|---------|
| 1 | ... | P0/P1/P2 | 用户A/内部 | ... |

## 需求分类
- 核心需求：必须做的
- 增强需求：做了更好的
- 远期需求：可以以后再考虑的

## 关键假设
- 这些需求基于哪些假设？如何验证？

## 建议的MVP范围
- 如果只做3个需求，应该做哪3个？为什么？''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_supplier_eval',
        name: '供应商评估',
        description: '从供应商沟通中提取评估信息',
        template: '''你是一位采购专家。请根据以下供应商沟通记录进行评估：

{{content}}

请从以下维度评估：
1. 报价分析：报价是否合理？与市场价对比如何？
2. 质量评估：样品/案例质量如何？有无质量保证？
3. 交付能力：交期是否满足？产能是否充足？
4. 服务水平：响应速度、售后政策、配合度
5. 风险评估：是否存在依赖风险？替代方案？
6. 综合评分：价格(1-10) | 质量(1-10) | 交付(1-10) | 服务(1-10)
7. 推荐决策：推荐/有条件推荐/不推荐，理由

请给出客观、有数据支撑的评估。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_interview_notes',
        name: '招聘面试笔记',
        description: '从面试记录中提取候选人评估',
        template: '''你是一位HR顾问。请根据以下面试记录进行候选人评估：

{{content}}

请按以下维度评估：
1. 基本匹配：岗位匹配度(1-10)，理由
2. 专业能力：技术/业务能力评价，亮点和不足
3. 沟通表达：逻辑性、清晰度、主动性
4. 文化匹配：价值观、工作风格是否匹配一人公司节奏
5. 薪资预期：期望薪资、可接受范围
6. 到岗时间：最早可到岗日期
7. 风险点：可能的离职风险、适应风险
8. 推荐决策：强烈推荐/推荐/待定/不推荐

请给出具体评价，避免模糊表述。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_project_retrospective',
        name: '项目复盘',
        description: '项目结束后的深度复盘和经验沉淀',
        template: '''你是一位项目管理顾问。请对以下项目记录进行深度复盘：

{{content}}

请按以下框架输出复盘报告：

## 项目概况
- 项目目标、周期、最终结果

## 做对了什么（继续保持）
- 列出3-5个关键成功做法
- 每个做法为什么有效？

## 做错了什么（避免再犯）
- 列出3-5个关键失误
- 每个失误的根本原因是什么？

## 可复用经验
- 哪些方法/工具/流程可以标准化？
- 建议形成什么SOP？

## 资源盘点
- 积累了哪些可复用资产（文档、模板、代码、人脉）？

## 下一步行动
- 基于复盘，接下来最重要的3个改进行动''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_daily_top3',
        name: '每日三件事',
        description: '从待办和记录中推荐今日最重要的3件事',
        template: '''你是一位高效的个人效率教练。请根据以下今日记录和待办事项，推荐今天最应该做的3件事：

{{content}}

请按以下格式输出：

## 今日Top 3
1. **[最重要的事]** - 为什么今天必须做？不做会怎样？
2. **[第二重要的事]** - 为什么今天应该做？
3. **[第三重要的事]** - 为什么今天可以做？

## 今日避坑指南
- 今天有什么事情看起来紧急但其实不重要？建议推迟

## 今日小胜利
- 有什么5分钟内能完成的事，做了会让自己感觉很好？

## 本周进度
- 基于现有信息，本周目标完成度大约多少？

请考虑：紧急且重要 > 重要不紧急 > 紧急不重要。一人公司的时间最宝贵，不要浪费在低价值事务上。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_content_repurpose',
        name: '内容再利用',
        description: '将录音/笔记转化为多种内容格式',
        template: '''你是一位内容运营专家。请将以下原始内容转化为多种可发布的内容格式：

{{content}}

请输出以下格式：

## 微信朋友圈（100字以内）
一段吸引眼球的朋友圈文案，带2-3个emoji

## 小红书笔记（300字以内）
标题+正文，风格轻松有干货，带话题标签

## 短视频脚本（60秒）
开头hook + 核心观点 + 结尾CTA，标注画面建议

## 知识卡片（1张）
提炼一个最核心的观点，适合做成图片卡片

## 公众号文章大纲
标题 + 3-5个章节标题 + 每章1句话概述

请保持原意，但根据不同平台调整语气和风格。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_pricing_strategy',
        name: '定价策略分析',
        description: '分析定价方案并给出优化建议',
        template: '''你是一位定价策略专家。请分析以下定价相关信息：

{{content}}

请从以下维度分析：
1. 成本结构：固定成本、可变成本、边际成本
2. 竞品定价：市场同类产品价格区间
3. 价值感知：用户愿意支付的价格锚点
4. 定价模型：订阅/一次性/分层/用量计费，哪种最合适？
5. 价格测试：如何验证定价是否合理？
6. 优化建议：具体的价格调整方案

请给出数据驱动的建议。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_legal_review',
        name: '合同要点审查',
        description: '快速提取合同关键条款和风险点',
        template: '''你是一位法律顾问。请审查以下合同或协议相关内容：

{{content}}

请提取并标注：
1. 关键条款：付款、交付、违约、知识产权、保密
2. 风险点：对我不利的条款或模糊表述
3. 缺失项：常见但本合同未提及的重要条款
4. 修改建议：具体如何修改对我更有利
5. 签字前检查清单

注意：此为初步审查，重要合同请咨询专业律师。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_brainstorm',
        name: '头脑风暴助手',
        description: '围绕主题进行多角度头脑风暴',
        template: '''你是一位创新思维导师。请围绕以下主题进行头脑风暴：

{{content}}

请从以下角度提供创意：
1. 反常识角度：与主流观点相反的思路
2. 跨界借鉴：其他行业如何解决类似问题？
3. 极端场景：最好情况/最坏情况下的解法
4. 资源约束：如果只有1/10的预算怎么做？
5. 用户视角：不同用户群体的真实需求
6. 时间维度：短期/中期/长期的不同策略

每个角度给出2-3个具体想法。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_email_draft',
        name: '邮件起草助手',
        description: '根据要点生成专业邮件',
        template: '''你是一位商务写作专家。请根据以下要点起草一封专业邮件：

{{content}}

请输出：
1. 邮件主题行（3个选项）
2. 正式版邮件（适合正式商务场景）
3. 简洁版邮件（适合快速沟通）
4. 跟进版邮件（适合催促回复）

注意语气专业、表达清晰、重点突出。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_investor_pitch',
        name: '投资人路演准备',
        description: '整理路演要点和回答准备',
        template: '''你是一位创业投资人。请帮我准备以下项目的路演材料：

{{content}}

请输出：
1. 一句话定位：用最简洁的语言描述项目
2. 痛点-方案-市场：核心逻辑梳理
3. 商业模式：如何赚钱？ unit economics？
4. 竞争壁垒：为什么是你？护城河在哪里？
5. 里程碑：已完成和接下来6个月的关键节点
6. 融资需求：融资金额、用途、出让比例
7. 投资人可能问的5个尖锐问题及建议回答

请用投资人视角，直击要害。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_user_interview',
        name: '用户访谈整理',
        description: '从用户访谈记录中提取洞察',
        template: '''你是一位用户研究专家。请分析以下用户访谈记录：

{{content}}

请输出：
1. 用户画像：年龄、职业、使用场景等关键信息
2. 核心痛点：用户最头疼的3个问题
3. 现有解法：用户目前在用什么替代方案？
4. 付费意愿：用户对解决问题的付费态度
5. 功能需求：用户明确提到的功能期望
6. 意外发现：访谈中出乎意料的洞察
7. 下一步：基于访谈，产品应该优先做什么？''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_mvp_scope',
        name: 'MVP范围确定',
        description: '从需求中确定最小可行产品范围',
        template: '''你是一位精益创业导师。请从以下需求中确定MVP范围：

{{content}}

请输出：
1. 核心假设：这个产品基于哪些关键假设？
2. 必须有的功能：MVP阶段绝对不能少的3个功能
3. 可以延后的功能：V2再做的功能清单
4. 验证指标：如何衡量MVP是否成功？
5. 开发周期估算：基于一人公司节奏，合理的时间预期
6. 发布策略：先给谁用？如何收集反馈？

请务实、可执行，避免过度设计。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_tax_planning',
        name: '税务筹划笔记',
        description: '从收支记录中提取税务相关信息',
        template: '''你是一位税务顾问。请从以下记录中提取税务相关信息：

{{content}}

请整理：
1. 收入分类：各类收入的金额和性质
2. 可抵扣项：可能可以抵扣的成本和费用
3. 发票情况：已开发票/待开发票/需收发票
4. 税务节点：季度申报、年度汇算等关键时间点
5. 风险提示：可能的税务风险点
6. 优化建议：合法合规的税务优化方向

注意：此为信息整理，具体税务问题请咨询专业会计师。''',
        category: 'solopreneur',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),

      // ===== 商业 (business) =====
      PromptTemplate(
        id: 'template_swot',
        name: 'SWOT分析',
        description: '对业务或个人进行SWOT分析',
        template: '''请对以下内容进行SWOT分析：

{{content}}

请输出：
## 优势 (Strengths)
- 内部积极因素

## 劣势 (Weaknesses)
- 内部消极因素

## 机会 (Opportunities)
- 外部积极因素

## 威胁 (Threats)
- 外部消极因素

## 策略建议
- SO策略：利用优势抓住机会
- WO策略：克服劣势利用机会
- ST策略：利用优势规避威胁
- WT策略：减少劣势规避威胁''',
        category: 'business',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_market_research',
        name: '市场调研框架',
        description: '整理市场调研的关键发现',
        template: '''你是一位市场研究分析师。请整理以下市场调研记录：

{{content}}

请按以下框架输出：
1. 市场规模：TAM/SAM/SOM估算
2. 目标用户：核心用户画像和细分
3. 竞争格局：主要玩家和市场份额
4. 市场趋势：增长驱动因素和变化趋势
5. 进入壁垒：新进入者面临的挑战
6. 机会窗口：最佳切入时机和方式
7. 风险提示：市场层面的主要风险

请用数据说话，避免主观臆断。''',
        category: 'business',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_business_model',
        name: '商业模式画布',
        description: '将业务构思转化为商业模式画布',
        template: '''你是一位商业模式设计专家。请将以下内容转化为商业模式画布：

{{content}}

请输出九宫格画布：

1. 客户细分：为谁创造价值？
2. 价值主张：解决什么问题？
3. 渠道通路：如何触达客户？
4. 客户关系：如何维护客户关系？
5. 收入来源：如何赚钱？
6. 核心资源：需要什么关键资源？
7. 关键业务：必须做什么？
8. 重要合作：需要谁的帮助？
9. 成本结构：主要成本是什么？

每个格子给出具体、可验证的内容。''',
        category: 'business',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_kpi_dashboard',
        name: 'KPI指标提取',
        description: '从业务记录中提取关键指标',
        template: '''你是一位数据分析师。请从以下记录中提取关键业务指标：

{{content}}

请整理：
1. 北极星指标：最能反映业务健康的1个指标
2. 增长指标：用户增长、收入增长、活跃度
3. 效率指标：转化率、客单价、获客成本
4. 健康指标：留存率、NPS、退款率
5. 目标对比：当前值 vs 目标值
6. 趋势判断：环比/同比变化
7. 行动建议：基于数据，下一步该做什么？

请用表格呈现，一目了然。''',
        category: 'business',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_risk_assessment',
        name: '风险评估矩阵',
        description: '系统性评估项目或业务风险',
        template: '''你是一位风险管理专家。请对以下内容进行风险评估：

{{content}}

请输出风险矩阵：

| 风险项 | 可能性(1-5) | 影响度(1-5) | 风险等级 | 应对措施 | 负责人 |
|--------|------------|------------|----------|----------|--------|

风险等级标准：
- 高：可能性×影响度 ≥ 15
- 中：可能性×影响度 8-14
- 低：可能性×影响度 ≤ 7

请列出至少5个风险项，并给出具体可执行的应对措施。''',
        category: 'business',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_partnership_eval',
        name: '合作方评估',
        description: '评估潜在合作方的匹配度',
        template: '''你是一位商务拓展专家。请评估以下潜在合作方：

{{content}}

请从以下维度评估：
1. 战略匹配：合作目标是否一致？
2. 资源互补：对方有什么我没有的？
3. 信誉评估：对方的行业口碑和过往合作记录
4. 合作模式：代理/联营/投资/技术合作，哪种最合适？
5. 风险考量：合作可能带来的风险
6. 谈判要点：关键条款和底线
7. 合作优先级：推荐/观望/放弃

请给出客观、全面的评估。''',
        category: 'business',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_fundraising_prep',
        name: '融资准备清单',
        description: '整理融资前需要准备的材料和信息',
        template: '''你是一位融资顾问。请根据以下信息整理融资准备清单：

{{content}}

请输出：
1. 融资故事：用3分钟讲清楚为什么值得投资
2. 数据包：投资人最关心的10个数据及当前值
3. 材料清单：BP、财务模型、尽调材料等
4. 投资人清单：适合接触的投资机构和理由
5. 时间规划：从准备到关账的合理时间线
6. 估值参考：同行业近期融资估值对比
7. 谈判策略：条款优先级和可让步项

请务实、具体，避免空洞的套话。''',
        category: 'business',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),

      // ===== 效率 (productivity) =====
      PromptTemplate(
        id: 'template_time_audit',
        name: '时间审计',
        description: '分析时间使用情况并优化',
        template: '''你是一位时间管理专家。请分析以下时间使用记录：

{{content}}

请输出：
1. 时间分布：各类活动占比
2. 高价值活动：哪些事带来了最大回报？
3. 时间黑洞：哪些事消耗了大量时间但价值低？
4. 精力曲线：一天中精力最好和最差的时间段
5. 优化方案：
   - 应该多做的事
   - 应该少做/外包的事
   - 应该停止做的事
6. 下周时间预算：理想的时间分配方案

请给出具体、可执行的建议。''',
        category: 'productivity',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_sop_generator',
        name: 'SOP流程生成',
        description: '将操作经验转化为标准操作流程',
        template: '''你是一位流程管理专家。请将以下操作经验转化为SOP：

{{content}}

请输出标准操作流程：

## 流程名称
## 适用范围
## 目标
## 步骤清单
| 步骤 | 操作内容 | 标准/要求 | 检查点 | 耗时 |
|------|----------|-----------|--------|------|

## 常见问题及处理
## 相关工具/模板
## 审核人
## 更新记录

请确保步骤清晰、可执行、可检查。''',
        category: 'productivity',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_decision_matrix',
        name: '决策矩阵',
        description: '用加权评分辅助复杂决策',
        template: '''你是一位决策分析专家。请帮助我对以下决策进行系统分析：

{{content}}

请输出：
1. 决策目标：这次决策要解决什么问题？
2. 可选方案：列出所有可行的选项
3. 评估维度：最重要的3-5个评估标准
4. 加权评分矩阵：
   | 方案 | 维度1(权重) | 维度2(权重) | ... | 总分 |
5. 敏感性分析：如果某个权重变化，结果会变吗？
6. 推荐决策：基于分析的最佳选择
7. 执行计划：选定方案后的第一步行动

请保持客观，避免先入为主。''',
        category: 'productivity',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_knowledge_card',
        name: '知识卡片生成',
        description: '将学习内容转化为知识卡片',
        template: '''你是一位知识管理专家。请将以下内容转化为知识卡片：

{{content}}

请输出：
1. 核心概念卡：用一句话定义核心概念
2. 原理卡：解释"为什么"会这样
3. 应用卡：3个实际应用场景
4. 关联卡：与哪些已有知识相关？
5. 反常识卡：有哪些反直觉的点？
6. 行动卡：读完这个，我应该做什么？

每张卡片控制在100字以内，适合复习。''',
        category: 'productivity',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_weekly_review',
        name: '周回顾模板',
        description: '结构化回顾一周工作',
        template: '''你是一位个人效能教练。请帮我回顾本周：

{{content}}

请按以下框架输出：

## 本周高光时刻
- 最值得骄傲的1-3件事

## 本周低谷时刻
- 最遗憾的1-3件事

## 时间投资复盘
- 计划用时 vs 实际用时
- 最大偏差在哪里？为什么？

## 能量管理
- 什么时候最有创造力？
- 什么时候最容易疲惫？

## 关系维护
- 本周维护了哪些重要关系？
- 忽略了谁？

## 下周调整
- 基于本周复盘，下周要调整的3件事

请诚实、具体，不粉饰。''',
        category: 'productivity',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_inbox_zero',
        name: '收件箱清零',
        description: '整理待办事项并确定优先级',
        template: '''你是一位任务管理专家。请帮我整理以下待办事项：

{{content}}

请输出：
1. 立即做（2分钟内能完成的）
2. 今日重点（今天必须完成的3件事）
3. 本周计划（本周要推进的事项）
4. 委托/删除（可以交给别人的或不需要做的）
5. 待定（暂时无法决定，需要更多信息）

对每个事项标注：预估时间、截止日期、所需资源。''',
        category: 'productivity',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_goal_breakdown',
        name: '目标拆解',
        description: '将大目标拆解为可执行的小步骤',
        template: '''你是一位目标管理专家。请将以下目标拆解为可执行步骤：

{{content}}

请输出：
1. 终极目标：清晰定义成功标准
2. 里程碑：3-5个关键节点及验收标准
3. 本月目标：这个月要完成什么？
4. 本周任务：这周要推进什么？
5. 今日行动：今天可以做的第一件事
6. 依赖关系：哪些步骤有先后顺序？
7. 风险预案：最可能卡住的地方及备选方案

请确保每个步骤都是具体、可衡量、可执行的。''',
        category: 'productivity',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),

      // ===== 创意 (creative) =====
      PromptTemplate(
        id: 'template_story_framework',
        name: '故事框架生成',
        description: '将素材转化为有结构的故事',
        template: '''你是一位故事创作专家。请将以下素材转化为完整故事框架：

{{content}}

请输出：
1. 故事核：一句话概括核心冲突
2. 人物设定：主角、对手、盟友的关键特征
3. 三幕结构：
   - 第一幕：设定、冲突引入
   - 第二幕：对抗、转折
   - 第三幕：高潮、结局
4. 关键场景：3-5个必须有的场景
5. 情感弧线：主角的情绪变化曲线
6. 主题：这个故事想表达什么？

适合小说、剧本、品牌故事等。''',
        category: 'creative',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_brand_voice',
        name: '品牌话术提炼',
        description: '从品牌相关内容中提炼品牌话术',
        template: '''你是一位品牌策略师。请从以下内容中提炼品牌话术：

{{content}}

请输出：
1. 品牌定位：一句话说清楚我是谁
2. 品牌故事：起源故事（150字以内）
3. 核心价值：3个品牌关键词
4. 品牌个性：如果是一个人，是什么性格？
5. 话术库：
   - 介绍话术（30秒版本）
   - 介绍话术（2分钟版本）
   - 社交媒体简介
   - 邮件签名话术
6. 禁忌词：品牌不应该使用的词汇

请确保所有话术一致、有辨识度。''',
        category: 'creative',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_visual_brief',
        name: '设计需求简报',
        description: '将设计需求整理为专业brief',
        template: '''你是一位创意总监。请将以下设计需求整理为专业brief：

{{content}}

请输出：
1. 项目背景：为什么要做这个项目？
2. 目标受众：为谁设计？他们的特征？
3. 设计目标：这个设计要解决什么问题？
4. 内容清单：必须包含的元素
5. 风格参考：期望的视觉风格（可描述或举例）
6. 技术要求：尺寸、格式、分辨率等
7. 禁忌：绝对不要出现的内容或风格
8. 时间线：初稿、修改、定稿的时间
9. 验收标准：什么样的产出算合格？

请清晰、具体，减少设计师的猜测。''',
        category: 'creative',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_hook_generator',
        name: '开头钩子生成',
        description: '为内容生成吸引人的开头',
        template: '''你是一位文案高手。请为以下内容生成吸引人的开头：

{{content}}

请输出10个不同风格的开头：
1. 悬念式：提出一个引人深思的问题
2. 数据式：用惊人数据开场
3. 故事式：用一个具体场景切入
4. 反常识式：挑战普遍认知
5. 痛点式：直击读者最头疼的问题
6. 权威式：引用专家观点或研究
7. 对比式：前后对比制造张力
8. 对话式：用对话开场
9. 预言式：预测未来趋势
10. 自嘲式：用幽默拉近距离

每个开头控制在50字以内。''',
        category: 'creative',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_script_rewrite',
        name: '文案改写助手',
        description: '将文案改写成不同风格',
        template: '''你是一位多风格文案专家。请将以下内容改写成不同风格：

{{content}}

请输出以下版本：
1. 专业正式版：适合商务场景
2. 轻松口语版：适合社交媒体
3. 极简版：控制在50字以内
4. 情感共鸣版：打动人心
5. 行动号召版：促使立即行动
6. 幽默版：轻松有趣

保持核心信息不变，调整语气和表达方式。''',
        category: 'creative',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_naming',
        name: '命名创意生成',
        description: '为产品/项目/品牌生成命名方案',
        template: '''你是一位命名专家。请为以下项目生成命名方案：

{{content}}

请输出：
1. 描述性名称：直接描述功能或特点
2. 隐喻性名称：用比喻或象征
3. 造词名称：创造新词或组合词
4. 人名/地名：用人名或地名关联
5. 外语名称：用其他语言的词汇
6. 缩写名称：用首字母缩写

每个类别给出3-5个选项，并解释命名理由。
同时检查：是否容易拼写、发音、记忆？域名是否可用？''',
        category: 'creative',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),

      // ===== 学习 (learning) =====
      PromptTemplate(
        id: 'template_book_summary',
        name: '读书笔记整理',
        description: '将阅读内容整理为结构化笔记',
        template: '''你是一位阅读方法专家。请帮我整理以下读书笔记：

{{content}}

请输出：
1. 书籍信息：书名、作者、核心主题
2. 一句话总结：这本书讲了什么？
3. 核心观点：3-5个最重要的观点
4. 金句摘录：最有启发的3句话
5. 与我相关：这本书与我的现状有什么关联？
6. 行动清单：读完这本书，我要做的3件事
7. 延伸阅读：相关的书籍或文章推荐

请精炼、实用，避免照搬原文。''',
        category: 'learning',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_course_notes',
        name: '课程笔记整理',
        description: '将课程学习内容系统化整理',
        template: '''你是一位学习专家。请帮我整理以下课程笔记：

{{content}}

请输出：
1. 课程概览：主题、讲师、核心框架
2. 知识地图：各知识点之间的关系
3. 重点笔记：最重要的概念和方法
4. 案例整理：课程中提到的关键案例
5. 疑问清单：还没理解或想深入的问题
6. 实践计划：如何将所学应用到实际工作中
7. 分享要点：如果要讲给别人听，重点讲什么？

请结构化、可视化，便于复习。''',
        category: 'learning',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_skill_gap',
        name: '技能差距分析',
        description: '分析当前技能与目标技能的差距',
        template: '''你是一位职业发展顾问。请分析以下技能相关信息：

{{content}}

请输出：
1. 目标岗位/角色：想要达到的状态
2. 必备技能清单：目标角色需要的核心技能
3. 当前技能评估：已掌握的技能及熟练度
4. 技能差距：还需要补齐的技能
5. 学习优先级：哪些技能应该先学？为什么？
6. 学习资源：推荐的书籍、课程、实践项目
7. 时间规划：合理的学习路径和时间预期
8. 验证方式：如何证明已经掌握了这项技能？

请给出具体、可执行的学习计划。''',
        category: 'learning',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_teach_back',
        name: '费曼学习法',
        description: '用简单语言复述所学内容',
        template: '''你是一位教育专家。请用费曼学习法帮我检验以下内容的理解：

{{content}}

请输出：
1. 用大白话解释：向一个10岁小孩解释这个概念
2. 类比：用一个生活中的类比来说明
3. 简化版：如果只能用3句话，怎么说？
4. 关键术语：列出必须理解的专业术语及解释
5. 常见误解：初学者最容易理解错的地方
6. 检验问题：3个问题，如果能回答就说明理解了
7. 知识盲区：我还需要补充了解什么？

请确保解释简单到任何人都能听懂。''',
        category: 'learning',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_conference_notes',
        name: '会议/峰会笔记',
        description: '整理行业会议或峰会的收获',
        template: '''你是一位行业观察家。请整理以下会议/峰会笔记：

{{content}}

请输出：
1. 会议概况：名称、时间、主题、关键嘉宾
2. 核心洞察：3-5个最有价值的观点
3. 行业趋势：从会议中看到的趋势信号
4. 新知收获：之前不知道的新信息
5. 人脉线索：值得跟进的人或组织
6. 商业机会：发现的可能机会
7. 行动清单：基于会议收获，接下来要做什么？

请提炼干货，避免流水账。''',
        category: 'learning',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),

      // ===== 生活 (life) =====
      PromptTemplate(
        id: 'template_travel_plan',
        name: '旅行规划助手',
        description: '根据需求生成旅行规划',
        template: '''你是一位旅行规划师。请根据以下需求规划旅行：

{{content}}

请输出：
1. 行程概览：天数、目的地、主题
2. 每日行程：每天的主要活动和安排
3. 住宿建议：区域选择和预算参考
4. 交通方案：各城市/景点间的交通
5. 美食推荐：当地必吃和特色餐厅
6. 预算估算：交通、住宿、餐饮、门票、购物
7. 注意事项：签证、天气、安全、文化禁忌
8. 备用方案：如果下雨/闭馆/延误怎么办？

请考虑性价比和体验感的平衡。''',
        category: 'life',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_health_log',
        name: '健康记录分析',
        description: '分析健康相关记录并给出建议',
        template: '''你是一位健康管理师。请分析以下健康记录：

{{content}}

请输出：
1. 整体评估：当前健康状态概览
2. 作息分析：睡眠、饮食、运动规律
3. 风险信号：需要关注的异常指标
4. 改善建议：
   - 饮食调整
   - 运动计划
   - 作息优化
5. 就医建议：是否需要看医生？看什么科？
6. 追踪指标：建议持续记录的关键指标

注意：此为健康信息整理，具体医疗问题请咨询医生。''',
        category: 'life',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_purchase_decision',
        name: '购买决策分析',
        description: '分析大件购买决策的利弊',
        template: '''你是一位消费决策顾问。请分析以下购买决策：

{{content}}

请输出：
1. 需求确认：是真需求还是伪需求？
2. 选项对比：各候选方案的优缺点
   | 方案 | 价格 | 优点 | 缺点 | 适合场景 |
3. 总拥有成本：除了购买价，还要花多少钱？
4. 时机判断：现在买是最好的时机吗？
5. 替代方案：不买或买更便宜的替代品？
6. 决策建议：推荐方案及理由
7. 谈判要点：如果买，怎么谈价格？

请帮助做出理性、不冲动的决策。''',
        category: 'life',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_relationship_maintain',
        name: '关系维护笔记',
        description: '整理人际关系维护的要点',
        template: '''你是一位人际关系顾问。请帮我整理以下关系维护记录：

{{content}}

请输出：
1. 关系图谱：关键人物及与我的关系
2. 重要日期：生日、纪念日、合作周年等
3. 互动记录：最近3次的沟通要点
4. 对方需求：每个人目前可能需要什么帮助？
5. 我的需求：我希望从这段关系中获得什么？
6. 维护计划：
   - 本周要联系的人
   - 本月要推进的关系
   - 需要修复的关系
7. 价值交换：如何为对方创造价值？

请真诚、长期主义，避免功利。''',
        category: 'life',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_habit_tracker',
        name: '习惯养成分析',
        description: '分析习惯记录并优化养成策略',
        template: '''你是一位习惯养成教练。请分析以下习惯记录：

{{content}}

请输出：
1. 习惯概览：正在培养的习惯及坚持天数
2. 成功率：各习惯的完成率
3. 触发分析：什么情况下容易坚持？什么情况下容易放弃？
4. 障碍识别：最大的3个障碍
5. 环境设计：如何调整环境让习惯更容易坚持？
6. 奖励机制：如何给自己正向反馈？
7. 习惯叠加：如何将新习惯绑定到已有习惯上？
8. 下周目标：具体、可衡量的下周习惯目标

请科学、温和，避免完美主义。''',
        category: 'life',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),

      // ===== 趣味 (fun) =====
      PromptTemplate(
        id: 'template_gossip_collector',
        name: '八卦收集助手',
        description: '整理收集到的各种八卦和信息碎片',
        template: '''你是一位信息整理专家。请帮我整理以下收集到的八卦和信息碎片：

{{content}}

请输出：
1. 人物关系图：涉及的人物及他们之间的关系
2. 核心信息：每条八卦的关键信息点
3. 可信度评估：高/中/低，理由
4. 信息缺口：还需要了解什么才能拼凑完整图景？
5. 潜在影响：这些信息可能带来什么后果？
6. 行动建议：基于这些信息，我应该做什么？

请客观整理，不添油加醋，也不遗漏关键信息。''',
        category: 'fun',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_brainstorm_wild',
        name: '脑洞大开',
        description: '不受约束地发散思维，产生疯狂创意',
        template: '''你是一位不受任何约束的创意狂人。请围绕以下主题进行彻底的发散思维：

{{content}}

请从以下疯狂角度思考：
1. 如果钱不是问题：无限预算下会怎么做？
2. 如果时间倒流：回到过去会改变什么？
3. 如果物理定律失效：打破一切规则会怎样？
4. 如果动物会说话：它们会给出什么建议？
5. 如果外星人参与：外星文明会怎么解决这个问题？
6. 如果我是反派：从反面角色的角度思考
7. 如果只有一句话：用一句话概括最疯狂的方案
8. 跨界混搭：把两个完全不相关的领域结合起来

每个角度给出1-2个离谱但有趣的想法。不要自我审查，越疯狂越好！''',
        category: 'fun',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_less_is_more',
        name: '字越少问题越大',
        description: '用极简文字表达，挖掘深层问题',
        template: '''你是一位极简主义分析大师。请对以下内容进行"字越少问题越大"的分析：

{{content}}

请输出：
1. 一句话总结：用最少的字概括核心问题
2. 三个字版本：再压缩到三个字
3. 一个字版本：最终压缩到一个字
4. 反向展开：从这个字/词反向展开，能看到什么深层问题？
5. 沉默的部分：没有说出来的话可能比说出来的更重要，有哪些潜台词？
6. 省略号效应：每个省略号"..."背后可能隐藏着什么？
7. 真正的问题：表面的文字之下，真正的问题是什么？

请像侦探一样，从字里行间发现隐藏的信息。''',
        category: 'fun',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_devil_advocate',
        name: '魔鬼代言人',
        description: '故意唱反调，挑战你的每一个假设',
        template: '''你是一位专业的"魔鬼代言人"，你的任务就是故意唱反调、挑毛病、找漏洞。请对以下内容进行全方位挑战：

{{content}}

请从以下角度进行攻击：
1. 前提质疑：这个结论基于什么前提？这些前提一定成立吗？
2. 反例攻击：举出3个反例证明这个结论不成立
3. 滑坡论证：如果接受这个观点，最坏会滑向哪里？
4. 动机质疑：提出这个观点的人可能有什么隐藏动机？
5. 数据质疑：如果有数据支持，数据可能有什么问题？
6. 替代解释：同样的现象，有没有完全不同的解释？
7. 极端测试：把这个观点推到极端，还成立吗？
8. 时间检验：3年后回头看，这个观点还站得住脚吗？

请毫不留情，但保持逻辑严密。''',
        category: 'fun',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_conspiracy_theory',
        name: '阴谋论生成器',
        description: '用幽默的方式生成各种"阴谋论"',
        template: '''你是一位幽默的"阴谋论"生成大师（纯属娱乐）。请基于以下信息，生成几个有趣的"阴谋论"：

{{content}}

请输出3-5个不同风格的"阴谋论"：
1. 经典版：用"真相只有一个"的口吻
2. 科幻版：加入外星人/时间旅行者/平行宇宙
3. 职场版：把一切都解释为办公室政治
4. 经济版：一切都是为了钱
5. 哲学版：上升到存在主义高度

每个"阴谋论"包含：
- 核心主张
- 3个"证据"
- 1个"知情者"的匿名爆料
- 为什么官方不想让你知道

⚠️ 纯属娱乐，请勿当真！''',
        category: 'fun',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_roast_me',
        name: '毒舌点评',
        description: '用幽默犀利的方式点评内容',
        template: '''你是一位毒舌但充满智慧的评论家。请对以下内容进行犀利点评：

{{content}}

请输出：
1. 一句话毒评：用一句话精准打击
2. 优点（ reluctantly 承认）：勉强找出2-3个优点
3. 槽点清单：列出5个最想吐槽的地方
4. 如果是我：如果是你，会怎么做？
5. 评分：满分10分，给几分？理由？
6. 金句总结：用一句让人过目不忘的话总结

请保持幽默感，吐槽要犀利但不恶毒，让人笑着接受批评。''',
        category: 'fun',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_fortune_teller',
        name: '赛博算命',
        description: '基于现有信息做趣味预测',
        template: '''你是一位赛博算命大师（仅供娱乐）。请基于以下信息进行趣味预测：

{{content}}

请输出：
1. 今日运势：基于内容的今日运势评分（1-100）
2. 幸运元素：幸运色、幸运数字、幸运方向
3. 贵人提示：什么样的人可能会帮到你？
4. 避坑指南：今天要注意避开什么？
5. 塔罗牌解读：抽3张塔罗牌并解读
   - 过去：代表什么？
   - 现在：代表什么？
   - 未来：代表什么？
6. 星座混搭：如果用星座性格分析，这是什么星座的行为模式？
7. 最终预言：用一句神秘的话预言未来

⚠️ 仅供娱乐，命运掌握在自己手中！''',
        category: 'fun',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PromptTemplate(
        id: 'template_ancient_wisdom',
        name: '古人智慧',
        description: '用古人/先贤的口吻给出建议',
        template: '''你是一位通晓古今的智慧长者。请用古人/先贤的口吻，对以下内容给出建议：

{{content}}

请分别以以下身份给出建议：
1. 孔子：用儒家思想分析
2. 老子：用道家思想分析
3. 孙子：用兵法策略分析
4. 苏格拉底：用诘问法引导思考
5. 尼采：用超人哲学分析
6. 马斯克：用第一性原理分析
7. 巴菲特：用价值投资思维分析

每位先贤给出：
- 一句名言式点评
- 具体建议
- 如果先贤遇到这种情况会怎么做？''',
        category: 'fun',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
