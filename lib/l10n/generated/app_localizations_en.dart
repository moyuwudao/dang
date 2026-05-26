// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Changji';

  @override
  String get appTagline => 'AI Voice Notes for One-Person Companies';

  @override
  String get homeTitle => 'My Notes';

  @override
  String get recordButton => 'Record';

  @override
  String get stopButton => 'Stop';

  @override
  String get pauseButton => 'Pause';

  @override
  String get resumeButton => 'Resume';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButton => 'Save';

  @override
  String get deleteButton => 'Delete';

  @override
  String get editButton => 'Edit';

  @override
  String get shareButton => 'Share';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get apiKeySettings => 'API Key Settings';

  @override
  String get openaiApiKey => 'OpenAI API Key';

  @override
  String get apiKeyHint => 'Enter your OpenAI API key';

  @override
  String get apiKeyHelp => 'Your API key is stored locally and never shared';

  @override
  String get themeSettings => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System Default';

  @override
  String get languageSettings => 'Language';

  @override
  String get english => 'English';

  @override
  String get chinese => 'Chinese';

  @override
  String get recordingTitle => 'Recording';

  @override
  String get recordingInProgress => 'Recording in progress...';

  @override
  String get tapToStop => 'Tap to stop';

  @override
  String get ocrTitle => 'OCR Scan';

  @override
  String get ocrDescription =>
      'Take a photo or select an image to extract text';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get selectImage => 'Select from Gallery';

  @override
  String get transcribeTitle => 'Transcribe';

  @override
  String get transcribeDescription => 'Convert voice to text using AI';

  @override
  String get transcribing => 'Transcribing...';

  @override
  String get transcribeSuccess => 'Transcription complete';

  @override
  String get transcribeError => 'Transcription failed';

  @override
  String get retryButton => 'Retry';

  @override
  String get noRecords => 'No records yet';

  @override
  String get createFirstRecord =>
      'Tap the microphone to create your first note';

  @override
  String get searchHint => 'Search notes...';

  @override
  String get allNotes => 'All Notes';

  @override
  String get favorites => 'Favorites';

  @override
  String get tags => 'Tags';

  @override
  String get addTag => 'Add Tag';

  @override
  String get untitled => 'Untitled';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get confirmDelete => 'Are you sure you want to delete?';

  @override
  String get confirmDeleteTitle => 'Confirm Delete';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get microphonePermission =>
      'Microphone access is required for recording';

  @override
  String get cameraPermission => 'Camera access is required for OCR';

  @override
  String get storagePermission =>
      'Storage access is required to save recordings';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'Network error. Please check your connection.';

  @override
  String get errorApiKey => 'Invalid API key. Please check your settings.';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get dataBackup => 'Data Backup';

  @override
  String get dataRestore => 'Data Restore';

  @override
  String get exportData => 'Export Data';

  @override
  String get importData => 'Import Data';

  @override
  String get clearData => 'Clear All Data';

  @override
  String get clearDataConfirm =>
      'This will permanently delete all your records. This action cannot be undone.';

  @override
  String get recordQuality => 'Recording Quality';

  @override
  String get recordFormat => 'Recording Format';

  @override
  String get highQuality => 'High Quality';

  @override
  String get mediumQuality => 'Medium Quality';

  @override
  String get lowQuality => 'Low Quality';

  @override
  String get helpAndFeedback => 'Help & Feedback';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get rateApp => 'Rate App';

  @override
  String get shareApp => 'Share App';

  @override
  String get textInput => 'Text Input';

  @override
  String get textInputHint => 'Enter text content here...';

  @override
  String get usageStatistics => 'Usage Statistics';

  @override
  String get usageStatsDetail => 'Usage Details';

  @override
  String get usageStatsClear => 'Clear Statistics';

  @override
  String get usageStatsClearConfirm =>
      'Are you sure you want to clear all usage statistics? This action cannot be undone.';

  @override
  String get usageStatsEmpty => 'No usage data yet';

  @override
  String get usageStatsEmptyHint => 'Use AI features to see statistics';

  @override
  String get calls => 'calls';

  @override
  String get tokens => 'tokens';

  @override
  String get lastUsed => 'Last used';

  @override
  String get features => 'Features';

  @override
  String get cancel => 'Cancel';

  @override
  String get clear => 'Clear';

  @override
  String get frequentlyUsedTemplates => 'Frequently Used';

  @override
  String get noMatchingTool => 'No matching tools';

  @override
  String get frequentlyUsedTools => 'Frequently Used';

  @override
  String get createRole => 'Create Role';

  @override
  String get selectDataSourceType => 'Select Data Source';

  @override
  String get noTags => 'No tags';

  @override
  String get noToolOutputData => 'No tool output data';

  @override
  String associatedRecords(int count) {
    return '$count related records';
  }

  @override
  String get dateRange => 'Date Range';

  @override
  String get includeAiAnalysis => 'Include AI Analysis';

  @override
  String get includeAiAnalysisDesc =>
      'Include AI analysis content as input data';

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
  String get add => 'Add';

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
  String get month => '/';

  @override
  String get day => '';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get overdue => 'Overdue';

  @override
  String get selectDate => 'Select Date';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusProcessing => '转写中';

  @override
  String get statusCompleted => 'Completed';

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
  String get pleaseEnterContent => 'Please enter content';

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
  String get quickNoteSaved => 'Quick note saved';

  @override
  String get smartReminders => 'Smart Reminders';

  @override
  String get addReminder => 'Add Reminder';

  @override
  String get editReminder => 'Edit Reminder';

  @override
  String get noReminders => 'No Reminders';

  @override
  String get tapToAddReminder => 'Tap + to add a reminder';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String cannotOpenCalendar(String error) {
    return 'Cannot open calendar: $error';
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
  String get seconds => 's';

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
  String get custom => 'Custom';

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
  String get saving => 'Saving...';

  @override
  String get roleName => 'Role Name';

  @override
  String get roleDescription => 'Role Description';

  @override
  String get systemPrompt => '系统提示词（Prompt）';

  @override
  String get nameAndPromptRequired => '名称和Prompt不能为空';

  @override
  String get confirmDeleteRole => 'Confirm Delete Role';

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
  String get templateName => 'Template Name';

  @override
  String get shortDescription => '简短描述';

  @override
  String get category => 'Category';

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
  String get restoreSuccess => 'Restored successfully';

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
  String get searchTools => 'Search tools';

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
  String get addToCalendar => 'Add to Calendar';

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
  String get toolDisplaySettings => 'Tool display settings';

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
  String get editRole => 'Edit Role';

  @override
  String get newRole => '新建角色';

  @override
  String get roleNameHint => 'Enter role name';

  @override
  String get roleDescriptionHint => 'Enter role description';

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
  String get templateNameHint => 'Enter template name';

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
    return '$count days remaining';
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
  String get templateDescription => 'Template Description';

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
  String get efficiency => 'Efficiency';

  @override
  String get analysis => 'Analysis';

  @override
  String get management => 'Management';

  @override
  String get homeToolsCannotBeHidden => 'Home tools cannot be hidden';

  @override
  String get homeMaxFiveTools => 'Maximum 5 tools on home page';

  @override
  String get hidden => 'Hidden';

  @override
  String toolsSelectedForHomeDisplay(int count) {
    return '$count tools selected for home display';
  }

  @override
  String get toolName => 'Tool name';

  @override
  String get showOnHome => 'Show on home';

  @override
  String get apiKeyRequired => 'API key is required';

  @override
  String get modelNameRequired => 'Model name is required';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get baseUrlHint => 'Optional: Custom API base URL';

  @override
  String get securityNotice => 'Security Notice';

  @override
  String get securityNoticeDetail =>
      'Your API key is stored locally and will not be uploaded to the server';

  @override
  String get apiKeyWizard => 'API Key Wizard';

  @override
  String get prevStep => 'Previous';

  @override
  String get selectProviderDesc => 'Choose an AI service provider';

  @override
  String get customProviderDesc => 'Enter custom provider details';

  @override
  String get selectFeatures => 'Select Features';

  @override
  String get selectFeaturesDesc => 'Choose which features to enable';

  @override
  String get enterApiKey => 'Enter API Key';

  @override
  String get enterApiKeyDesc => 'Enter your API key for the selected provider';

  @override
  String get customProviderNameHint => 'Custom provider name';

  @override
  String get confirmConfig => 'Confirm Configuration';

  @override
  String get confirmConfigDesc => 'Please confirm your API configuration';

  @override
  String get provider => 'Provider';

  @override
  String get selectedFeatures => 'Selected Features';

  @override
  String get finish => 'Finish';

  @override
  String get nextStep => 'Next';

  @override
  String get enterCustomProviderName => 'Please enter custom provider name';

  @override
  String get appIdRequired => 'App ID is required';

  @override
  String get noPromptTemplates => 'No prompt templates';

  @override
  String get addPromptTemplateHint => 'Add a new prompt template';

  @override
  String get analysisModel => 'Analysis Model';

  @override
  String get summaryModel => 'Summary Model';

  @override
  String get qwenRealtime => 'Qwen Realtime';

  @override
  String get qwenAudio => 'Qwen Audio';

  @override
  String get paraformerRealtime => 'Paraformer Realtime';

  @override
  String get paraformer => 'Paraformer';

  @override
  String get qwenMax => 'Qwen Max';

  @override
  String get qwenPlus => 'Qwen Plus';

  @override
  String get qwenTurbo => 'Qwen Turbo';

  @override
  String get deepseekChat => 'DeepSeek Chat';

  @override
  String get deepseekReasoner => 'DeepSeek Reasoner';

  @override
  String get text => 'Text';

  @override
  String get voice => 'Voice';

  @override
  String get image => 'Image';

  @override
  String moreTools(int count) {
    return '+$count more';
  }

  @override
  String get recent7DaysApiTrend => 'Recent 7 Days API Trend';

  @override
  String get permanentDeleteMessage =>
      'This action is irreversible. Are you sure you want to permanently delete this record?';

  @override
  String get emptyRecycleBinMessage =>
      'All records in the recycle bin will be permanently deleted. This action cannot be undone.';

  @override
  String get emptyRecycleBinSuccess => 'Recycle bin emptied successfully';

  @override
  String get noDeletedNotes => 'No deleted notes';

  @override
  String get deletedNotesHint => 'Deleted notes will be kept here for 7 days';

  @override
  String get restore => 'Restore';

  @override
  String get untitledNote => 'Untitled Note';

  @override
  String get clearLogsSuccess => 'Logs cleared successfully';

  @override
  String get clearLogsFailed => 'Failed to clear logs';

  @override
  String get copySuccess => 'Copied successfully';

  @override
  String get logViewer => 'Log Viewer';

  @override
  String get copyLogs => 'Copy Logs';

  @override
  String get shareLogs => 'Share Logs';

  @override
  String get loadLogsFailed => 'Failed to load logs';

  @override
  String get noLogsHint => 'No logs available';

  @override
  String get autoAnalysisSwitch => 'Auto Analysis';

  @override
  String get autoAnalysisEnabled => 'Enable Auto Analysis';

  @override
  String get autoAnalysisEnabledDesc =>
      'Automatically analyze after transcription';

  @override
  String get analysisMode => 'Analysis Mode';

  @override
  String get quickAnalysis => 'Quick Analysis';

  @override
  String get quickAnalysisDesc => 'Fast analysis with basic summary';

  @override
  String get standardAnalysis => 'Standard Analysis';

  @override
  String get standardAnalysisDesc => 'Balanced analysis with moderate detail';

  @override
  String get deepAnalysis => 'Deep Analysis';

  @override
  String get deepAnalysisDesc =>
      'Detailed analysis with comprehensive insights';

  @override
  String get analysisDelay => 'Analysis Delay';

  @override
  String get delaySeconds => 'Delay Seconds';

  @override
  String get delaySecondsDesc =>
      'Delay before starting analysis after transcription';

  @override
  String get autoAnalysisItems => 'Auto Analysis Items';

  @override
  String get autoSummarize => 'Auto Summarize';

  @override
  String get autoSummarizeDesc => 'Automatically generate summary';

  @override
  String get autoExtractTasks => 'Auto Extract Tasks';

  @override
  String get autoExtractTasksDesc => 'Automatically extract tasks from content';

  @override
  String get autoSuggestTags => 'Auto Suggest Tags';

  @override
  String get autoSuggestTagsDesc => 'Automatically suggest tags for content';

  @override
  String get analysisTemplate => 'Analysis Template';

  @override
  String get noAnalysisTemplates => 'No analysis templates';

  @override
  String get addAnalysisTemplateHint => 'Tap + to add a new analysis template';

  @override
  String get templateDescriptionHint => 'Enter template description';

  @override
  String get templatePrompt => 'Template Prompt';

  @override
  String get templatePromptHint => 'Enter the AI prompt for this template';

  @override
  String get setAsDefaultDesc => 'Set as default template for analysis';

  @override
  String get addTemplate => 'Add Template';

  @override
  String get templateNameRequired => 'Template name is required';

  @override
  String confirmDeleteTemplateMessage(String name) {
    return 'Are you sure you want to delete template \"$name\"?';
  }

  @override
  String get backupSuccess => 'Backup created successfully';

  @override
  String get confirmRestoreMessage =>
      'Restoring will overwrite current data. Continue?';

  @override
  String get confirmDeleteBackup => 'Delete Backup';

  @override
  String get confirmDeleteBackupMessage =>
      'Are you sure you want to delete this backup?';

  @override
  String get createBackupHint =>
      'Tap \"Create Backup\" to create your first backup';

  @override
  String get retry => 'Retry';

  @override
  String get summary => 'Summary';

  @override
  String get chat => 'Chat';

  @override
  String get promptContent => 'Prompt Content';

  @override
  String get promptContentHint => 'Enter the prompt content';

  @override
  String get editPromptTemplate => 'Edit Prompt Template';

  @override
  String get addPromptTemplate => 'Add Prompt Template';

  @override
  String get inputYourThoughts => 'Input your thoughts...';

  @override
  String get roleManagement => 'Role Management';

  @override
  String get noRoles => 'No roles';

  @override
  String get addRoleHint => 'Tap + to add a role';

  @override
  String get addRole => 'Add Role';

  @override
  String get rolePrompt => 'Role Prompt';

  @override
  String get rolePromptHint => 'Enter the system prompt for this role';

  @override
  String get roleNameRequired => 'Role name is required';

  @override
  String confirmDeleteRoleMessage(String name) {
    return 'Are you sure you want to delete role \"$name\"?';
  }
}
