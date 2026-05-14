import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/expandable_text_field.dart';

class AnalysisTemplateSettingsScreen extends ConsumerStatefulWidget {
  const AnalysisTemplateSettingsScreen({super.key});

  @override
  ConsumerState<AnalysisTemplateSettingsScreen> createState() =>
      _AnalysisTemplateSettingsScreenState();
}

class _AnalysisTemplateSettingsScreenState
    extends ConsumerState<AnalysisTemplateSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AnalysisTemplateConfig _config = AnalysisTemplateConfig.defaultConfig();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await StorageService.getAnalysisTemplates();
    if (mounted) {
      setState(() {
        _config = config;
        _isLoading = false;
      });
    }
  }

  List<AnalysisTemplate> get _builtInWeeklyTemplates => [
        AnalysisTemplate(
          id: 'builtin_weekly_default',
          name: '标准周报',
          description: '经典的周报格式，包含成果、数据、问题、经验、计划',
          type: 'weekly_report',
          systemPrompt: '''你是一位高效的个人助理。请根据以下工作记录，生成一份结构化的周报。

请按以下格式输出：

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
          isBuiltIn: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        AnalysisTemplate(
          id: 'builtin_weekly_executive',
          name: '高管简报',
          description: '简洁的高管视角周报，聚焦关键决策信息',
          type: 'weekly_report',
          systemPrompt: '''你是一位CEO助理。请根据以下工作记录，生成一份高管级别的周报简报。

请按以下格式输出：

## 本周关键进展（3条以内）
- 只写最重要的，每条不超过30字

## 关键数据变化
- 环比变化：收入、用户、效率等核心指标

## 需要决策的事项
- 需要我拍板的事情，附建议方案

## 风险预警
- 可能出问题的地方，提前预警

## 下周必做（3件）
- 优先级最高的3件事

请极度简洁，每部分不超过5条，适合3分钟阅读完毕。''',
          isBuiltIn: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        AnalysisTemplate(
          id: 'builtin_weekly_detailed',
          name: '详细工作周报',
          description: '详细记录每项工作的进展和细节',
          type: 'weekly_report',
          systemPrompt: '''你是一位严谨的项目管理助理。请根据以下工作记录，生成一份详细的工作周报。

请按以下格式输出：

## 本周完成工作清单
| 序号 | 工作内容 | 完成度 | 耗时 | 备注 |
|------|----------|--------|------|------|

## 各项目进展
### 项目A
- 本周进展
- 遇到的问题
- 下一步计划

### 项目B
- 本周进展
- 遇到的问题
- 下一步计划

## 时间分配分析
- 各类工作占比
- 时间使用效率评估

## 待解决问题清单
- 问题描述
- 优先级
- 预计解决时间

## 下周详细计划
| 日期 | 计划内容 | 预计产出 |
|------|----------|----------|

请详细、结构化，适合存档和复盘。''',
          isBuiltIn: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

  List<AnalysisTemplate> get _builtInMindMapTemplates => [
        AnalysisTemplate(
          id: 'builtin_mindmap_default',
          name: '关联脑图',
          description: '基于记录标签和内容的关联知识脑图',
          type: 'mindmap',
          systemPrompt: '''你是一位知识管理专家。请根据以下记录，生成一份结构化的知识关联脑图。

请按以下格式输出：

## 核心主题
- 所有记录围绕的核心主题是什么？

## 一级分支
### 分支1：[主题名]
- 相关记录要点
- 关键洞察

### 分支2：[主题名]
- 相关记录要点
- 关键洞察

## 关联关系
- 分支1 → 分支2：什么关联？
- 分支2 → 分支3：什么关联？

## 知识缺口
- 哪些重要主题缺少记录？

## 行动建议
- 基于脑图，接下来应该关注什么？''',
          isBuiltIn: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        AnalysisTemplate(
          id: 'builtin_mindmap_problem',
          name: '问题拆解脑图',
          description: '将复杂问题拆解为结构化脑图',
          type: 'mindmap',
          systemPrompt: '''你是一位问题解决专家。请根据以下记录，将核心问题拆解为结构化的脑图。

请按以下格式输出：

## 核心问题
- 所有记录指向的核心问题是什么？

## 问题拆解
### 子问题1
- 具体表现
- 根本原因
- 可能的解决方案

### 子问题2
- 具体表现
- 根本原因
- 可能的解决方案

## 因果关系链
- A → B → C 的因果链条

## 优先级排序
- 哪些问题必须先解决？
- 哪些可以并行处理？

## 资源需求
- 解决这些问题需要什么资源？

## 下一步行动
- 基于拆解，第一步应该做什么？''',
          isBuiltIn: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        AnalysisTemplate(
          id: 'builtin_mindmap_opportunity',
          name: '机会洞察脑图',
          description: '从记录中挖掘潜在机会和关联',
          type: 'mindmap',
          systemPrompt: '''你是一位商业洞察专家。请根据以下记录，挖掘潜在的机会和关联。

请按以下格式输出：

## 核心洞察
- 从记录中发现的最重要的洞察是什么？

## 机会地图
### 机会1
- 机会描述
- 可行性评估
- 潜在价值

### 机会2
- 机会描述
- 可行性评估
- 潜在价值

## 关联发现
- 哪些看似无关的记录其实有关联？
- 这种关联意味着什么？

## 趋势判断
- 从记录中能看到什么趋势？
- 这个趋势会带来什么机会或威胁？

## 创新点子
- 基于这些记录，有什么创新的想法？

## 行动建议
- 最值得尝试的机会是什么？为什么？''',
          isBuiltIn: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

  List<AnalysisTemplate> _getTemplatesForType(String type) {
    final builtIn = type == 'weekly_report'
        ? _builtInWeeklyTemplates
        : _builtInMindMapTemplates;
    final custom =
        _config.customTemplates.where((t) => t.type == type).toList();
    return [...builtIn, ...custom];
  }

  String _getDefaultIdForType(String type) {
    return type == 'weekly_report'
        ? _config.defaultWeeklyReportTemplateId
        : _config.defaultMindMapTemplateId;
  }

  Future<void> _setDefault(String templateId, String type) async {
    final newConfig = type == 'weekly_report'
        ? _config.copyWith(defaultWeeklyReportTemplateId: templateId)
        : _config.copyWith(defaultMindMapTemplateId: templateId);
    await StorageService.saveAnalysisTemplates(newConfig);
    setState(() => _config = newConfig);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('默认模板已更新'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _deleteCustomTemplate(String id) async {
    final newCustom = _config.customTemplates.where((t) => t.id != id).toList();
    var newConfig = _config.copyWith(customTemplates: newCustom);

    // 如果删除的是默认模板，重置为内置默认
    if (_config.defaultWeeklyReportTemplateId == id) {
      newConfig = newConfig.copyWith(
          defaultWeeklyReportTemplateId: 'builtin_weekly_default');
    }
    if (_config.defaultMindMapTemplateId == id) {
      newConfig = newConfig.copyWith(
          defaultMindMapTemplateId: 'builtin_mindmap_default');
    }

    await StorageService.saveAnalysisTemplates(newConfig);
    setState(() => _config = newConfig);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('模板已删除'), backgroundColor: AppColors.success),
      );
    }
  }

  void _showTemplateEditor({AnalysisTemplate? existing}) {
    final isEditing = existing != null;
    final type = _tabController.index == 0 ? 'weekly_report' : 'mindmap';
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descController =
        TextEditingController(text: existing?.description ?? '');
    final promptController =
        TextEditingController(text: existing?.systemPrompt ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? '编辑模板' : '新建模板'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExpandableTextField(
                controller: nameController,
                labelText: '模板名称',
                minLines: 1,
                maxLines: 2,
                showExpandButton: false,
              ),
              const SizedBox(height: 12),
              ExpandableTextField(
                controller: descController,
                labelText: '描述',
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              ExpandableTextField(
                controller: promptController,
                labelText: 'System Prompt',
                hintText: '输入AI分析时使用的系统提示词...',
                minLines: 5,
                maxLines: 10,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final prompt = promptController.text.trim();
              if (name.isEmpty || prompt.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('名称和Prompt不能为空')),
                );
                return;
              }

              final newTemplate = AnalysisTemplate(
                id: isEditing ? existing.id : 'custom_${const Uuid().v4()}',
                name: name,
                description: descController.text.trim(),
                type: type,
                systemPrompt: prompt,
                isBuiltIn: false,
                createdAt: isEditing ? existing.createdAt : DateTime.now(),
                updatedAt: DateTime.now(),
              );

              final newCustom =
                  List<AnalysisTemplate>.from(_config.customTemplates);
              if (isEditing) {
                final idx = newCustom.indexWhere((t) => t.id == existing.id);
                if (idx >= 0) newCustom[idx] = newTemplate;
              } else {
                newCustom.add(newTemplate);
              }

              final newConfig = _config.copyWith(customTemplates: newCustom);
              await StorageService.saveAnalysisTemplates(newConfig);
              setState(() => _config = newConfig);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('模板已保存'),
                      backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析模板设置'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '周报模板'),
            Tab(text: '脑图模板'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTemplateList('weekly_report'),
                _buildTemplateList('mindmap'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTemplateEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTemplateList(String type) {
    final templates = _getTemplatesForType(type);
    final defaultId = _getDefaultIdForType(type);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final isDefault = template.id == defaultId;
        final isBuiltIn = template.isBuiltIn;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDefault ? AppColors.primary : Colors.grey[200]!,
              width: isDefault ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            template.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isBuiltIn) ...[
                            const SizedBox(width: 8),
                            Chip(
                              label: const Text('系统',
                                  style: TextStyle(fontSize: 10)),
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '默认',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  template.description,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!isDefault)
                      TextButton.icon(
                        onPressed: () => _setDefault(template.id, type),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('设为默认'),
                      )
                    else
                      const SizedBox.shrink(),
                    const Spacer(),
                    if (!isBuiltIn) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () =>
                            _showTemplateEditor(existing: template),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppColors.error),
                        onPressed: () => _deleteCustomTemplate(template.id),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
