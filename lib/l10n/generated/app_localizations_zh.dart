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
  String get confirmDelete => '确定要删除吗？';

  @override
  String get confirmDeleteTitle => '确认删除';

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

  @override
  String get frequentlyUsedTemplates => '常用模板';

  @override
  String get noMatchingTool => '没有匹配的工具';

  @override
  String get frequentlyUsedTools => '常用工具';

  @override
  String get createRole => '创建角色';

  @override
  String get selectDataSourceType => '选择数据源类型';

  @override
  String get noTags => '暂无标签';

  @override
  String get noToolOutputData => '没有工具输出数据';

  @override
  String associatedRecords(int count) {
    return '关联 $count 条记录';
  }

  @override
  String get dateRange => '日期范围';

  @override
  String get includeAiAnalysis => '包含AI分析结果';

  @override
  String get includeAiAnalysisDesc => '将记录的AI分析内容也作为输入数据';

  @override
  String get confirm => '确认';

  @override
  String get close => '关闭';

  @override
  String get copy => '复制';

  @override
  String get back => '返回';

  @override
  String get next => '下一步';

  @override
  String get previous => '上一步';

  @override
  String get done => '完成';

  @override
  String get add => '添加';

  @override
  String get hide => '隐藏';

  @override
  String get login => '登录';

  @override
  String get register => '注册';

  @override
  String get logout => '退出登录';

  @override
  String get loading => '加载中...';

  @override
  String get saveSuccess => '保存成功';

  @override
  String get saveFailed => '保存失败';

  @override
  String get loadFailed => '加载失败';

  @override
  String get deleteSuccess => '删除成功';

  @override
  String get contentUpdated => '内容已更新';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get noContent => '无内容';

  @override
  String get noMoreRecords => '没有更多记录了';

  @override
  String get searchFailed => '搜索失败';

  @override
  String get noSearchResults => '未找到相关记录';

  @override
  String get workbench => '工具台';

  @override
  String get addTagOptional => '添加标签（可选）';

  @override
  String get justNow => '刚刚';

  @override
  String get minutesAgo => '分钟前';

  @override
  String get hoursAgo => '小时前';

  @override
  String get daysAgo => '天前';

  @override
  String get year => '年';

  @override
  String get month => '月';

  @override
  String get day => '日';

  @override
  String get tomorrow => '明天';

  @override
  String get overdue => '已逾期';

  @override
  String get selectDate => '选择日期';

  @override
  String get statusPending => '待处理';

  @override
  String get statusProcessing => '转写中';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusFailed => '失败';

  @override
  String get statusActive => '生效中';

  @override
  String get statusExpired => '已过期';

  @override
  String get freePlan => '免费版';

  @override
  String get typeVoice => '语音';

  @override
  String get typeText => '文本';

  @override
  String get typeOcr => 'OCR';

  @override
  String get recordNotFound => '记录不存在';

  @override
  String get realtimeTranscription => '实时转写';

  @override
  String get realtimeTranscribing => '实时转写中';

  @override
  String get configureRealtimeApi => '请先配置实时转写API';

  @override
  String get gotoConfigure => '未配置API，点击前往配置';

  @override
  String get tapToStopRecording => '点击停止录音';

  @override
  String get tapToStartRecording => '点击开始录音';

  @override
  String get paused => '已暂停';

  @override
  String get recording => '录音中';

  @override
  String get viewRealtimeTranscription => '查看实时转写';

  @override
  String get returnToRecording => '返回录音界面可继续控制录音';

  @override
  String get waitingForVoiceInput => '等待语音输入...';

  @override
  String get originalTranscription => '原始转写文本';

  @override
  String get supplementContent => '补充内容';

  @override
  String get supplementIdeas => '补充完善想法';

  @override
  String get transcriptionResult => '转写结果';

  @override
  String get transcriptionLog => '转写日志';

  @override
  String get aiAnalysisResult => 'AI分析结果';

  @override
  String get relatedRecords => '相关记录';

  @override
  String get originalImage => '原始图片';

  @override
  String get audioSupplement => '录音补充';

  @override
  String get imageSupplement => '图片补充';

  @override
  String get textSupplement => '文本补充';

  @override
  String get noContentAvailable => '无内容';

  @override
  String get hideRecord => '隐藏记录';

  @override
  String get hideRecordConfirm => '隐藏后该记录将不再出现在相关记录列表中。';

  @override
  String get auto => '自动';

  @override
  String get retranscribe => '重新转写';

  @override
  String get retranscribeOptions => '重新转写选项';

  @override
  String get retranscribeAll => '全部转写';

  @override
  String get selectParagraphs => '选择段落';

  @override
  String get selectParagraphsToRetranscribe => '选择要重新转写的段落';

  @override
  String get selectAnalysisRole => '选择分析角色';

  @override
  String get manageRoles => '管理角色';

  @override
  String get selectShareMethod => '选择分享方式';

  @override
  String get analysisExists => '已存在分析结果';

  @override
  String get analysisExistsConfirm => '已有分析结果，是否重新分析？';

  @override
  String get reanalyze => '重新分析';

  @override
  String get analysisComplete => '分析完成';

  @override
  String get analysisFailed => '分析失败';

  @override
  String get noContentToAnalyze => '没有可分析的内容';

  @override
  String get addAiAnalysis => '添加AI分析';

  @override
  String get aiAnalyzing => 'AI正在分析中...';

  @override
  String get tapToAnalyze => '点击 + 使用AI角色分析此记录';

  @override
  String get deleteRecordConfirm => '删除的记录将移至回收站，保留7天后自动清除。是否继续？';

  @override
  String get transcriptionProgress => '转写进度';

  @override
  String get chunkProgress => '分片进度';

  @override
  String get supplementAdded => '补充内容已添加';

  @override
  String get transcribingSupplement => '正在转写补充内容...';

  @override
  String get supplementTranscriptionComplete => '补充内容转写完成';

  @override
  String get selectedParagraphsSuccess => '选定段落转写成功';

  @override
  String get transcriptionSuccess => '转写成功';

  @override
  String get transcriptionSuccessNoContent => '转写完成，但未获取到文本内容';

  @override
  String get pleaseConfigureApiKey => '请先配置API Key';

  @override
  String get noRecordsInPeriod => '该时间段内没有记录';

  @override
  String get pleaseEnterContent => '请输入内容';

  @override
  String get generationFailed => '生成失败';

  @override
  String get audioNotFound => '音频文件不存在';

  @override
  String get fileNotFound => '文件不存在';

  @override
  String get audioInvalid => '音频文件无效';

  @override
  String get playerInitFailed => '播放器初始化失败';

  @override
  String get playbackFailed => '播放失败';

  @override
  String get audioPlayback => '音频播放';

  @override
  String get preparingToShare => '正在准备分享...';

  @override
  String get voiceRecord => '语音记录';

  @override
  String get ocrRecord => 'OCR识别';

  @override
  String get textRecord => '文本记录';

  @override
  String get characters => '字';

  @override
  String get unfavorite => '取消收藏';

  @override
  String get favoriteRecords => '记录收藏';

  @override
  String get noFavoriteRecords => '暂无收藏记录';

  @override
  String get toolOutputFavorites => '工具输出收藏';

  @override
  String get noFavoriteToolOutputs => '暂无收藏的工具输出';

  @override
  String get ocrFailed => '文字识别失败';

  @override
  String get selectImageFailed => '选择图片失败';

  @override
  String get recordSaved => '记录已保存';

  @override
  String get photoOcr => '拍照识别';

  @override
  String get recognitionResult => '识别结果';

  @override
  String get retakePhoto => '重新拍照';

  @override
  String get saveRecord => '保存记录';

  @override
  String get recognizingText => '正在识别文字...';

  @override
  String get quickNote => '速记';

  @override
  String get enterYourThoughts => '在这里输入你的想法';

  @override
  String get quickNoteSaved => '速记已保存';

  @override
  String get smartReminders => '智能提醒';

  @override
  String get addReminder => '添加提醒';

  @override
  String get editReminder => '编辑提醒';

  @override
  String get noReminders => '暂无提醒';

  @override
  String get tapToAddReminder => '点击 + 添加提醒';

  @override
  String get title => '标题';

  @override
  String get description => '描述';

  @override
  String cannotOpenCalendar(String error) {
    return '无法打开日历：$error';
  }

  @override
  String get smartWeeklyReport => '智能周报';

  @override
  String get generating => '生成中...';

  @override
  String get generateReport => '生成周报';

  @override
  String get timeRange => '时间范围';

  @override
  String get reportContent => '周报内容';

  @override
  String get selectTimeRangeHint => '选择时间范围，一键生成周报';

  @override
  String get aiWillSummarize => 'AI将自动汇总该时间段内的所有记录';

  @override
  String get saveReport => '保存周报';

  @override
  String get weeklyReportSaved => '周报已保存';

  @override
  String get knowledgeMindMap => '知识脑图';

  @override
  String get selectTags => '选择标签';

  @override
  String get savePlan => '保存方案';

  @override
  String get planSaved => '方案已保存';

  @override
  String get archiveByTags => '按标签归档';

  @override
  String archivedRecordsCount(Object count) {
    return '已归档 $count 条记录';
  }

  @override
  String get aiMindMapSuccess => 'AI脑图生成成功';

  @override
  String get aiMindMapFailed => 'AI脑图生成失败';

  @override
  String get unnamed => '未命名';

  @override
  String get unnamedTopic => '未命名主题';

  @override
  String get apiAnalysis => 'API调用分析';

  @override
  String get totalCalls => '总调用次数';

  @override
  String get successRate => '成功率';

  @override
  String get textCalls => '文本调用';

  @override
  String get voiceCalls => '语音调用';

  @override
  String get imageCalls => '图片调用';

  @override
  String get failedCalls => '失败次数';

  @override
  String get apiCallTypeDistribution => 'API调用类型分布';

  @override
  String get noToolCallData => '暂无工具调用数据';

  @override
  String get toolCallUsage => '工具调用使用量';

  @override
  String get noDailyCallData => '暂无每日调用数据';

  @override
  String get recent7DaysTrend => '近7天API调用趋势';

  @override
  String get monday => '周一';

  @override
  String get tuesday => '周二';

  @override
  String get wednesday => '周三';

  @override
  String get thursday => '周四';

  @override
  String get friday => '周五';

  @override
  String get saturday => '周六';

  @override
  String get sunday => '周日';

  @override
  String get dataStatistics => '数据统计';

  @override
  String get loadStatsFailed => '加载统计失败';

  @override
  String get accountCenter => '账户中心';

  @override
  String get systemSettings => '系统设置';

  @override
  String get runtimeLogs => '运行日志';

  @override
  String get quickConfigWizard => '快速配置向导';

  @override
  String get multiApiConfig => '多API配置管理';

  @override
  String get aiAnalysisRoles => 'AI分析角色';

  @override
  String get promptTemplateManagement => 'Prompt模板管理';

  @override
  String get toolConfig => '工具方案配置';

  @override
  String get autoAnalysisSettings => '自动分析设置';

  @override
  String get backupManagement => '备份管理';

  @override
  String get personalInfo => '个人信息';

  @override
  String get rechargeCenter => '充值中心';

  @override
  String get confirmLogout => '确认退出';

  @override
  String get logoutConfirmMessage => '退出后将无法使用云端AI服务';

  @override
  String get loginRegister => '登录/注册';

  @override
  String get cloudAiService => '云端AI服务';

  @override
  String get localApiConfig => '本地API配置';

  @override
  String get notLoggedIn => '未登录';

  @override
  String get user => '用户';

  @override
  String get loginRequired => '该功能需要登录后使用';

  @override
  String get goToLogin => '去登录';

  @override
  String get skipLogin => '暂不登录';

  @override
  String get currentPlan => '当前套餐';

  @override
  String get transcriptionQuota => '转写额度';

  @override
  String get quotaDetails => '额度详情';

  @override
  String get purchasePlan => '购买套餐';

  @override
  String get monthlySubscription => '按月订阅';

  @override
  String get planPackage => '套餐包';

  @override
  String get recharge => '充值';

  @override
  String get accountBalance => '账户余额';

  @override
  String get selectRechargeAmount => '选择充值金额';

  @override
  String get orEnterCustomAmount => '或输入自定义金额';

  @override
  String get pleaseEnterAmount => '请输入金额';

  @override
  String get recommended => '推荐';

  @override
  String get buyNow => '立即购买';

  @override
  String get rechargeNow => '立即充值';

  @override
  String get confirmRecharge => '确认充值';

  @override
  String get confirmPurchase => '确认购买';

  @override
  String get otherPaymentMethods => '其他支付方式';

  @override
  String get useBalance => '使用余额';

  @override
  String get transactionHistory => '交易记录';

  @override
  String get noTransactionRecords => '暂无交易记录';

  @override
  String get mySubscription => '我的订阅';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get phoneNumber => '手机号';

  @override
  String get pleaseEnterPhone => '请输入手机号';

  @override
  String get pleaseEnterPassword => '请输入密码';

  @override
  String get forgotPassword => '忘记密码?';

  @override
  String get noAccount => '还没有账号?';

  @override
  String get hasAccount => '已有账号?';

  @override
  String get loginNow => '立即登录';

  @override
  String get registerNow => '立即注册';

  @override
  String get pleaseFillPhoneAndPassword => '请填写手机号和密码';

  @override
  String get pleaseEnterValidPhone => '请输入正确的11位手机号';

  @override
  String get loginFailed => '登录失败，请检查手机号和密码';

  @override
  String get registerAccount => '注册账号';

  @override
  String get createAccount => '创建账号';

  @override
  String get verificationCode => '验证码';

  @override
  String get captcha => '图形验证码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get getVerificationCode => '获取验证码';

  @override
  String get seconds => '秒';

  @override
  String get sendFailed => '发送失败';

  @override
  String get refreshFailed => '刷新失败';

  @override
  String get passwordTooShort => '密码长度不能少于6位';

  @override
  String get passwordsNotMatch => '两次密码不一致';

  @override
  String get registerFailed => '注册失败，请稍后重试';

  @override
  String get welcomeToChangji => '欢迎加入畅记！';

  @override
  String get newUserGift => '已赠送您新手体验包：';

  @override
  String get getStarted => '开始使用';

  @override
  String get accountInfo => '账号信息';

  @override
  String get registrationTime => '注册时间';

  @override
  String get notConfigured => '未配置';

  @override
  String get selectConfig => '选择配置';

  @override
  String get testConnection => '测试连接';

  @override
  String get testingConnection => '正在测试连接...';

  @override
  String get connectionSuccess => '连接成功';

  @override
  String get connectionFailed => '连接失败';

  @override
  String get testError => '测试出错';

  @override
  String get configName => '配置名称';

  @override
  String get custom => '自定义';

  @override
  String get customProviderName => '自定义提供商名称';

  @override
  String get modelName => '模型名称';

  @override
  String get configDeleted => '配置已删除';

  @override
  String get configSaved => '配置已保存';

  @override
  String get fillAllRequired => '请填写所有必填项';

  @override
  String get selectAtLeastOneFeature => '至少选择一个功能';

  @override
  String get featureIncompatible => '功能不兼容';

  @override
  String get apiConfigManagement => 'API配置管理';

  @override
  String get featureAssignment => '功能分配';

  @override
  String get selectProvider => '选择提供商';

  @override
  String get supportedFeatures => '支持的功能';

  @override
  String get checkApiKeyBaseUrlNetwork =>
      '请检查: 1. API Key是否正确 2. Base URL是否正确 3. 网络连接是否正常';

  @override
  String get supportsAiAnalysis => '支持AI分析、摘要、标题生成';

  @override
  String get supportsAudioToText => '支持录音转文字';

  @override
  String get supportsRealtimeTranscription => '支持实时语音转写';

  @override
  String get supportsOfflineTranscription => '支持提交音频文件进行离线转写';

  @override
  String get supportsSpeakerDiarization => '支持区分不同发言人';

  @override
  String get supportsImageRecognition => '支持图片内容识别';

  @override
  String get supportsMultiTurnDialogue => '支持多轮对话';

  @override
  String get textAnalysis => '文本分析';

  @override
  String get voiceTranscription => '语音转写';

  @override
  String get recordThenTranscribe => '录音后转文字';

  @override
  String get realtimeVoiceTranscription => '语音实时转写';

  @override
  String get realtimeTextDuringRecording => '录音时实时转文字';

  @override
  String get offlineVoiceTranscription => '离线语音转写';

  @override
  String get imageRecognition => '图像识别';

  @override
  String get speakerDiarization => '说话人分离';

  @override
  String get dialogue => '对话';

  @override
  String get offlineTranscription => '离线转写';

  @override
  String get wizardSuccess => '配置成功！畅记已准备就绪';

  @override
  String get wizardSaveFailed => '保存失败，请重试';

  @override
  String get wizardInvalidApiKey => 'API Key无效，请检查后重试';

  @override
  String get wizardVerifyFailed => '验证失败';

  @override
  String get wizardConfigureLater => '稍后配置';

  @override
  String get wizardVerifyAndSave => '验证并保存';

  @override
  String get verifying => '验证中...';

  @override
  String get saving => '保存中...';

  @override
  String get roleName => '角色名称';

  @override
  String get roleDescription => '角色描述';

  @override
  String get systemPrompt => '系统提示词（Prompt）';

  @override
  String get nameAndPromptRequired => '名称和Prompt不能为空';

  @override
  String get confirmDeleteRole => '确认删除角色';

  @override
  String get editAndConvertToCustom => '编辑并转为自定义';

  @override
  String get enableAutoAnalysis => '启用自动分析';

  @override
  String get autoAnalysisDescription => '转写完成后自动进行AI分析';

  @override
  String get viewMoreTemplates => '查看更多模板...';

  @override
  String get selectTemplate => '选择模板方案';

  @override
  String get settingsSaved => '设置已保存';

  @override
  String get defaultTemplateUpdated => '默认模板已更新';

  @override
  String get templateDeleted => '模板已删除';

  @override
  String get templateSaved => '模板已保存';

  @override
  String get systemDefaultTemplateCannotDelete => '系统默认模板不能删除';

  @override
  String get deleteTemplate => '删除模板';

  @override
  String get confirmDeleteTemplate => '确定要删除这个模板吗？';

  @override
  String get templateName => '模板名称';

  @override
  String get shortDescription => '简短描述';

  @override
  String get category => '分类';

  @override
  String get templateContent => '模板内容';

  @override
  String get useContentPlaceholder => '使用 [content] 作为内容占位符';

  @override
  String get fillTemplateNameAndContent => '请填写模板名称和内容';

  @override
  String confirmDeleteTemplateNamed(Object name) {
    return '确定要删除模板「$name」吗？此操作不可撤销。';
  }

  @override
  String get setAsDefault => '设为默认';

  @override
  String get setAsDefaultTemplate => '设为默认模板';

  @override
  String get analysisTemplateSettings => '分析模板设置';

  @override
  String get inputSystemPrompt => '输入AI分析时使用的系统提示词...';

  @override
  String get backupName => '备份名称（可选）';

  @override
  String get includeMediaFiles => '包含媒体文件';

  @override
  String get createBackup => '创建备份';

  @override
  String get importBackup => '导入备份';

  @override
  String get restoreBackup => '恢复此备份';

  @override
  String get shareBackup => '分享备份';

  @override
  String get backupFailed => '备份失败';

  @override
  String get importSuccess => '导入成功';

  @override
  String get importFailed => '导入失败';

  @override
  String get restoreSuccess => '恢复成功';

  @override
  String get restoreFailed => '恢复失败';

  @override
  String get confirmRestore => '确认恢复';

  @override
  String get backupFileNotFound => '备份文件不存在';

  @override
  String get deleteBackup => '删除备份';

  @override
  String get leaveEmptyForDefault => '留空将使用默认名称';

  @override
  String get recycleBin => '回收站';

  @override
  String get emptyRecycleBin => '清空回收站';

  @override
  String get recycleBinEmptied => '回收站已清空';

  @override
  String get confirmPermanentDelete => '确认永久删除';

  @override
  String get permanentDeleteConfirm => '此操作不可恢复，是否继续？';

  @override
  String get permanentlyDeleted => '已永久删除';

  @override
  String get copyFilteredLogs => '复制筛选后的日志';

  @override
  String get copyAllLogs => '复制全部日志';

  @override
  String get clearLogs => '清空日志';

  @override
  String get searchLogs => '搜索日志...';

  @override
  String get allTags => '全部标签';

  @override
  String get filteredLogsCopied => '筛选后的日志已复制到剪贴板';

  @override
  String get allLogsCopied => '全部日志已复制到剪贴板';

  @override
  String get singleLogCopied => '已复制单条日志';

  @override
  String get confirmClearLogs => '确认清空';

  @override
  String get clearLogsConfirm => '确定要清空所有日志吗？';

  @override
  String get enterNewTag => '输入新标签';

  @override
  String get searchTools => '搜索工具';

  @override
  String get searchOutputContent => '搜索输出内容...';

  @override
  String get searchRolesOrTemplates => '搜索角色或模板...';

  @override
  String get toolOutputs => '工具台输出';

  @override
  String get toolOutputTitle => '工具台输出';

  @override
  String get toolOutputContent => '内容';

  @override
  String get deleteOutputConfirm => '删除后无法恢复，是否继续？';

  @override
  String get saveResult => '保存结果';

  @override
  String get inputSaveName => '输入保存名称';

  @override
  String get name => '名称';

  @override
  String get inputName => '输入保存名称';

  @override
  String get enterContent => '请输入内容';

  @override
  String get fullScreen => '全屏查看';

  @override
  String get selectAll => '全选';

  @override
  String get moreActions => '更多操作';

  @override
  String get addToCalendar => '添加到日历';

  @override
  String get favorite => '收藏';

  @override
  String get layout => '布局方式';

  @override
  String get sortTools => '排序工具';

  @override
  String get showHideTools => '显示/隐藏工具';

  @override
  String get restoreDefault => '恢复默认';

  @override
  String get toolDisplaySettings => '工具显示设置';

  @override
  String get max5ToolsOnHome => '首页最多显示5个工具';

  @override
  String get homeToolsCannotHide => '展示在首页的工具不得隐藏';

  @override
  String get selectAtLeastOneDataSource => '请至少选择一种数据源';

  @override
  String get noDataSourceAvailable => '没有可用的数据源';

  @override
  String get planName => '方案名称';

  @override
  String get planContent => '方案内容';

  @override
  String get saveTemporaryPlan => '保存临时方案';

  @override
  String get inputAiPrompt => '输入AI的系统提示词';

  @override
  String get bold => '加粗';

  @override
  String get italic => '斜体';

  @override
  String get underline => '下划线';

  @override
  String get strikethrough => '删除线';

  @override
  String get largeHeading => '大标题';

  @override
  String get smallHeading => '小标题';

  @override
  String get orderedList => '有序列表';

  @override
  String get unorderedList => '无序列表';

  @override
  String get inlineCode => '行内代码';

  @override
  String get emoji => '表情符号';

  @override
  String get shareFailed => '分享失败';

  @override
  String get recordingSaved => '录音已保存';

  @override
  String get microphonePermissionRequired => '需要麦克风权限';

  @override
  String get startRecordingFailed => '开始录音失败';

  @override
  String get stopRecordingFailed => '停止录音失败';

  @override
  String get imageSelectionNotImplemented => '图片选择功能待实现';

  @override
  String get addYourThoughts => '在此补充你的想法...';

  @override
  String get inputContent => '输入内容';

  @override
  String remainingRecords(Object count) {
    return '还有$count条相关记录';
  }

  @override
  String relatedRecordCount(Object count) {
    return '$count条';
  }

  @override
  String get transcriptionCompleteWithResult => '转写完成！';

  @override
  String get processingAllUntranscribed => '将处理所有未正常转写的录音，是否继续？';

  @override
  String get wizardStep1Title => '3步完成AI服务配置，推荐新手使用';

  @override
  String get viewLogsDesc => '查看APP运行日志，用于排查问题';

  @override
  String get multiApiDesc => '为语音/图像/文本配置独立API，支持多平台';

  @override
  String get roleManagementDesc => '管理系统角色和自定义分析角色';

  @override
  String get templateManagementDesc => '管理内置和自定义AI分析模板';

  @override
  String get toolTemplateDesc => '管理各工具的AI模板，支持新增和删除';

  @override
  String get autoAnalysisDesc => '转写完成后自动进行AI分析';

  @override
  String get statisticsDesc => '查看记录趋势和热门标签';

  @override
  String get apiAnalysisDesc => '查看API调用统计和工具使用量';

  @override
  String get dataManagementDesc => '数据备份、导出和恢复';

  @override
  String get recycleBinDesc => '查看和管理已删除的记录';

  @override
  String get cloudAiDesc => '解锁云端AI服务，注册送100分钟';

  @override
  String get useOwnApiKey => '使用自己的API Key';

  @override
  String get aiConfig => 'AI配置';

  @override
  String get debugTools => '调试工具';

  @override
  String get viewLogs => '运行日志';

  @override
  String get quickConfigWizardDesc => '3步完成AI服务配置，推荐新手使用';

  @override
  String get multiApiConfigDesc => '为语音/图像/文本配置独立API，支持多平台';

  @override
  String get aiRoleManagement => 'AI角色管理';

  @override
  String get aiAnalysisRolesDesc => '管理系统角色和自定义分析角色';

  @override
  String get promptTemplateManagementDesc => '管理内置和自定义AI分析模板';

  @override
  String get toolAiConfig => '工具AI配置';

  @override
  String get toolConfigDesc => '以下是各工具的模板配置，系统默认模板不能删除，可设置默认模板';

  @override
  String get autoAnalysis => '自动分析';

  @override
  String get usageStatsDesc => '查看记录趋势和热门标签';

  @override
  String get apiCallAnalysis => 'API调用分析';

  @override
  String get apiCallAnalysisDesc => '查看API调用统计和工具使用量';

  @override
  String get backupManagementDesc => '数据备份、导出和恢复';

  @override
  String get accountManagement => '账户管理';

  @override
  String get loginRegisterDesc => '解锁云端AI服务，注册送100分钟';

  @override
  String get transactionRecords => '交易记录';

  @override
  String get aiServiceConfig => 'AI服务配置';

  @override
  String get cloudAiServiceLoggedIn => '使用云端分配的API Key';

  @override
  String get cloudAiServiceNotLoggedIn => '登录后开启云端AI服务';

  @override
  String minutesUsed(Object total, Object used) {
    return '已用 $used / $total 分钟';
  }

  @override
  String get save => '保存';

  @override
  String get functionAssignment => '功能分配';

  @override
  String get functionAssignmentDesc => '为不同功能选择使用的API配置，仅显示支持该功能的模型';

  @override
  String get textAnalysisDesc => 'AI分析、摘要、标题生成';

  @override
  String get voiceTranscriptionDesc => '录音后转文字';

  @override
  String get realtimeVoiceTranscriptionDesc => '录音时实时转文字';

  @override
  String get offlineVoiceTranscriptionDesc => '提交音频文件进行离线转写（支持说话人分离）';

  @override
  String get imageRecognitionDesc => '图片内容识别（OCR）';

  @override
  String get incompatible => '不兼容';

  @override
  String get featureMismatch => '功能不匹配';

  @override
  String get apiConfigList => 'API配置列表';

  @override
  String get noApiConfig => '暂无API配置';

  @override
  String get addApiConfigHint => '点击右下角 + 添加配置';

  @override
  String get connectionSuccessDetail => 'API配置有效，可以正常使用。';

  @override
  String connectionFailedDetail(Object code) {
    return '状态码: $code\n请检查API Key和Base URL是否正确。';
  }

  @override
  String get editConfig => '编辑配置';

  @override
  String get addConfig => '添加配置';

  @override
  String get configNameHint => '例如：OpenAI-文本';

  @override
  String get autoFilterIncompatible => '已自动过滤不兼容功能';

  @override
  String get noCompatibleFunctions => '暂无可用的功能支持，请选择其他提供商。';

  @override
  String get providerCapabilityDesc => '能力说明';

  @override
  String get model => '模型';

  @override
  String get apiKey => 'API Key';

  @override
  String get appId => 'App ID';

  @override
  String get accessKeySecret => 'AccessKey Secret';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get modelNameHint => '例如：gpt-4o-mini';

  @override
  String get deleteConfig => '删除配置';

  @override
  String get scenarioMeeting => '会议/沟通记录';

  @override
  String get scenarioMeetingDesc => '客户沟通、团队会议、电话录音';

  @override
  String get scenarioIdea => '灵感/创意捕捉';

  @override
  String get scenarioIdeaDesc => '随时记录想法，AI帮你梳理';

  @override
  String get scenarioStudy => '学习/课堂笔记';

  @override
  String get scenarioStudyDesc => '课程录音、读书笔记、知识整理';

  @override
  String get scenarioAll => '全部场景';

  @override
  String get scenarioAllDesc => '录音转写 + AI分析，完整体验';

  @override
  String get step1Title => '第一步：你的主要场景是？';

  @override
  String get step2Title => '第二步：选择AI服务商';

  @override
  String get step3Title => '第三步：输入API Key';

  @override
  String get providerRecommendDesc => '推荐以下服务商（按性价比排序）';

  @override
  String get wizardTip => '提示：你只需要填API Key，其他参数已自动配置好';

  @override
  String get rankRecommended => '推荐';

  @override
  String get rankAlternative => '备选';

  @override
  String get transcription => '转写';

  @override
  String get aiAnalysis => 'AI分析';

  @override
  String get pricing => '价格';

  @override
  String inputApiKeyHint(Object provider) {
    return '填入你的 $provider API Key 即可完成配置';
  }

  @override
  String get modelLabel => '模型';

  @override
  String get transcriptionModel => '转写模型';

  @override
  String get apiKeySecurity => '你的API Key仅存储在本地设备，加密保存，不会上传到任何第三方服务器。';

  @override
  String get noApiKey => '没有API Key？';

  @override
  String getApiKeyGuide(Object provider) {
    return '前往 $provider 平台获取 API Key';
  }

  @override
  String get getApiKeyGeneric => '前往服务商官网获取 API Key';

  @override
  String get verifyAndSave => '验证并保存';

  @override
  String get systemRoles => '系统角色';

  @override
  String get customRoles => '自定义';

  @override
  String get templateLibrary => '模板库';

  @override
  String get noCustomRoles => '暂无自定义角色';

  @override
  String get addCustomRoleHint => '点击右下角 + 创建你的专属AI角色';

  @override
  String get categoryFrequentlyUsed => '常用';

  @override
  String get categoryGeneral => '通用';

  @override
  String get categorySolopreneur => '一人公司';

  @override
  String get categoryBusiness => '商业';

  @override
  String get categoryProductivity => '效率';

  @override
  String get categoryCreative => '创意';

  @override
  String get categoryLearning => '学习';

  @override
  String get categoryLife => '生活';

  @override
  String get categoryFun => '趣味';

  @override
  String usedCount(Object count) {
    return '使用$count次';
  }

  @override
  String get prompt => '提示词（Prompt）';

  @override
  String get edit => '编辑';

  @override
  String get editRole => '编辑角色';

  @override
  String get newRole => '新建角色';

  @override
  String get roleNameHint => '输入角色名称';

  @override
  String get roleDescriptionHint => '输入角色描述';

  @override
  String get systemPromptHint => '输入系统提示词，定义AI的角色和行为...';

  @override
  String deleteRoleConfirm(Object name) {
    return '确定要删除角色「$name」吗？此操作不可恢复。';
  }

  @override
  String get selectAutoAnalysisPlan => '选择自动分析方案';

  @override
  String get selectAutoAnalysisPlanDesc => '选择转写后自动使用的分析角色或模板';

  @override
  String get enableAutoAnalysisFirst => '请先启用自动分析开关';

  @override
  String get noAvailableRoles => '暂无可用角色';

  @override
  String get addFromTemplateLibrary => '从模板库添加方案';

  @override
  String get added => '已添加';

  @override
  String get autoAnalysisInstructions => '说明';

  @override
  String get autoAnalysisInstruction1 => '• 开启自动分析后，录音转写完成将自动使用所选方案进行分析';

  @override
  String get autoAnalysisInstruction2 => '• 自动分析会消耗API调用次数，请确保API配置正确';

  @override
  String get autoAnalysisInstruction3 => '• 可以从模板库添加方案，也可以直接使用系统或自定义角色';

  @override
  String get autoAnalysisInstruction4 => '• 保存的模板方案会独立存储，即使模板库更新也不会丢失';

  @override
  String get toolConfigTitle => '工具方案配置';

  @override
  String get allCategories => '全部';

  @override
  String get productivityTools => '效率工具';

  @override
  String get analysisTools => '分析工具';

  @override
  String get managementTools => '管理工具';

  @override
  String get aiTools => 'AI工具';

  @override
  String get newTemplate => '新建模板';

  @override
  String get defaultLabel => '默认';

  @override
  String addTemplateFor(Object tool) {
    return '为$tool新增模板';
  }

  @override
  String get templateNameHint => '输入模板名称';

  @override
  String get descriptionHint => '简要描述这个模板的用途';

  @override
  String get aiPrompt => '系统提示词';

  @override
  String get aiPromptHint => '输入AI的系统提示词';

  @override
  String get editTemplate => '编辑模板';

  @override
  String get fillNameAndPrompt => '请填写名称和提示词';

  @override
  String get localBackupManagement => '本地备份管理';

  @override
  String get creating => '创建中...';

  @override
  String get backupNow => '立即备份';

  @override
  String get restoreFromFile => '从文件恢复';

  @override
  String get restoring => '恢复中...';

  @override
  String get noBackups => '暂无备份';

  @override
  String get createFirstBackup => '点击\"立即备份\"创建您的第一个备份';

  @override
  String recordsCount(Object count) {
    return '$count 条记录';
  }

  @override
  String get restoreThisBackup => '恢复此备份';

  @override
  String get backupNameHint => '留空将使用默认名称';

  @override
  String get selectBackupContent => '选择备份内容';

  @override
  String get recordsData => '记录数据';

  @override
  String get recordsDataDesc => '所有录音记录、文本、标签、周报、脑图等';

  @override
  String get aiConfigBackup => 'AI 配置';

  @override
  String get aiConfigBackupDesc => 'API密钥、AI角色、Prompt模板、分析模板、自动分析设置';

  @override
  String get includeMediaFilesDesc => '音频、图片等附件（会显著增加备份大小）';

  @override
  String get restoreConfirmTitle => '确认恢复';

  @override
  String get restoreConfirmMessage =>
      '恢复备份将覆盖当前所有数据（包括记录、设置等）。\n\n此操作不可撤销，是否继续？';

  @override
  String get backupNotFound => '备份文件不存在';

  @override
  String backupShareText(Object name) {
    return '畅记备份: $name';
  }

  @override
  String deleteBackupConfirm(Object name) {
    return '确定要删除备份 \"$name\" 吗？';
  }

  @override
  String get empty => '清空';

  @override
  String get recycleBinEmpty => '回收站为空';

  @override
  String get recycleBinRetention => '删除的记录将在这里保留7天';

  @override
  String remainingDays(int count) {
    return '还剩$count天';
  }

  @override
  String get willBeClearedSoon => '即将清除';

  @override
  String createdAt(Object date) {
    return '创建于 $date';
  }

  @override
  String deletedAt(Object date) {
    return '删除于 $date';
  }

  @override
  String get permanentDelete => '永久删除';

  @override
  String clearRecordsConfirm(Object count) {
    return '将永久删除$count条记录，此操作不可恢复，是否继续？';
  }

  @override
  String get logScreenTitle => '运行日志';

  @override
  String get selectTagFilter => '选择标签筛选';

  @override
  String tagFilter(Object tag) {
    return '标签: $tag';
  }

  @override
  String get allLevels => '全部';

  @override
  String get levelInfo => '信息';

  @override
  String get levelWarning => '警告';

  @override
  String get levelError => '错误';

  @override
  String get noLogs => '暂无日志';

  @override
  String showingCount(Object count) {
    return '显示 $count 条';
  }

  @override
  String totalCount(Object count) {
    return '总计 $count 条';
  }

  @override
  String get weeklyReportTemplate => '周报模板';

  @override
  String get mindMapTemplate => '脑图模板';

  @override
  String get system => '系统';

  @override
  String get templateDescription => '模板描述';

  @override
  String get systemPromptLabel => 'System Prompt';

  @override
  String get noTemplates => '暂无模板';

  @override
  String get createNewTemplateHint => '点击右上角 + 创建新模板';

  @override
  String get builtIn => '内置';

  @override
  String get templateDetail => '模板详情';

  @override
  String get templateContentLabel => '模板内容';

  @override
  String get editTemplateTitle => '编辑模板';

  @override
  String get createTemplateTitle => '创建新模板';

  @override
  String get shortDescriptionHint => '一句话描述模板用途';

  @override
  String get contentPlaceholderHint => '提示：使用 [content] 表示用户录音/笔记内容的位置';

  @override
  String get saveChanges => '保存修改';

  @override
  String get createTemplate => '创建模板';

  @override
  String get templateUpdated => '模板已更新';

  @override
  String get templateCreated => '模板已创建';

  @override
  String get loginSubtitle => '登录后解锁云端AI服务';

  @override
  String get password => '密码';

  @override
  String get registerGift => '注册即送100分钟体验额度';

  @override
  String get newUserGiftDetail => '100分钟转写额度，有效期7天';

  @override
  String get minutes => '分钟';

  @override
  String get retryFailedTranscriptions => '重新转写';

  @override
  String get retryFailedTranscriptionsConfirm => '将处理所有未正常转写的录音，是否继续？';

  @override
  String get retranscribeSuccess => '转写成功';

  @override
  String get retranscribeError => '转写失败';

  @override
  String get generateResult => '生成结果';

  @override
  String get savedResults => '已保存的结果';

  @override
  String savedResultCount(Object count) {
    return '$count 份';
  }

  @override
  String get noSavedResults => '暂无保存的结果';

  @override
  String get sendEmail => '发送邮件';

  @override
  String get sendEmailDesc => '调用系统邮件客户端';

  @override
  String get addToCalendarDesc => '创建日程提醒';

  @override
  String get copyAll => '复制全部';

  @override
  String get copyAllDesc => '复制到剪贴板';

  @override
  String get shareDesc => '分享到其他应用';

  @override
  String get template => '模板';

  @override
  String get defaultTemplate => '默认';

  @override
  String get expand => '收起';

  @override
  String get switchTemplate => '切换';

  @override
  String get aiAnalyzingData => 'AI正在分析数据...';

  @override
  String get usingTemplate => '使用模板';

  @override
  String get noTools => '暂无工具';

  @override
  String get addToolsInSettings => '请在设置中添加工具';

  @override
  String get recentlyUsed => '最近使用';

  @override
  String get workbenchSettings => '工作台设置';

  @override
  String get cardLayout => '卡片式';

  @override
  String get listLayout => '列表式';

  @override
  String get reorderTools => '拖拽调整工具顺序';

  @override
  String get customizeVisibleTools => '自定义显示哪些工具';

  @override
  String get resetToInitialLayout => '重置为初始布局';

  @override
  String get settingsRestored => '已恢复默认设置';

  @override
  String get tagManagement => '标签管理';

  @override
  String get selectedTags => '已选标签';

  @override
  String get availableTags => '可选标签';

  @override
  String get noMatchingOutputs => '没有符合条件的输出';

  @override
  String get adjustSearchCriteria => '尝试调整搜索条件';

  @override
  String get toolOutputSavedHint => '使用工具后保存的内容会显示在这里';

  @override
  String get delete => '删除';

  @override
  String get addedToCalendar => '已添加到日历';

  @override
  String get days => '天';

  @override
  String get records => '记录';

  @override
  String get toolOutput => '工具输出';

  @override
  String get aiAnalysisSummary => 'AI分析摘要';

  @override
  String selectedItems(int count) {
    return '已选 $count 项';
  }

  @override
  String get selected => '已选';

  @override
  String get selectAiRole => '选择AI角色';

  @override
  String get searchRoleOrTemplate => '搜索角色或模板...';

  @override
  String get noMatchingSystemRole => '没有匹配的系统角色';

  @override
  String get noCustomRole => '暂无自定义角色';

  @override
  String get clickToCreateRole => '点击创建你的角色';

  @override
  String get noTemplate => '暂无模板';

  @override
  String get dataPreview => '数据预览';

  @override
  String get dataSourceConfig => '数据源配置';

  @override
  String get confirmAndExecute => '确认并执行';

  @override
  String get pleaseSelectAtLeastOneDataSource => '请至少选择一种数据源';

  @override
  String get dataConfirm => '数据确认';

  @override
  String get ai => 'AI';

  @override
  String get efficiency => '效率';

  @override
  String get analysis => '分析';

  @override
  String get management => '管理';

  @override
  String get homeToolsCannotBeHidden => '首页工具不能隐藏';

  @override
  String get homeMaxFiveTools => '首页最多5个工具';

  @override
  String get hidden => '隐藏';

  @override
  String toolsSelectedForHomeDisplay(int count) {
    return '已选择$count个工具在首页显示';
  }

  @override
  String get toolName => '工具名称';

  @override
  String get showOnHome => '在首页显示';

  @override
  String get apiKeyRequired => 'API密钥不能为空';

  @override
  String get modelNameRequired => '模型名称不能为空';

  @override
  String get unknownError => '未知错误';

  @override
  String get baseUrlHint => '可选：自定义API基础URL';

  @override
  String get securityNotice => '安全提示';

  @override
  String get securityNoticeDetail => '您的API密钥仅存储在本地，不会上传到服务器';

  @override
  String get apiKeyWizard => 'API密钥向导';

  @override
  String get prevStep => '上一步';

  @override
  String get selectProviderDesc => '选择AI服务提供商';

  @override
  String get customProviderDesc => '输入自定义提供商详情';

  @override
  String get selectFeatures => '选择功能';

  @override
  String get selectFeaturesDesc => '选择要启用的功能';

  @override
  String get enterApiKey => '输入API密钥';

  @override
  String get enterApiKeyDesc => '为选定的提供商输入API密钥';

  @override
  String get customProviderNameHint => '自定义提供商名称';

  @override
  String get confirmConfig => '确认配置';

  @override
  String get confirmConfigDesc => '请确认您的API配置';

  @override
  String get provider => '提供商';

  @override
  String get selectedFeatures => '已选功能';

  @override
  String get finish => '完成';

  @override
  String get nextStep => '下一步';

  @override
  String get enterCustomProviderName => '请输入自定义提供商名称';

  @override
  String get appIdRequired => 'App ID不能为空';

  @override
  String get noPromptTemplates => '暂无提示模板';

  @override
  String get addPromptTemplateHint => '添加新的提示模板';

  @override
  String get analysisModel => '分析模型';

  @override
  String get summaryModel => '摘要模型';

  @override
  String get qwenRealtime => '通义千问实时';

  @override
  String get qwenAudio => '通义千问音频';

  @override
  String get paraformerRealtime => 'Paraformer实时';

  @override
  String get paraformer => 'Paraformer';

  @override
  String get qwenMax => '通义千问Max';

  @override
  String get qwenPlus => '通义千问Plus';

  @override
  String get qwenTurbo => '通义千问Turbo';

  @override
  String get deepseekChat => 'DeepSeek Chat';

  @override
  String get deepseekReasoner => 'DeepSeek Reasoner';

  @override
  String get text => '文本';

  @override
  String get voice => '语音';

  @override
  String get image => '图片';

  @override
  String moreTools(int count) {
    return '还有$count个';
  }

  @override
  String get recent7DaysApiTrend => '近7天API调用趋势';

  @override
  String get permanentDeleteMessage => '此操作不可恢复，确定要永久删除这条记录吗？';

  @override
  String get emptyRecycleBinMessage => '回收站中的所有记录将被永久删除，此操作不可撤销。';

  @override
  String get emptyRecycleBinSuccess => '回收站已清空';

  @override
  String get noDeletedNotes => '没有已删除的笔记';

  @override
  String get deletedNotesHint => '删除的笔记将在这里保留7天';

  @override
  String get restore => '恢复';

  @override
  String get untitledNote => '未命名笔记';

  @override
  String get clearLogsSuccess => '日志已清空';

  @override
  String get clearLogsFailed => '清空日志失败';

  @override
  String get copySuccess => '复制成功';

  @override
  String get logViewer => '日志查看器';

  @override
  String get copyLogs => '复制日志';

  @override
  String get shareLogs => '分享日志';

  @override
  String get loadLogsFailed => '加载日志失败';

  @override
  String get noLogsHint => '暂无日志';

  @override
  String get autoAnalysisSwitch => '自动分析';

  @override
  String get autoAnalysisEnabled => '启用自动分析';

  @override
  String get autoAnalysisEnabledDesc => '转写完成后自动进行分析';

  @override
  String get analysisMode => '分析模式';

  @override
  String get quickAnalysis => '快速分析';

  @override
  String get quickAnalysisDesc => '快速分析，生成基础摘要';

  @override
  String get standardAnalysis => '标准分析';

  @override
  String get standardAnalysisDesc => '平衡分析，适中详细程度';

  @override
  String get deepAnalysis => '深度分析';

  @override
  String get deepAnalysisDesc => '详细分析，提供全面洞察';

  @override
  String get analysisDelay => '分析延迟';

  @override
  String get delaySeconds => '延迟秒数';

  @override
  String get delaySecondsDesc => '转写完成后延迟多久开始分析';

  @override
  String get autoAnalysisItems => '自动分析项目';

  @override
  String get autoSummarize => '自动摘要';

  @override
  String get autoSummarizeDesc => '自动生成内容摘要';

  @override
  String get autoExtractTasks => '自动提取任务';

  @override
  String get autoExtractTasksDesc => '自动从内容中提取任务';

  @override
  String get autoSuggestTags => '自动建议标签';

  @override
  String get autoSuggestTagsDesc => '自动为内容建议标签';

  @override
  String get analysisTemplate => '分析模板';

  @override
  String get noAnalysisTemplates => '暂无分析模板';

  @override
  String get addAnalysisTemplateHint => '点击 + 添加新的分析模板';

  @override
  String get templateDescriptionHint => '输入模板描述';

  @override
  String get templatePrompt => '模板提示词';

  @override
  String get templatePromptHint => '输入此模板的AI提示词';

  @override
  String get setAsDefaultDesc => '设为默认分析模板';

  @override
  String get addTemplate => '添加模板';

  @override
  String get templateNameRequired => '模板名称不能为空';

  @override
  String confirmDeleteTemplateMessage(String name) {
    return '确定要删除模板「$name」吗？';
  }

  @override
  String get backupSuccess => '备份创建成功';

  @override
  String get confirmRestoreMessage => '恢复将覆盖当前数据，是否继续？';

  @override
  String get confirmDeleteBackup => '删除备份';

  @override
  String get confirmDeleteBackupMessage => '确定要删除此备份吗？';

  @override
  String get createBackupHint => '点击「创建备份」创建您的第一个备份';

  @override
  String get retry => '重试';

  @override
  String get summary => '摘要';

  @override
  String get chat => '聊天';

  @override
  String get promptContent => '提示词内容';

  @override
  String get promptContentHint => '输入提示词内容';

  @override
  String get editPromptTemplate => '编辑提示模板';

  @override
  String get addPromptTemplate => '添加提示模板';

  @override
  String get inputYourThoughts => '输入你的想法...';

  @override
  String get roleManagement => '角色管理';

  @override
  String get noRoles => '暂无角色';

  @override
  String get addRoleHint => '点击 + 添加角色';

  @override
  String get addRole => '添加角色';

  @override
  String get rolePrompt => '角色提示词';

  @override
  String get rolePromptHint => '输入此角色的系统提示词';

  @override
  String get roleNameRequired => '角色名称不能为空';

  @override
  String confirmDeleteRoleMessage(String name) {
    return '确定要删除角色「$name」吗？';
  }
}
