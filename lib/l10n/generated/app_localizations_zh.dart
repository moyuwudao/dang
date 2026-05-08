// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '畅记';

  @override
  String get appTagline => '面向一人公司的AI速记应用';

  @override
  String get homeTitle => '我的笔记';

  @override
  String get recordButton => '录音';

  @override
  String get stopButton => '停止';

  @override
  String get pauseButton => '暂停';

  @override
  String get resumeButton => '继续';

  @override
  String get cancelButton => '取消';

  @override
  String get saveButton => '保存';

  @override
  String get deleteButton => '删除';

  @override
  String get editButton => '编辑';

  @override
  String get shareButton => '分享';

  @override
  String get settingsTitle => '设置';

  @override
  String get apiKeySettings => 'API密钥设置';

  @override
  String get openaiApiKey => 'OpenAI API密钥';

  @override
  String get apiKeyHint => '请输入您的OpenAI API密钥';

  @override
  String get apiKeyHelp => '您的API密钥仅存储在本地，不会上传';

  @override
  String get themeSettings => '主题';

  @override
  String get lightTheme => '浅色';

  @override
  String get darkTheme => '深色';

  @override
  String get systemTheme => '跟随系统';

  @override
  String get languageSettings => '语言';

  @override
  String get english => '英语';

  @override
  String get chinese => '中文';

  @override
  String get recordingTitle => '录音';

  @override
  String get recordingInProgress => '正在录音...';

  @override
  String get tapToStop => '点击停止';

  @override
  String get ocrTitle => '文字识别';

  @override
  String get ocrDescription => '拍照或选择图片以提取文字';

  @override
  String get takePhoto => '拍照';

  @override
  String get selectImage => '从相册选择';

  @override
  String get transcribeTitle => '语音转写';

  @override
  String get transcribeDescription => '使用AI将语音转换为文字';

  @override
  String get transcribing => '正在转写...';

  @override
  String get transcribeSuccess => '转写完成';

  @override
  String get transcribeError => '转写失败';

  @override
  String get retryButton => '重试';

  @override
  String get noRecords => '暂无记录';

  @override
  String get createFirstRecord => '点击麦克风创建您的第一条笔记';

  @override
  String get searchHint => '搜索笔记...';

  @override
  String get allNotes => '全部笔记';

  @override
  String get favorites => '收藏';

  @override
  String get tags => '标签';

  @override
  String get addTag => '添加标签';

  @override
  String get untitled => '未命名';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get termsOfService => '用户协议';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get confirmDelete => '确定要删除这条笔记吗？';

  @override
  String get confirmDeleteTitle => '删除笔记';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get permissionRequired => '需要权限';

  @override
  String get microphonePermission => '录音需要麦克风权限';

  @override
  String get cameraPermission => '文字识别需要相机权限';

  @override
  String get storagePermission => '保存录音需要存储权限';

  @override
  String get grantPermission => '授予权限';

  @override
  String get errorGeneric => '出错了，请重试';

  @override
  String get errorNetwork => '网络错误，请检查网络连接';

  @override
  String get errorApiKey => 'API密钥无效，请检查设置';

  @override
  String get dataManagement => '数据管理';

  @override
  String get dataBackup => '数据备份';

  @override
  String get dataRestore => '数据恢复';

  @override
  String get exportData => '导出数据';

  @override
  String get importData => '导入数据';

  @override
  String get clearData => '清除所有数据';

  @override
  String get clearDataConfirm => '这将永久删除所有记录，此操作无法撤销。';

  @override
  String get recordQuality => '录音质量';

  @override
  String get recordFormat => '录音格式';

  @override
  String get highQuality => '高质量';

  @override
  String get mediumQuality => '中等质量';

  @override
  String get lowQuality => '低质量';

  @override
  String get helpAndFeedback => '帮助与反馈';

  @override
  String get contactUs => '联系我们';

  @override
  String get rateApp => '评价应用';

  @override
  String get shareApp => '分享应用';

  @override
  String get textInput => '文本录入';

  @override
  String get textInputHint => '在此输入文本内容...';

  @override
  String get usageStatistics => '使用统计';

  @override
  String get usageStatsDetail => '使用详情';

  @override
  String get usageStatsClear => '清除统计';

  @override
  String get usageStatsClearConfirm => '确定要清除所有使用统计吗？此操作无法撤销。';

  @override
  String get usageStatsEmpty => '暂无使用数据';

  @override
  String get usageStatsEmptyHint => '使用AI功能后将显示统计数据';

  @override
  String get calls => '次调用';

  @override
  String get tokens => '个Token';

  @override
  String get lastUsed => '最后使用';

  @override
  String get features => '功能';

  @override
  String get cancel => '取消';

  @override
  String get clear => '清除';
}
