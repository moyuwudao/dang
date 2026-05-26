import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Changji'**
  String get appName;

  /// Application tagline
  ///
  /// In en, this message translates to:
  /// **'AI Voice Notes for One-Person Companies'**
  String get appTagline;

  /// Home page title
  ///
  /// In en, this message translates to:
  /// **'My Notes'**
  String get homeTitle;

  /// Record button text
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get recordButton;

  /// Stop button text
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopButton;

  /// Pause button text
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseButton;

  /// Resume button text
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeButton;

  /// 取消按钮
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editButton;

  /// Share button text
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// API key settings section title
  ///
  /// In en, this message translates to:
  /// **'API Key Settings'**
  String get apiKeySettings;

  /// OpenAI API key label
  ///
  /// In en, this message translates to:
  /// **'OpenAI API Key'**
  String get openaiApiKey;

  /// API key input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your OpenAI API key'**
  String get apiKeyHint;

  /// API key help text
  ///
  /// In en, this message translates to:
  /// **'Your API key is stored locally and never shared'**
  String get apiKeyHelp;

  /// Theme settings section title
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSettings;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// System default theme option
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemTheme;

  /// Language settings section title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Chinese language option
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// Recording page title
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recordingTitle;

  /// Recording in progress text
  ///
  /// In en, this message translates to:
  /// **'Recording in progress...'**
  String get recordingInProgress;

  /// Tap to stop hint
  ///
  /// In en, this message translates to:
  /// **'Tap to stop'**
  String get tapToStop;

  /// OCR page title
  ///
  /// In en, this message translates to:
  /// **'OCR Scan'**
  String get ocrTitle;

  /// OCR page description
  ///
  /// In en, this message translates to:
  /// **'Take a photo or select an image to extract text'**
  String get ocrDescription;

  /// Take photo button
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Select image button
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get selectImage;

  /// Transcribe page title
  ///
  /// In en, this message translates to:
  /// **'Transcribe'**
  String get transcribeTitle;

  /// Transcribe page description
  ///
  /// In en, this message translates to:
  /// **'Convert voice to text using AI'**
  String get transcribeDescription;

  /// Transcribing in progress
  ///
  /// In en, this message translates to:
  /// **'Transcribing...'**
  String get transcribing;

  /// Transcription success message
  ///
  /// In en, this message translates to:
  /// **'Transcription complete'**
  String get transcribeSuccess;

  /// Transcription error message
  ///
  /// In en, this message translates to:
  /// **'Transcription failed'**
  String get transcribeError;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No records message
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get noRecords;

  /// Create first record hint
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone to create your first note'**
  String get createFirstRecord;

  /// Search input hint
  ///
  /// In en, this message translates to:
  /// **'Search notes...'**
  String get searchHint;

  /// All notes filter
  ///
  /// In en, this message translates to:
  /// **'All Notes'**
  String get allNotes;

  /// Favorites filter
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Tags section
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// Add tag button
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get addTag;

  /// Untitled note default title
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// 今天
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Yesterday date label
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Privacy policy link
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Terms of service link
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// About section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// 确认删除
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete?'**
  String get confirmDelete;

  /// 确认删除标题
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDeleteTitle;

  /// Yes button
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Permission required dialog title
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// Microphone permission rationale
  ///
  /// In en, this message translates to:
  /// **'Microphone access is required for recording'**
  String get microphonePermission;

  /// Camera permission rationale
  ///
  /// In en, this message translates to:
  /// **'Camera access is required for OCR'**
  String get cameraPermission;

  /// Storage permission rationale
  ///
  /// In en, this message translates to:
  /// **'Storage access is required to save recordings'**
  String get storagePermission;

  /// Grant permission button
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get errorNetwork;

  /// API key error message
  ///
  /// In en, this message translates to:
  /// **'Invalid API key. Please check your settings.'**
  String get errorApiKey;

  /// Data management section title
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// Data backup option
  ///
  /// In en, this message translates to:
  /// **'Data Backup'**
  String get dataBackup;

  /// Data restore option
  ///
  /// In en, this message translates to:
  /// **'Data Restore'**
  String get dataRestore;

  /// Export data option
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// Import data option
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// Clear all data option
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearData;

  /// Clear data confirmation message
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your records. This action cannot be undone.'**
  String get clearDataConfirm;

  /// Recording quality setting
  ///
  /// In en, this message translates to:
  /// **'Recording Quality'**
  String get recordQuality;

  /// Recording format setting
  ///
  /// In en, this message translates to:
  /// **'Recording Format'**
  String get recordFormat;

  /// High quality option
  ///
  /// In en, this message translates to:
  /// **'High Quality'**
  String get highQuality;

  /// Medium quality option
  ///
  /// In en, this message translates to:
  /// **'Medium Quality'**
  String get mediumQuality;

  /// Low quality option
  ///
  /// In en, this message translates to:
  /// **'Low Quality'**
  String get lowQuality;

  /// Help and feedback option
  ///
  /// In en, this message translates to:
  /// **'Help & Feedback'**
  String get helpAndFeedback;

  /// Contact us option
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// Rate app option
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// Share app option
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// Text input button
  ///
  /// In en, this message translates to:
  /// **'Text Input'**
  String get textInput;

  /// Text input hint
  ///
  /// In en, this message translates to:
  /// **'Enter text content here...'**
  String get textInputHint;

  /// Usage statistics section title
  ///
  /// In en, this message translates to:
  /// **'Usage Statistics'**
  String get usageStatistics;

  /// Usage stats detail button
  ///
  /// In en, this message translates to:
  /// **'Usage Details'**
  String get usageStatsDetail;

  /// Clear usage stats button
  ///
  /// In en, this message translates to:
  /// **'Clear Statistics'**
  String get usageStatsClear;

  /// Clear usage stats confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all usage statistics? This action cannot be undone.'**
  String get usageStatsClearConfirm;

  /// No usage data message
  ///
  /// In en, this message translates to:
  /// **'No usage data yet'**
  String get usageStatsEmpty;

  /// No usage data hint
  ///
  /// In en, this message translates to:
  /// **'Use AI features to see statistics'**
  String get usageStatsEmptyHint;

  /// Calls count label
  ///
  /// In en, this message translates to:
  /// **'calls'**
  String get calls;

  /// Tokens count label
  ///
  /// In en, this message translates to:
  /// **'tokens'**
  String get tokens;

  /// Last used label
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get lastUsed;

  /// Features label
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Clear button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Frequently used templates label
  ///
  /// In en, this message translates to:
  /// **'Frequently Used'**
  String get frequentlyUsedTemplates;

  /// No matching tools message
  ///
  /// In en, this message translates to:
  /// **'No matching tools'**
  String get noMatchingTool;

  /// Frequently used tools label
  ///
  /// In en, this message translates to:
  /// **'Frequently Used'**
  String get frequentlyUsedTools;

  /// Create role button
  ///
  /// In en, this message translates to:
  /// **'Create Role'**
  String get createRole;

  /// Select data source type label
  ///
  /// In en, this message translates to:
  /// **'Select Data Source'**
  String get selectDataSourceType;

  /// No tags message
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get noTags;

  /// No tool output data message
  ///
  /// In en, this message translates to:
  /// **'No tool output data'**
  String get noToolOutputData;

  /// Associated records count
  ///
  /// In en, this message translates to:
  /// **'{count} related records'**
  String associatedRecords(int count);

  /// Date range label
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// Include AI analysis checkbox
  ///
  /// In en, this message translates to:
  /// **'Include AI Analysis'**
  String get includeAiAnalysis;

  /// Include AI analysis description
  ///
  /// In en, this message translates to:
  /// **'Include AI analysis content as input data'**
  String get includeAiAnalysisDesc;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'下一步'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'上一步'**
  String get previous;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'完成'**
  String get done;

  /// 添加
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'隐藏'**
  String get hide;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'登录'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'注册'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'退出登录'**
  String get logout;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'加载中...'**
  String get loading;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'保存成功'**
  String get saveSuccess;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'保存失败'**
  String get saveFailed;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'加载失败'**
  String get loadFailed;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'删除成功'**
  String get deleteSuccess;

  /// No description provided for @contentUpdated.
  ///
  /// In en, this message translates to:
  /// **'内容已更新'**
  String get contentUpdated;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'已复制到剪贴板'**
  String get copiedToClipboard;

  /// No description provided for @noContent.
  ///
  /// In en, this message translates to:
  /// **'无内容'**
  String get noContent;

  /// No description provided for @noMoreRecords.
  ///
  /// In en, this message translates to:
  /// **'没有更多记录了'**
  String get noMoreRecords;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'搜索失败'**
  String get searchFailed;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'未找到相关记录'**
  String get noSearchResults;

  /// No description provided for @workbench.
  ///
  /// In en, this message translates to:
  /// **'工具台'**
  String get workbench;

  /// No description provided for @addTagOptional.
  ///
  /// In en, this message translates to:
  /// **'添加标签（可选）'**
  String get addTagOptional;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'刚刚'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'分钟前'**
  String get minutesAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'小时前'**
  String get hoursAgo;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'天前'**
  String get daysAgo;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'年'**
  String get year;

  /// 月份分隔符
  ///
  /// In en, this message translates to:
  /// **'/'**
  String get month;

  /// 日
  ///
  /// In en, this message translates to:
  /// **''**
  String get day;

  /// 明天
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// 已逾期
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// 选择日期
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// 待处理
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusProcessing.
  ///
  /// In en, this message translates to:
  /// **'转写中'**
  String get statusProcessing;

  /// 已完成
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'失败'**
  String get statusFailed;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'生效中'**
  String get statusActive;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'已过期'**
  String get statusExpired;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'免费版'**
  String get freePlan;

  /// No description provided for @typeVoice.
  ///
  /// In en, this message translates to:
  /// **'语音'**
  String get typeVoice;

  /// No description provided for @typeText.
  ///
  /// In en, this message translates to:
  /// **'文本'**
  String get typeText;

  /// No description provided for @typeOcr.
  ///
  /// In en, this message translates to:
  /// **'OCR'**
  String get typeOcr;

  /// No description provided for @recordNotFound.
  ///
  /// In en, this message translates to:
  /// **'记录不存在'**
  String get recordNotFound;

  /// No description provided for @realtimeTranscription.
  ///
  /// In en, this message translates to:
  /// **'实时转写'**
  String get realtimeTranscription;

  /// No description provided for @realtimeTranscribing.
  ///
  /// In en, this message translates to:
  /// **'实时转写中'**
  String get realtimeTranscribing;

  /// No description provided for @configureRealtimeApi.
  ///
  /// In en, this message translates to:
  /// **'请先配置实时转写API'**
  String get configureRealtimeApi;

  /// No description provided for @gotoConfigure.
  ///
  /// In en, this message translates to:
  /// **'未配置API，点击前往配置'**
  String get gotoConfigure;

  /// No description provided for @tapToStopRecording.
  ///
  /// In en, this message translates to:
  /// **'点击停止录音'**
  String get tapToStopRecording;

  /// No description provided for @tapToStartRecording.
  ///
  /// In en, this message translates to:
  /// **'点击开始录音'**
  String get tapToStartRecording;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'已暂停'**
  String get paused;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'录音中'**
  String get recording;

  /// No description provided for @viewRealtimeTranscription.
  ///
  /// In en, this message translates to:
  /// **'查看实时转写'**
  String get viewRealtimeTranscription;

  /// No description provided for @returnToRecording.
  ///
  /// In en, this message translates to:
  /// **'返回录音界面可继续控制录音'**
  String get returnToRecording;

  /// No description provided for @waitingForVoiceInput.
  ///
  /// In en, this message translates to:
  /// **'等待语音输入...'**
  String get waitingForVoiceInput;

  /// No description provided for @originalTranscription.
  ///
  /// In en, this message translates to:
  /// **'原始转写文本'**
  String get originalTranscription;

  /// No description provided for @supplementContent.
  ///
  /// In en, this message translates to:
  /// **'补充内容'**
  String get supplementContent;

  /// No description provided for @supplementIdeas.
  ///
  /// In en, this message translates to:
  /// **'补充完善想法'**
  String get supplementIdeas;

  /// No description provided for @transcriptionResult.
  ///
  /// In en, this message translates to:
  /// **'转写结果'**
  String get transcriptionResult;

  /// No description provided for @transcriptionLog.
  ///
  /// In en, this message translates to:
  /// **'转写日志'**
  String get transcriptionLog;

  /// No description provided for @aiAnalysisResult.
  ///
  /// In en, this message translates to:
  /// **'AI分析结果'**
  String get aiAnalysisResult;

  /// No description provided for @relatedRecords.
  ///
  /// In en, this message translates to:
  /// **'相关记录'**
  String get relatedRecords;

  /// No description provided for @originalImage.
  ///
  /// In en, this message translates to:
  /// **'原始图片'**
  String get originalImage;

  /// No description provided for @audioSupplement.
  ///
  /// In en, this message translates to:
  /// **'录音补充'**
  String get audioSupplement;

  /// No description provided for @imageSupplement.
  ///
  /// In en, this message translates to:
  /// **'图片补充'**
  String get imageSupplement;

  /// No description provided for @textSupplement.
  ///
  /// In en, this message translates to:
  /// **'文本补充'**
  String get textSupplement;

  /// No description provided for @noContentAvailable.
  ///
  /// In en, this message translates to:
  /// **'无内容'**
  String get noContentAvailable;

  /// No description provided for @hideRecord.
  ///
  /// In en, this message translates to:
  /// **'隐藏记录'**
  String get hideRecord;

  /// No description provided for @hideRecordConfirm.
  ///
  /// In en, this message translates to:
  /// **'隐藏后该记录将不再出现在相关记录列表中。'**
  String get hideRecordConfirm;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'自动'**
  String get auto;

  /// No description provided for @retranscribe.
  ///
  /// In en, this message translates to:
  /// **'重新转写'**
  String get retranscribe;

  /// No description provided for @retranscribeOptions.
  ///
  /// In en, this message translates to:
  /// **'重新转写选项'**
  String get retranscribeOptions;

  /// No description provided for @retranscribeAll.
  ///
  /// In en, this message translates to:
  /// **'全部转写'**
  String get retranscribeAll;

  /// No description provided for @selectParagraphs.
  ///
  /// In en, this message translates to:
  /// **'选择段落'**
  String get selectParagraphs;

  /// No description provided for @selectParagraphsToRetranscribe.
  ///
  /// In en, this message translates to:
  /// **'选择要重新转写的段落'**
  String get selectParagraphsToRetranscribe;

  /// No description provided for @selectAnalysisRole.
  ///
  /// In en, this message translates to:
  /// **'选择分析角色'**
  String get selectAnalysisRole;

  /// No description provided for @manageRoles.
  ///
  /// In en, this message translates to:
  /// **'管理角色'**
  String get manageRoles;

  /// No description provided for @selectShareMethod.
  ///
  /// In en, this message translates to:
  /// **'选择分享方式'**
  String get selectShareMethod;

  /// No description provided for @analysisExists.
  ///
  /// In en, this message translates to:
  /// **'已存在分析结果'**
  String get analysisExists;

  /// No description provided for @analysisExistsConfirm.
  ///
  /// In en, this message translates to:
  /// **'已有分析结果，是否重新分析？'**
  String get analysisExistsConfirm;

  /// No description provided for @reanalyze.
  ///
  /// In en, this message translates to:
  /// **'重新分析'**
  String get reanalyze;

  /// No description provided for @analysisComplete.
  ///
  /// In en, this message translates to:
  /// **'分析完成'**
  String get analysisComplete;

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'分析失败'**
  String get analysisFailed;

  /// No description provided for @noContentToAnalyze.
  ///
  /// In en, this message translates to:
  /// **'没有可分析的内容'**
  String get noContentToAnalyze;

  /// No description provided for @addAiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'添加AI分析'**
  String get addAiAnalysis;

  /// No description provided for @aiAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'AI正在分析中...'**
  String get aiAnalyzing;

  /// No description provided for @tapToAnalyze.
  ///
  /// In en, this message translates to:
  /// **'点击 + 使用AI角色分析此记录'**
  String get tapToAnalyze;

  /// No description provided for @deleteRecordConfirm.
  ///
  /// In en, this message translates to:
  /// **'删除的记录将移至回收站，保留7天后自动清除。是否继续？'**
  String get deleteRecordConfirm;

  /// No description provided for @transcriptionProgress.
  ///
  /// In en, this message translates to:
  /// **'转写进度'**
  String get transcriptionProgress;

  /// No description provided for @chunkProgress.
  ///
  /// In en, this message translates to:
  /// **'分片进度'**
  String get chunkProgress;

  /// No description provided for @supplementAdded.
  ///
  /// In en, this message translates to:
  /// **'补充内容已添加'**
  String get supplementAdded;

  /// No description provided for @transcribingSupplement.
  ///
  /// In en, this message translates to:
  /// **'正在转写补充内容...'**
  String get transcribingSupplement;

  /// No description provided for @supplementTranscriptionComplete.
  ///
  /// In en, this message translates to:
  /// **'补充内容转写完成'**
  String get supplementTranscriptionComplete;

  /// No description provided for @selectedParagraphsSuccess.
  ///
  /// In en, this message translates to:
  /// **'选定段落转写成功'**
  String get selectedParagraphsSuccess;

  /// No description provided for @transcriptionSuccess.
  ///
  /// In en, this message translates to:
  /// **'转写成功'**
  String get transcriptionSuccess;

  /// No description provided for @transcriptionSuccessNoContent.
  ///
  /// In en, this message translates to:
  /// **'转写完成，但未获取到文本内容'**
  String get transcriptionSuccessNoContent;

  /// No description provided for @pleaseConfigureApiKey.
  ///
  /// In en, this message translates to:
  /// **'请先配置API Key'**
  String get pleaseConfigureApiKey;

  /// No description provided for @noRecordsInPeriod.
  ///
  /// In en, this message translates to:
  /// **'该时间段内没有记录'**
  String get noRecordsInPeriod;

  /// 请输入内容
  ///
  /// In en, this message translates to:
  /// **'Please enter content'**
  String get pleaseEnterContent;

  /// No description provided for @generationFailed.
  ///
  /// In en, this message translates to:
  /// **'生成失败'**
  String get generationFailed;

  /// No description provided for @audioNotFound.
  ///
  /// In en, this message translates to:
  /// **'音频文件不存在'**
  String get audioNotFound;

  /// No description provided for @fileNotFound.
  ///
  /// In en, this message translates to:
  /// **'文件不存在'**
  String get fileNotFound;

  /// No description provided for @audioInvalid.
  ///
  /// In en, this message translates to:
  /// **'音频文件无效'**
  String get audioInvalid;

  /// No description provided for @playerInitFailed.
  ///
  /// In en, this message translates to:
  /// **'播放器初始化失败'**
  String get playerInitFailed;

  /// No description provided for @playbackFailed.
  ///
  /// In en, this message translates to:
  /// **'播放失败'**
  String get playbackFailed;

  /// No description provided for @audioPlayback.
  ///
  /// In en, this message translates to:
  /// **'音频播放'**
  String get audioPlayback;

  /// No description provided for @preparingToShare.
  ///
  /// In en, this message translates to:
  /// **'正在准备分享...'**
  String get preparingToShare;

  /// No description provided for @voiceRecord.
  ///
  /// In en, this message translates to:
  /// **'语音记录'**
  String get voiceRecord;

  /// No description provided for @ocrRecord.
  ///
  /// In en, this message translates to:
  /// **'OCR识别'**
  String get ocrRecord;

  /// No description provided for @textRecord.
  ///
  /// In en, this message translates to:
  /// **'文本记录'**
  String get textRecord;

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'字'**
  String get characters;

  /// No description provided for @unfavorite.
  ///
  /// In en, this message translates to:
  /// **'取消收藏'**
  String get unfavorite;

  /// No description provided for @favoriteRecords.
  ///
  /// In en, this message translates to:
  /// **'记录收藏'**
  String get favoriteRecords;

  /// No description provided for @noFavoriteRecords.
  ///
  /// In en, this message translates to:
  /// **'暂无收藏记录'**
  String get noFavoriteRecords;

  /// No description provided for @toolOutputFavorites.
  ///
  /// In en, this message translates to:
  /// **'工具输出收藏'**
  String get toolOutputFavorites;

  /// No description provided for @noFavoriteToolOutputs.
  ///
  /// In en, this message translates to:
  /// **'暂无收藏的工具输出'**
  String get noFavoriteToolOutputs;

  /// No description provided for @ocrFailed.
  ///
  /// In en, this message translates to:
  /// **'文字识别失败'**
  String get ocrFailed;

  /// No description provided for @selectImageFailed.
  ///
  /// In en, this message translates to:
  /// **'选择图片失败'**
  String get selectImageFailed;

  /// No description provided for @recordSaved.
  ///
  /// In en, this message translates to:
  /// **'记录已保存'**
  String get recordSaved;

  /// No description provided for @photoOcr.
  ///
  /// In en, this message translates to:
  /// **'拍照识别'**
  String get photoOcr;

  /// No description provided for @recognitionResult.
  ///
  /// In en, this message translates to:
  /// **'识别结果'**
  String get recognitionResult;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'重新拍照'**
  String get retakePhoto;

  /// No description provided for @saveRecord.
  ///
  /// In en, this message translates to:
  /// **'保存记录'**
  String get saveRecord;

  /// No description provided for @recognizingText.
  ///
  /// In en, this message translates to:
  /// **'正在识别文字...'**
  String get recognizingText;

  /// No description provided for @quickNote.
  ///
  /// In en, this message translates to:
  /// **'速记'**
  String get quickNote;

  /// No description provided for @enterYourThoughts.
  ///
  /// In en, this message translates to:
  /// **'在这里输入你的想法'**
  String get enterYourThoughts;

  /// 速记已保存
  ///
  /// In en, this message translates to:
  /// **'Quick note saved'**
  String get quickNoteSaved;

  /// 智能提醒
  ///
  /// In en, this message translates to:
  /// **'Smart Reminders'**
  String get smartReminders;

  /// 添加提醒
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get addReminder;

  /// 编辑提醒
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get editReminder;

  /// 没有提醒
  ///
  /// In en, this message translates to:
  /// **'No Reminders'**
  String get noReminders;

  /// 点击添加提醒
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a reminder'**
  String get tapToAddReminder;

  /// 标题
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// 描述
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// 无法打开日历
  ///
  /// In en, this message translates to:
  /// **'Cannot open calendar: {error}'**
  String cannotOpenCalendar(String error);

  /// No description provided for @smartWeeklyReport.
  ///
  /// In en, this message translates to:
  /// **'智能周报'**
  String get smartWeeklyReport;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'生成中...'**
  String get generating;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'生成周报'**
  String get generateReport;

  /// No description provided for @timeRange.
  ///
  /// In en, this message translates to:
  /// **'时间范围'**
  String get timeRange;

  /// No description provided for @reportContent.
  ///
  /// In en, this message translates to:
  /// **'周报内容'**
  String get reportContent;

  /// No description provided for @selectTimeRangeHint.
  ///
  /// In en, this message translates to:
  /// **'选择时间范围，一键生成周报'**
  String get selectTimeRangeHint;

  /// No description provided for @aiWillSummarize.
  ///
  /// In en, this message translates to:
  /// **'AI将自动汇总该时间段内的所有记录'**
  String get aiWillSummarize;

  /// No description provided for @saveReport.
  ///
  /// In en, this message translates to:
  /// **'保存周报'**
  String get saveReport;

  /// No description provided for @weeklyReportSaved.
  ///
  /// In en, this message translates to:
  /// **'周报已保存'**
  String get weeklyReportSaved;

  /// No description provided for @knowledgeMindMap.
  ///
  /// In en, this message translates to:
  /// **'知识脑图'**
  String get knowledgeMindMap;

  /// No description provided for @selectTags.
  ///
  /// In en, this message translates to:
  /// **'选择标签'**
  String get selectTags;

  /// No description provided for @savePlan.
  ///
  /// In en, this message translates to:
  /// **'保存方案'**
  String get savePlan;

  /// No description provided for @planSaved.
  ///
  /// In en, this message translates to:
  /// **'方案已保存'**
  String get planSaved;

  /// No description provided for @archiveByTags.
  ///
  /// In en, this message translates to:
  /// **'按标签归档'**
  String get archiveByTags;

  /// No description provided for @archivedRecordsCount.
  ///
  /// In en, this message translates to:
  /// **'已归档 {count} 条记录'**
  String archivedRecordsCount(Object count);

  /// No description provided for @aiMindMapSuccess.
  ///
  /// In en, this message translates to:
  /// **'AI脑图生成成功'**
  String get aiMindMapSuccess;

  /// No description provided for @aiMindMapFailed.
  ///
  /// In en, this message translates to:
  /// **'AI脑图生成失败'**
  String get aiMindMapFailed;

  /// No description provided for @unnamed.
  ///
  /// In en, this message translates to:
  /// **'未命名'**
  String get unnamed;

  /// No description provided for @unnamedTopic.
  ///
  /// In en, this message translates to:
  /// **'未命名主题'**
  String get unnamedTopic;

  /// No description provided for @apiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'API调用分析'**
  String get apiAnalysis;

  /// No description provided for @totalCalls.
  ///
  /// In en, this message translates to:
  /// **'总调用次数'**
  String get totalCalls;

  /// No description provided for @successRate.
  ///
  /// In en, this message translates to:
  /// **'成功率'**
  String get successRate;

  /// No description provided for @textCalls.
  ///
  /// In en, this message translates to:
  /// **'文本调用'**
  String get textCalls;

  /// No description provided for @voiceCalls.
  ///
  /// In en, this message translates to:
  /// **'语音调用'**
  String get voiceCalls;

  /// No description provided for @imageCalls.
  ///
  /// In en, this message translates to:
  /// **'图片调用'**
  String get imageCalls;

  /// No description provided for @failedCalls.
  ///
  /// In en, this message translates to:
  /// **'失败次数'**
  String get failedCalls;

  /// No description provided for @apiCallTypeDistribution.
  ///
  /// In en, this message translates to:
  /// **'API调用类型分布'**
  String get apiCallTypeDistribution;

  /// No description provided for @noToolCallData.
  ///
  /// In en, this message translates to:
  /// **'暂无工具调用数据'**
  String get noToolCallData;

  /// No description provided for @toolCallUsage.
  ///
  /// In en, this message translates to:
  /// **'工具调用使用量'**
  String get toolCallUsage;

  /// No description provided for @noDailyCallData.
  ///
  /// In en, this message translates to:
  /// **'暂无每日调用数据'**
  String get noDailyCallData;

  /// No description provided for @recent7DaysTrend.
  ///
  /// In en, this message translates to:
  /// **'近7天API调用趋势'**
  String get recent7DaysTrend;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'周一'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'周二'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'周三'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'周四'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'周五'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'周六'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'周日'**
  String get sunday;

  /// No description provided for @dataStatistics.
  ///
  /// In en, this message translates to:
  /// **'数据统计'**
  String get dataStatistics;

  /// No description provided for @loadStatsFailed.
  ///
  /// In en, this message translates to:
  /// **'加载统计失败'**
  String get loadStatsFailed;

  /// No description provided for @accountCenter.
  ///
  /// In en, this message translates to:
  /// **'账户中心'**
  String get accountCenter;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'系统设置'**
  String get systemSettings;

  /// No description provided for @runtimeLogs.
  ///
  /// In en, this message translates to:
  /// **'运行日志'**
  String get runtimeLogs;

  /// No description provided for @quickConfigWizard.
  ///
  /// In en, this message translates to:
  /// **'快速配置向导'**
  String get quickConfigWizard;

  /// No description provided for @multiApiConfig.
  ///
  /// In en, this message translates to:
  /// **'多API配置管理'**
  String get multiApiConfig;

  /// No description provided for @aiAnalysisRoles.
  ///
  /// In en, this message translates to:
  /// **'AI分析角色'**
  String get aiAnalysisRoles;

  /// No description provided for @promptTemplateManagement.
  ///
  /// In en, this message translates to:
  /// **'Prompt模板管理'**
  String get promptTemplateManagement;

  /// No description provided for @toolConfig.
  ///
  /// In en, this message translates to:
  /// **'工具方案配置'**
  String get toolConfig;

  /// No description provided for @autoAnalysisSettings.
  ///
  /// In en, this message translates to:
  /// **'自动分析设置'**
  String get autoAnalysisSettings;

  /// No description provided for @backupManagement.
  ///
  /// In en, this message translates to:
  /// **'备份管理'**
  String get backupManagement;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'个人信息'**
  String get personalInfo;

  /// No description provided for @rechargeCenter.
  ///
  /// In en, this message translates to:
  /// **'充值中心'**
  String get rechargeCenter;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'确认退出'**
  String get confirmLogout;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'退出后将无法使用云端AI服务'**
  String get logoutConfirmMessage;

  /// No description provided for @loginRegister.
  ///
  /// In en, this message translates to:
  /// **'登录/注册'**
  String get loginRegister;

  /// No description provided for @cloudAiService.
  ///
  /// In en, this message translates to:
  /// **'云端AI服务'**
  String get cloudAiService;

  /// No description provided for @localApiConfig.
  ///
  /// In en, this message translates to:
  /// **'本地API配置'**
  String get localApiConfig;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'未登录'**
  String get notLoggedIn;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'用户'**
  String get user;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'该功能需要登录后使用'**
  String get loginRequired;

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'去登录'**
  String get goToLogin;

  /// No description provided for @skipLogin.
  ///
  /// In en, this message translates to:
  /// **'暂不登录'**
  String get skipLogin;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'当前套餐'**
  String get currentPlan;

  /// No description provided for @transcriptionQuota.
  ///
  /// In en, this message translates to:
  /// **'转写额度'**
  String get transcriptionQuota;

  /// No description provided for @quotaDetails.
  ///
  /// In en, this message translates to:
  /// **'额度详情'**
  String get quotaDetails;

  /// No description provided for @purchasePlan.
  ///
  /// In en, this message translates to:
  /// **'购买套餐'**
  String get purchasePlan;

  /// No description provided for @monthlySubscription.
  ///
  /// In en, this message translates to:
  /// **'按月订阅'**
  String get monthlySubscription;

  /// No description provided for @planPackage.
  ///
  /// In en, this message translates to:
  /// **'套餐包'**
  String get planPackage;

  /// No description provided for @recharge.
  ///
  /// In en, this message translates to:
  /// **'充值'**
  String get recharge;

  /// No description provided for @accountBalance.
  ///
  /// In en, this message translates to:
  /// **'账户余额'**
  String get accountBalance;

  /// No description provided for @selectRechargeAmount.
  ///
  /// In en, this message translates to:
  /// **'选择充值金额'**
  String get selectRechargeAmount;

  /// No description provided for @orEnterCustomAmount.
  ///
  /// In en, this message translates to:
  /// **'或输入自定义金额'**
  String get orEnterCustomAmount;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'请输入金额'**
  String get pleaseEnterAmount;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'推荐'**
  String get recommended;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'立即购买'**
  String get buyNow;

  /// No description provided for @rechargeNow.
  ///
  /// In en, this message translates to:
  /// **'立即充值'**
  String get rechargeNow;

  /// No description provided for @confirmRecharge.
  ///
  /// In en, this message translates to:
  /// **'确认充值'**
  String get confirmRecharge;

  /// No description provided for @confirmPurchase.
  ///
  /// In en, this message translates to:
  /// **'确认购买'**
  String get confirmPurchase;

  /// No description provided for @otherPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'其他支付方式'**
  String get otherPaymentMethods;

  /// No description provided for @useBalance.
  ///
  /// In en, this message translates to:
  /// **'使用余额'**
  String get useBalance;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'交易记录'**
  String get transactionHistory;

  /// No description provided for @noTransactionRecords.
  ///
  /// In en, this message translates to:
  /// **'暂无交易记录'**
  String get noTransactionRecords;

  /// No description provided for @mySubscription.
  ///
  /// In en, this message translates to:
  /// **'我的订阅'**
  String get mySubscription;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'欢迎回来'**
  String get welcomeBack;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'手机号'**
  String get phoneNumber;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'请输入手机号'**
  String get pleaseEnterPhone;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'请输入密码'**
  String get pleaseEnterPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'忘记密码?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'还没有账号?'**
  String get noAccount;

  /// No description provided for @hasAccount.
  ///
  /// In en, this message translates to:
  /// **'已有账号?'**
  String get hasAccount;

  /// No description provided for @loginNow.
  ///
  /// In en, this message translates to:
  /// **'立即登录'**
  String get loginNow;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'立即注册'**
  String get registerNow;

  /// No description provided for @pleaseFillPhoneAndPassword.
  ///
  /// In en, this message translates to:
  /// **'请填写手机号和密码'**
  String get pleaseFillPhoneAndPassword;

  /// No description provided for @pleaseEnterValidPhone.
  ///
  /// In en, this message translates to:
  /// **'请输入正确的11位手机号'**
  String get pleaseEnterValidPhone;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'登录失败，请检查手机号和密码'**
  String get loginFailed;

  /// No description provided for @registerAccount.
  ///
  /// In en, this message translates to:
  /// **'注册账号'**
  String get registerAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'创建账号'**
  String get createAccount;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'验证码'**
  String get verificationCode;

  /// No description provided for @captcha.
  ///
  /// In en, this message translates to:
  /// **'图形验证码'**
  String get captcha;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'确认密码'**
  String get confirmPassword;

  /// No description provided for @getVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'获取验证码'**
  String get getVerificationCode;

  /// 秒
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get seconds;

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'发送失败'**
  String get sendFailed;

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'刷新失败'**
  String get refreshFailed;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'密码长度不能少于6位'**
  String get passwordTooShort;

  /// No description provided for @passwordsNotMatch.
  ///
  /// In en, this message translates to:
  /// **'两次密码不一致'**
  String get passwordsNotMatch;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'注册失败，请稍后重试'**
  String get registerFailed;

  /// No description provided for @welcomeToChangji.
  ///
  /// In en, this message translates to:
  /// **'欢迎加入畅记！'**
  String get welcomeToChangji;

  /// No description provided for @newUserGift.
  ///
  /// In en, this message translates to:
  /// **'已赠送您新手体验包：'**
  String get newUserGift;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'开始使用'**
  String get getStarted;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'账号信息'**
  String get accountInfo;

  /// No description provided for @registrationTime.
  ///
  /// In en, this message translates to:
  /// **'注册时间'**
  String get registrationTime;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'未配置'**
  String get notConfigured;

  /// No description provided for @selectConfig.
  ///
  /// In en, this message translates to:
  /// **'选择配置'**
  String get selectConfig;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'测试连接'**
  String get testConnection;

  /// No description provided for @testingConnection.
  ///
  /// In en, this message translates to:
  /// **'正在测试连接...'**
  String get testingConnection;

  /// No description provided for @connectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'连接成功'**
  String get connectionSuccess;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'连接失败'**
  String get connectionFailed;

  /// No description provided for @testError.
  ///
  /// In en, this message translates to:
  /// **'测试出错'**
  String get testError;

  /// No description provided for @configName.
  ///
  /// In en, this message translates to:
  /// **'配置名称'**
  String get configName;

  /// 自定义
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @customProviderName.
  ///
  /// In en, this message translates to:
  /// **'自定义提供商名称'**
  String get customProviderName;

  /// No description provided for @modelName.
  ///
  /// In en, this message translates to:
  /// **'模型名称'**
  String get modelName;

  /// No description provided for @configDeleted.
  ///
  /// In en, this message translates to:
  /// **'配置已删除'**
  String get configDeleted;

  /// No description provided for @configSaved.
  ///
  /// In en, this message translates to:
  /// **'配置已保存'**
  String get configSaved;

  /// No description provided for @fillAllRequired.
  ///
  /// In en, this message translates to:
  /// **'请填写所有必填项'**
  String get fillAllRequired;

  /// No description provided for @selectAtLeastOneFeature.
  ///
  /// In en, this message translates to:
  /// **'至少选择一个功能'**
  String get selectAtLeastOneFeature;

  /// No description provided for @featureIncompatible.
  ///
  /// In en, this message translates to:
  /// **'功能不兼容'**
  String get featureIncompatible;

  /// No description provided for @apiConfigManagement.
  ///
  /// In en, this message translates to:
  /// **'API配置管理'**
  String get apiConfigManagement;

  /// No description provided for @featureAssignment.
  ///
  /// In en, this message translates to:
  /// **'功能分配'**
  String get featureAssignment;

  /// No description provided for @selectProvider.
  ///
  /// In en, this message translates to:
  /// **'选择提供商'**
  String get selectProvider;

  /// No description provided for @supportedFeatures.
  ///
  /// In en, this message translates to:
  /// **'支持的功能'**
  String get supportedFeatures;

  /// No description provided for @checkApiKeyBaseUrlNetwork.
  ///
  /// In en, this message translates to:
  /// **'请检查: 1. API Key是否正确 2. Base URL是否正确 3. 网络连接是否正常'**
  String get checkApiKeyBaseUrlNetwork;

  /// No description provided for @supportsAiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'支持AI分析、摘要、标题生成'**
  String get supportsAiAnalysis;

  /// No description provided for @supportsAudioToText.
  ///
  /// In en, this message translates to:
  /// **'支持录音转文字'**
  String get supportsAudioToText;

  /// No description provided for @supportsRealtimeTranscription.
  ///
  /// In en, this message translates to:
  /// **'支持实时语音转写'**
  String get supportsRealtimeTranscription;

  /// No description provided for @supportsOfflineTranscription.
  ///
  /// In en, this message translates to:
  /// **'支持提交音频文件进行离线转写'**
  String get supportsOfflineTranscription;

  /// No description provided for @supportsSpeakerDiarization.
  ///
  /// In en, this message translates to:
  /// **'支持区分不同发言人'**
  String get supportsSpeakerDiarization;

  /// No description provided for @supportsImageRecognition.
  ///
  /// In en, this message translates to:
  /// **'支持图片内容识别'**
  String get supportsImageRecognition;

  /// No description provided for @supportsMultiTurnDialogue.
  ///
  /// In en, this message translates to:
  /// **'支持多轮对话'**
  String get supportsMultiTurnDialogue;

  /// No description provided for @textAnalysis.
  ///
  /// In en, this message translates to:
  /// **'文本分析'**
  String get textAnalysis;

  /// No description provided for @voiceTranscription.
  ///
  /// In en, this message translates to:
  /// **'语音转写'**
  String get voiceTranscription;

  /// No description provided for @recordThenTranscribe.
  ///
  /// In en, this message translates to:
  /// **'录音后转文字'**
  String get recordThenTranscribe;

  /// No description provided for @realtimeVoiceTranscription.
  ///
  /// In en, this message translates to:
  /// **'语音实时转写'**
  String get realtimeVoiceTranscription;

  /// No description provided for @realtimeTextDuringRecording.
  ///
  /// In en, this message translates to:
  /// **'录音时实时转文字'**
  String get realtimeTextDuringRecording;

  /// No description provided for @offlineVoiceTranscription.
  ///
  /// In en, this message translates to:
  /// **'离线语音转写'**
  String get offlineVoiceTranscription;

  /// No description provided for @imageRecognition.
  ///
  /// In en, this message translates to:
  /// **'图像识别'**
  String get imageRecognition;

  /// No description provided for @speakerDiarization.
  ///
  /// In en, this message translates to:
  /// **'说话人分离'**
  String get speakerDiarization;

  /// No description provided for @dialogue.
  ///
  /// In en, this message translates to:
  /// **'对话'**
  String get dialogue;

  /// No description provided for @offlineTranscription.
  ///
  /// In en, this message translates to:
  /// **'离线转写'**
  String get offlineTranscription;

  /// No description provided for @wizardSuccess.
  ///
  /// In en, this message translates to:
  /// **'配置成功！畅记已准备就绪'**
  String get wizardSuccess;

  /// No description provided for @wizardSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'保存失败，请重试'**
  String get wizardSaveFailed;

  /// No description provided for @wizardInvalidApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key无效，请检查后重试'**
  String get wizardInvalidApiKey;

  /// No description provided for @wizardVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'验证失败'**
  String get wizardVerifyFailed;

  /// No description provided for @wizardConfigureLater.
  ///
  /// In en, this message translates to:
  /// **'稍后配置'**
  String get wizardConfigureLater;

  /// No description provided for @wizardVerifyAndSave.
  ///
  /// In en, this message translates to:
  /// **'验证并保存'**
  String get wizardVerifyAndSave;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'验证中...'**
  String get verifying;

  /// 保存中
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// 角色名称
  ///
  /// In en, this message translates to:
  /// **'Role Name'**
  String get roleName;

  /// 角色描述
  ///
  /// In en, this message translates to:
  /// **'Role Description'**
  String get roleDescription;

  /// No description provided for @systemPrompt.
  ///
  /// In en, this message translates to:
  /// **'系统提示词（Prompt）'**
  String get systemPrompt;

  /// No description provided for @nameAndPromptRequired.
  ///
  /// In en, this message translates to:
  /// **'名称和Prompt不能为空'**
  String get nameAndPromptRequired;

  /// 确认删除角色
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete Role'**
  String get confirmDeleteRole;

  /// No description provided for @editAndConvertToCustom.
  ///
  /// In en, this message translates to:
  /// **'编辑并转为自定义'**
  String get editAndConvertToCustom;

  /// No description provided for @enableAutoAnalysis.
  ///
  /// In en, this message translates to:
  /// **'启用自动分析'**
  String get enableAutoAnalysis;

  /// No description provided for @autoAnalysisDescription.
  ///
  /// In en, this message translates to:
  /// **'转写完成后自动进行AI分析'**
  String get autoAnalysisDescription;

  /// No description provided for @viewMoreTemplates.
  ///
  /// In en, this message translates to:
  /// **'查看更多模板...'**
  String get viewMoreTemplates;

  /// No description provided for @selectTemplate.
  ///
  /// In en, this message translates to:
  /// **'选择模板方案'**
  String get selectTemplate;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'设置已保存'**
  String get settingsSaved;

  /// No description provided for @defaultTemplateUpdated.
  ///
  /// In en, this message translates to:
  /// **'默认模板已更新'**
  String get defaultTemplateUpdated;

  /// No description provided for @templateDeleted.
  ///
  /// In en, this message translates to:
  /// **'模板已删除'**
  String get templateDeleted;

  /// No description provided for @templateSaved.
  ///
  /// In en, this message translates to:
  /// **'模板已保存'**
  String get templateSaved;

  /// No description provided for @systemDefaultTemplateCannotDelete.
  ///
  /// In en, this message translates to:
  /// **'系统默认模板不能删除'**
  String get systemDefaultTemplateCannotDelete;

  /// No description provided for @deleteTemplate.
  ///
  /// In en, this message translates to:
  /// **'删除模板'**
  String get deleteTemplate;

  /// No description provided for @confirmDeleteTemplate.
  ///
  /// In en, this message translates to:
  /// **'确定要删除这个模板吗？'**
  String get confirmDeleteTemplate;

  /// 模板名称
  ///
  /// In en, this message translates to:
  /// **'Template Name'**
  String get templateName;

  /// No description provided for @shortDescription.
  ///
  /// In en, this message translates to:
  /// **'简短描述'**
  String get shortDescription;

  /// 分类
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @templateContent.
  ///
  /// In en, this message translates to:
  /// **'模板内容'**
  String get templateContent;

  /// No description provided for @useContentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'使用 [content] 作为内容占位符'**
  String get useContentPlaceholder;

  /// No description provided for @fillTemplateNameAndContent.
  ///
  /// In en, this message translates to:
  /// **'请填写模板名称和内容'**
  String get fillTemplateNameAndContent;

  /// No description provided for @confirmDeleteTemplateNamed.
  ///
  /// In en, this message translates to:
  /// **'确定要删除模板「{name}」吗？此操作不可撤销。'**
  String confirmDeleteTemplateNamed(Object name);

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'设为默认'**
  String get setAsDefault;

  /// No description provided for @setAsDefaultTemplate.
  ///
  /// In en, this message translates to:
  /// **'设为默认模板'**
  String get setAsDefaultTemplate;

  /// No description provided for @analysisTemplateSettings.
  ///
  /// In en, this message translates to:
  /// **'分析模板设置'**
  String get analysisTemplateSettings;

  /// No description provided for @inputSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'输入AI分析时使用的系统提示词...'**
  String get inputSystemPrompt;

  /// No description provided for @backupName.
  ///
  /// In en, this message translates to:
  /// **'备份名称（可选）'**
  String get backupName;

  /// No description provided for @includeMediaFiles.
  ///
  /// In en, this message translates to:
  /// **'包含媒体文件'**
  String get includeMediaFiles;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'创建备份'**
  String get createBackup;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'导入备份'**
  String get importBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'恢复此备份'**
  String get restoreBackup;

  /// No description provided for @shareBackup.
  ///
  /// In en, this message translates to:
  /// **'分享备份'**
  String get shareBackup;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'备份失败'**
  String get backupFailed;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'导入成功'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'导入失败'**
  String get importFailed;

  /// 恢复成功
  ///
  /// In en, this message translates to:
  /// **'Restored successfully'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'恢复失败'**
  String get restoreFailed;

  /// No description provided for @confirmRestore.
  ///
  /// In en, this message translates to:
  /// **'确认恢复'**
  String get confirmRestore;

  /// No description provided for @backupFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'备份文件不存在'**
  String get backupFileNotFound;

  /// No description provided for @deleteBackup.
  ///
  /// In en, this message translates to:
  /// **'删除备份'**
  String get deleteBackup;

  /// No description provided for @leaveEmptyForDefault.
  ///
  /// In en, this message translates to:
  /// **'留空将使用默认名称'**
  String get leaveEmptyForDefault;

  /// No description provided for @recycleBin.
  ///
  /// In en, this message translates to:
  /// **'回收站'**
  String get recycleBin;

  /// No description provided for @emptyRecycleBin.
  ///
  /// In en, this message translates to:
  /// **'清空回收站'**
  String get emptyRecycleBin;

  /// No description provided for @recycleBinEmptied.
  ///
  /// In en, this message translates to:
  /// **'回收站已清空'**
  String get recycleBinEmptied;

  /// No description provided for @confirmPermanentDelete.
  ///
  /// In en, this message translates to:
  /// **'确认永久删除'**
  String get confirmPermanentDelete;

  /// No description provided for @permanentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'此操作不可恢复，是否继续？'**
  String get permanentDeleteConfirm;

  /// No description provided for @permanentlyDeleted.
  ///
  /// In en, this message translates to:
  /// **'已永久删除'**
  String get permanentlyDeleted;

  /// No description provided for @copyFilteredLogs.
  ///
  /// In en, this message translates to:
  /// **'复制筛选后的日志'**
  String get copyFilteredLogs;

  /// No description provided for @copyAllLogs.
  ///
  /// In en, this message translates to:
  /// **'复制全部日志'**
  String get copyAllLogs;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'清空日志'**
  String get clearLogs;

  /// No description provided for @searchLogs.
  ///
  /// In en, this message translates to:
  /// **'搜索日志...'**
  String get searchLogs;

  /// No description provided for @allTags.
  ///
  /// In en, this message translates to:
  /// **'全部标签'**
  String get allTags;

  /// No description provided for @filteredLogsCopied.
  ///
  /// In en, this message translates to:
  /// **'筛选后的日志已复制到剪贴板'**
  String get filteredLogsCopied;

  /// No description provided for @allLogsCopied.
  ///
  /// In en, this message translates to:
  /// **'全部日志已复制到剪贴板'**
  String get allLogsCopied;

  /// No description provided for @singleLogCopied.
  ///
  /// In en, this message translates to:
  /// **'已复制单条日志'**
  String get singleLogCopied;

  /// No description provided for @confirmClearLogs.
  ///
  /// In en, this message translates to:
  /// **'确认清空'**
  String get confirmClearLogs;

  /// No description provided for @clearLogsConfirm.
  ///
  /// In en, this message translates to:
  /// **'确定要清空所有日志吗？'**
  String get clearLogsConfirm;

  /// No description provided for @enterNewTag.
  ///
  /// In en, this message translates to:
  /// **'输入新标签'**
  String get enterNewTag;

  /// 搜索工具提示
  ///
  /// In en, this message translates to:
  /// **'Search tools'**
  String get searchTools;

  /// No description provided for @searchOutputContent.
  ///
  /// In en, this message translates to:
  /// **'搜索输出内容...'**
  String get searchOutputContent;

  /// No description provided for @searchRolesOrTemplates.
  ///
  /// In en, this message translates to:
  /// **'搜索角色或模板...'**
  String get searchRolesOrTemplates;

  /// No description provided for @toolOutputs.
  ///
  /// In en, this message translates to:
  /// **'工具台输出'**
  String get toolOutputs;

  /// No description provided for @toolOutputTitle.
  ///
  /// In en, this message translates to:
  /// **'工具台输出'**
  String get toolOutputTitle;

  /// No description provided for @toolOutputContent.
  ///
  /// In en, this message translates to:
  /// **'内容'**
  String get toolOutputContent;

  /// No description provided for @deleteOutputConfirm.
  ///
  /// In en, this message translates to:
  /// **'删除后无法恢复，是否继续？'**
  String get deleteOutputConfirm;

  /// No description provided for @saveResult.
  ///
  /// In en, this message translates to:
  /// **'保存结果'**
  String get saveResult;

  /// No description provided for @inputSaveName.
  ///
  /// In en, this message translates to:
  /// **'输入保存名称'**
  String get inputSaveName;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'名称'**
  String get name;

  /// No description provided for @inputName.
  ///
  /// In en, this message translates to:
  /// **'输入保存名称'**
  String get inputName;

  /// No description provided for @enterContent.
  ///
  /// In en, this message translates to:
  /// **'请输入内容'**
  String get enterContent;

  /// No description provided for @fullScreen.
  ///
  /// In en, this message translates to:
  /// **'全屏查看'**
  String get fullScreen;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'全选'**
  String get selectAll;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'更多操作'**
  String get moreActions;

  /// 添加到日历
  ///
  /// In en, this message translates to:
  /// **'Add to Calendar'**
  String get addToCalendar;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'收藏'**
  String get favorite;

  /// No description provided for @layout.
  ///
  /// In en, this message translates to:
  /// **'布局方式'**
  String get layout;

  /// No description provided for @sortTools.
  ///
  /// In en, this message translates to:
  /// **'排序工具'**
  String get sortTools;

  /// No description provided for @showHideTools.
  ///
  /// In en, this message translates to:
  /// **'显示/隐藏工具'**
  String get showHideTools;

  /// No description provided for @restoreDefault.
  ///
  /// In en, this message translates to:
  /// **'恢复默认'**
  String get restoreDefault;

  /// 工具显示设置标题
  ///
  /// In en, this message translates to:
  /// **'Tool display settings'**
  String get toolDisplaySettings;

  /// No description provided for @max5ToolsOnHome.
  ///
  /// In en, this message translates to:
  /// **'首页最多显示5个工具'**
  String get max5ToolsOnHome;

  /// No description provided for @homeToolsCannotHide.
  ///
  /// In en, this message translates to:
  /// **'展示在首页的工具不得隐藏'**
  String get homeToolsCannotHide;

  /// No description provided for @selectAtLeastOneDataSource.
  ///
  /// In en, this message translates to:
  /// **'请至少选择一种数据源'**
  String get selectAtLeastOneDataSource;

  /// No description provided for @noDataSourceAvailable.
  ///
  /// In en, this message translates to:
  /// **'没有可用的数据源'**
  String get noDataSourceAvailable;

  /// No description provided for @planName.
  ///
  /// In en, this message translates to:
  /// **'方案名称'**
  String get planName;

  /// No description provided for @planContent.
  ///
  /// In en, this message translates to:
  /// **'方案内容'**
  String get planContent;

  /// No description provided for @saveTemporaryPlan.
  ///
  /// In en, this message translates to:
  /// **'保存临时方案'**
  String get saveTemporaryPlan;

  /// No description provided for @inputAiPrompt.
  ///
  /// In en, this message translates to:
  /// **'输入AI的系统提示词'**
  String get inputAiPrompt;

  /// No description provided for @bold.
  ///
  /// In en, this message translates to:
  /// **'加粗'**
  String get bold;

  /// No description provided for @italic.
  ///
  /// In en, this message translates to:
  /// **'斜体'**
  String get italic;

  /// No description provided for @underline.
  ///
  /// In en, this message translates to:
  /// **'下划线'**
  String get underline;

  /// No description provided for @strikethrough.
  ///
  /// In en, this message translates to:
  /// **'删除线'**
  String get strikethrough;

  /// No description provided for @largeHeading.
  ///
  /// In en, this message translates to:
  /// **'大标题'**
  String get largeHeading;

  /// No description provided for @smallHeading.
  ///
  /// In en, this message translates to:
  /// **'小标题'**
  String get smallHeading;

  /// No description provided for @orderedList.
  ///
  /// In en, this message translates to:
  /// **'有序列表'**
  String get orderedList;

  /// No description provided for @unorderedList.
  ///
  /// In en, this message translates to:
  /// **'无序列表'**
  String get unorderedList;

  /// No description provided for @inlineCode.
  ///
  /// In en, this message translates to:
  /// **'行内代码'**
  String get inlineCode;

  /// No description provided for @emoji.
  ///
  /// In en, this message translates to:
  /// **'表情符号'**
  String get emoji;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'分享失败'**
  String get shareFailed;

  /// No description provided for @recordingSaved.
  ///
  /// In en, this message translates to:
  /// **'录音已保存'**
  String get recordingSaved;

  /// No description provided for @microphonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'需要麦克风权限'**
  String get microphonePermissionRequired;

  /// No description provided for @startRecordingFailed.
  ///
  /// In en, this message translates to:
  /// **'开始录音失败'**
  String get startRecordingFailed;

  /// No description provided for @stopRecordingFailed.
  ///
  /// In en, this message translates to:
  /// **'停止录音失败'**
  String get stopRecordingFailed;

  /// No description provided for @imageSelectionNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'图片选择功能待实现'**
  String get imageSelectionNotImplemented;

  /// No description provided for @addYourThoughts.
  ///
  /// In en, this message translates to:
  /// **'在此补充你的想法...'**
  String get addYourThoughts;

  /// No description provided for @inputContent.
  ///
  /// In en, this message translates to:
  /// **'输入内容'**
  String get inputContent;

  /// No description provided for @remainingRecords.
  ///
  /// In en, this message translates to:
  /// **'还有{count}条相关记录'**
  String remainingRecords(Object count);

  /// No description provided for @relatedRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count}条'**
  String relatedRecordCount(Object count);

  /// No description provided for @transcriptionCompleteWithResult.
  ///
  /// In en, this message translates to:
  /// **'转写完成！'**
  String get transcriptionCompleteWithResult;

  /// No description provided for @processingAllUntranscribed.
  ///
  /// In en, this message translates to:
  /// **'将处理所有未正常转写的录音，是否继续？'**
  String get processingAllUntranscribed;

  /// No description provided for @wizardStep1Title.
  ///
  /// In en, this message translates to:
  /// **'3步完成AI服务配置，推荐新手使用'**
  String get wizardStep1Title;

  /// No description provided for @viewLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'查看APP运行日志，用于排查问题'**
  String get viewLogsDesc;

  /// No description provided for @multiApiDesc.
  ///
  /// In en, this message translates to:
  /// **'为语音/图像/文本配置独立API，支持多平台'**
  String get multiApiDesc;

  /// No description provided for @roleManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'管理系统角色和自定义分析角色'**
  String get roleManagementDesc;

  /// No description provided for @templateManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'管理内置和自定义AI分析模板'**
  String get templateManagementDesc;

  /// No description provided for @toolTemplateDesc.
  ///
  /// In en, this message translates to:
  /// **'管理各工具的AI模板，支持新增和删除'**
  String get toolTemplateDesc;

  /// No description provided for @autoAnalysisDesc.
  ///
  /// In en, this message translates to:
  /// **'转写完成后自动进行AI分析'**
  String get autoAnalysisDesc;

  /// No description provided for @statisticsDesc.
  ///
  /// In en, this message translates to:
  /// **'查看记录趋势和热门标签'**
  String get statisticsDesc;

  /// No description provided for @apiAnalysisDesc.
  ///
  /// In en, this message translates to:
  /// **'查看API调用统计和工具使用量'**
  String get apiAnalysisDesc;

  /// No description provided for @dataManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'数据备份、导出和恢复'**
  String get dataManagementDesc;

  /// No description provided for @recycleBinDesc.
  ///
  /// In en, this message translates to:
  /// **'查看和管理已删除的记录'**
  String get recycleBinDesc;

  /// No description provided for @cloudAiDesc.
  ///
  /// In en, this message translates to:
  /// **'解锁云端AI服务，注册送100分钟'**
  String get cloudAiDesc;

  /// No description provided for @useOwnApiKey.
  ///
  /// In en, this message translates to:
  /// **'使用自己的API Key'**
  String get useOwnApiKey;

  /// No description provided for @aiConfig.
  ///
  /// In en, this message translates to:
  /// **'AI配置'**
  String get aiConfig;

  /// No description provided for @debugTools.
  ///
  /// In en, this message translates to:
  /// **'调试工具'**
  String get debugTools;

  /// No description provided for @viewLogs.
  ///
  /// In en, this message translates to:
  /// **'运行日志'**
  String get viewLogs;

  /// No description provided for @quickConfigWizardDesc.
  ///
  /// In en, this message translates to:
  /// **'3步完成AI服务配置，推荐新手使用'**
  String get quickConfigWizardDesc;

  /// No description provided for @multiApiConfigDesc.
  ///
  /// In en, this message translates to:
  /// **'为语音/图像/文本配置独立API，支持多平台'**
  String get multiApiConfigDesc;

  /// No description provided for @aiRoleManagement.
  ///
  /// In en, this message translates to:
  /// **'AI角色管理'**
  String get aiRoleManagement;

  /// No description provided for @aiAnalysisRolesDesc.
  ///
  /// In en, this message translates to:
  /// **'管理系统角色和自定义分析角色'**
  String get aiAnalysisRolesDesc;

  /// No description provided for @promptTemplateManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'管理内置和自定义AI分析模板'**
  String get promptTemplateManagementDesc;

  /// No description provided for @toolAiConfig.
  ///
  /// In en, this message translates to:
  /// **'工具AI配置'**
  String get toolAiConfig;

  /// No description provided for @toolConfigDesc.
  ///
  /// In en, this message translates to:
  /// **'以下是各工具的模板配置，系统默认模板不能删除，可设置默认模板'**
  String get toolConfigDesc;

  /// No description provided for @autoAnalysis.
  ///
  /// In en, this message translates to:
  /// **'自动分析'**
  String get autoAnalysis;

  /// No description provided for @usageStatsDesc.
  ///
  /// In en, this message translates to:
  /// **'查看记录趋势和热门标签'**
  String get usageStatsDesc;

  /// No description provided for @apiCallAnalysis.
  ///
  /// In en, this message translates to:
  /// **'API调用分析'**
  String get apiCallAnalysis;

  /// No description provided for @apiCallAnalysisDesc.
  ///
  /// In en, this message translates to:
  /// **'查看API调用统计和工具使用量'**
  String get apiCallAnalysisDesc;

  /// No description provided for @backupManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'数据备份、导出和恢复'**
  String get backupManagementDesc;

  /// No description provided for @accountManagement.
  ///
  /// In en, this message translates to:
  /// **'账户管理'**
  String get accountManagement;

  /// No description provided for @loginRegisterDesc.
  ///
  /// In en, this message translates to:
  /// **'解锁云端AI服务，注册送100分钟'**
  String get loginRegisterDesc;

  /// No description provided for @transactionRecords.
  ///
  /// In en, this message translates to:
  /// **'交易记录'**
  String get transactionRecords;

  /// No description provided for @aiServiceConfig.
  ///
  /// In en, this message translates to:
  /// **'AI服务配置'**
  String get aiServiceConfig;

  /// No description provided for @cloudAiServiceLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'使用云端分配的API Key'**
  String get cloudAiServiceLoggedIn;

  /// No description provided for @cloudAiServiceNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'登录后开启云端AI服务'**
  String get cloudAiServiceNotLoggedIn;

  /// No description provided for @minutesUsed.
  ///
  /// In en, this message translates to:
  /// **'已用 {used} / {total} 分钟'**
  String minutesUsed(Object total, Object used);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @functionAssignment.
  ///
  /// In en, this message translates to:
  /// **'功能分配'**
  String get functionAssignment;

  /// No description provided for @functionAssignmentDesc.
  ///
  /// In en, this message translates to:
  /// **'为不同功能选择使用的API配置，仅显示支持该功能的模型'**
  String get functionAssignmentDesc;

  /// No description provided for @textAnalysisDesc.
  ///
  /// In en, this message translates to:
  /// **'AI分析、摘要、标题生成'**
  String get textAnalysisDesc;

  /// No description provided for @voiceTranscriptionDesc.
  ///
  /// In en, this message translates to:
  /// **'录音后转文字'**
  String get voiceTranscriptionDesc;

  /// No description provided for @realtimeVoiceTranscriptionDesc.
  ///
  /// In en, this message translates to:
  /// **'录音时实时转文字'**
  String get realtimeVoiceTranscriptionDesc;

  /// No description provided for @offlineVoiceTranscriptionDesc.
  ///
  /// In en, this message translates to:
  /// **'提交音频文件进行离线转写（支持说话人分离）'**
  String get offlineVoiceTranscriptionDesc;

  /// No description provided for @imageRecognitionDesc.
  ///
  /// In en, this message translates to:
  /// **'图片内容识别（OCR）'**
  String get imageRecognitionDesc;

  /// No description provided for @incompatible.
  ///
  /// In en, this message translates to:
  /// **'不兼容'**
  String get incompatible;

  /// No description provided for @featureMismatch.
  ///
  /// In en, this message translates to:
  /// **'功能不匹配'**
  String get featureMismatch;

  /// No description provided for @apiConfigList.
  ///
  /// In en, this message translates to:
  /// **'API配置列表'**
  String get apiConfigList;

  /// No description provided for @noApiConfig.
  ///
  /// In en, this message translates to:
  /// **'暂无API配置'**
  String get noApiConfig;

  /// No description provided for @addApiConfigHint.
  ///
  /// In en, this message translates to:
  /// **'点击右下角 + 添加配置'**
  String get addApiConfigHint;

  /// No description provided for @connectionSuccessDetail.
  ///
  /// In en, this message translates to:
  /// **'API配置有效，可以正常使用。'**
  String get connectionSuccessDetail;

  /// No description provided for @connectionFailedDetail.
  ///
  /// In en, this message translates to:
  /// **'状态码: {code}\n请检查API Key和Base URL是否正确。'**
  String connectionFailedDetail(Object code);

  /// No description provided for @editConfig.
  ///
  /// In en, this message translates to:
  /// **'编辑配置'**
  String get editConfig;

  /// No description provided for @addConfig.
  ///
  /// In en, this message translates to:
  /// **'添加配置'**
  String get addConfig;

  /// No description provided for @configNameHint.
  ///
  /// In en, this message translates to:
  /// **'例如：OpenAI-文本'**
  String get configNameHint;

  /// No description provided for @autoFilterIncompatible.
  ///
  /// In en, this message translates to:
  /// **'已自动过滤不兼容功能'**
  String get autoFilterIncompatible;

  /// No description provided for @noCompatibleFunctions.
  ///
  /// In en, this message translates to:
  /// **'暂无可用的功能支持，请选择其他提供商。'**
  String get noCompatibleFunctions;

  /// No description provided for @providerCapabilityDesc.
  ///
  /// In en, this message translates to:
  /// **'能力说明'**
  String get providerCapabilityDesc;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'模型'**
  String get model;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @appId.
  ///
  /// In en, this message translates to:
  /// **'App ID'**
  String get appId;

  /// No description provided for @accessKeySecret.
  ///
  /// In en, this message translates to:
  /// **'AccessKey Secret'**
  String get accessKeySecret;

  /// No description provided for @baseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get baseUrl;

  /// No description provided for @modelNameHint.
  ///
  /// In en, this message translates to:
  /// **'例如：gpt-4o-mini'**
  String get modelNameHint;

  /// No description provided for @deleteConfig.
  ///
  /// In en, this message translates to:
  /// **'删除配置'**
  String get deleteConfig;

  /// No description provided for @scenarioMeeting.
  ///
  /// In en, this message translates to:
  /// **'会议/沟通记录'**
  String get scenarioMeeting;

  /// No description provided for @scenarioMeetingDesc.
  ///
  /// In en, this message translates to:
  /// **'客户沟通、团队会议、电话录音'**
  String get scenarioMeetingDesc;

  /// No description provided for @scenarioIdea.
  ///
  /// In en, this message translates to:
  /// **'灵感/创意捕捉'**
  String get scenarioIdea;

  /// No description provided for @scenarioIdeaDesc.
  ///
  /// In en, this message translates to:
  /// **'随时记录想法，AI帮你梳理'**
  String get scenarioIdeaDesc;

  /// No description provided for @scenarioStudy.
  ///
  /// In en, this message translates to:
  /// **'学习/课堂笔记'**
  String get scenarioStudy;

  /// No description provided for @scenarioStudyDesc.
  ///
  /// In en, this message translates to:
  /// **'课程录音、读书笔记、知识整理'**
  String get scenarioStudyDesc;

  /// No description provided for @scenarioAll.
  ///
  /// In en, this message translates to:
  /// **'全部场景'**
  String get scenarioAll;

  /// No description provided for @scenarioAllDesc.
  ///
  /// In en, this message translates to:
  /// **'录音转写 + AI分析，完整体验'**
  String get scenarioAllDesc;

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'第一步：你的主要场景是？'**
  String get step1Title;

  /// No description provided for @step2Title.
  ///
  /// In en, this message translates to:
  /// **'第二步：选择AI服务商'**
  String get step2Title;

  /// No description provided for @step3Title.
  ///
  /// In en, this message translates to:
  /// **'第三步：输入API Key'**
  String get step3Title;

  /// No description provided for @providerRecommendDesc.
  ///
  /// In en, this message translates to:
  /// **'推荐以下服务商（按性价比排序）'**
  String get providerRecommendDesc;

  /// No description provided for @wizardTip.
  ///
  /// In en, this message translates to:
  /// **'提示：你只需要填API Key，其他参数已自动配置好'**
  String get wizardTip;

  /// No description provided for @rankRecommended.
  ///
  /// In en, this message translates to:
  /// **'推荐'**
  String get rankRecommended;

  /// No description provided for @rankAlternative.
  ///
  /// In en, this message translates to:
  /// **'备选'**
  String get rankAlternative;

  /// No description provided for @transcription.
  ///
  /// In en, this message translates to:
  /// **'转写'**
  String get transcription;

  /// No description provided for @aiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI分析'**
  String get aiAnalysis;

  /// No description provided for @pricing.
  ///
  /// In en, this message translates to:
  /// **'价格'**
  String get pricing;

  /// No description provided for @inputApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'填入你的 {provider} API Key 即可完成配置'**
  String inputApiKeyHint(Object provider);

  /// No description provided for @modelLabel.
  ///
  /// In en, this message translates to:
  /// **'模型'**
  String get modelLabel;

  /// No description provided for @transcriptionModel.
  ///
  /// In en, this message translates to:
  /// **'转写模型'**
  String get transcriptionModel;

  /// No description provided for @apiKeySecurity.
  ///
  /// In en, this message translates to:
  /// **'你的API Key仅存储在本地设备，加密保存，不会上传到任何第三方服务器。'**
  String get apiKeySecurity;

  /// No description provided for @noApiKey.
  ///
  /// In en, this message translates to:
  /// **'没有API Key？'**
  String get noApiKey;

  /// No description provided for @getApiKeyGuide.
  ///
  /// In en, this message translates to:
  /// **'前往 {provider} 平台获取 API Key'**
  String getApiKeyGuide(Object provider);

  /// No description provided for @getApiKeyGeneric.
  ///
  /// In en, this message translates to:
  /// **'前往服务商官网获取 API Key'**
  String get getApiKeyGeneric;

  /// No description provided for @verifyAndSave.
  ///
  /// In en, this message translates to:
  /// **'验证并保存'**
  String get verifyAndSave;

  /// No description provided for @systemRoles.
  ///
  /// In en, this message translates to:
  /// **'系统角色'**
  String get systemRoles;

  /// No description provided for @customRoles.
  ///
  /// In en, this message translates to:
  /// **'自定义'**
  String get customRoles;

  /// No description provided for @templateLibrary.
  ///
  /// In en, this message translates to:
  /// **'模板库'**
  String get templateLibrary;

  /// No description provided for @noCustomRoles.
  ///
  /// In en, this message translates to:
  /// **'暂无自定义角色'**
  String get noCustomRoles;

  /// No description provided for @addCustomRoleHint.
  ///
  /// In en, this message translates to:
  /// **'点击右下角 + 创建你的专属AI角色'**
  String get addCustomRoleHint;

  /// No description provided for @categoryFrequentlyUsed.
  ///
  /// In en, this message translates to:
  /// **'常用'**
  String get categoryFrequentlyUsed;

  /// No description provided for @categoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'通用'**
  String get categoryGeneral;

  /// No description provided for @categorySolopreneur.
  ///
  /// In en, this message translates to:
  /// **'一人公司'**
  String get categorySolopreneur;

  /// No description provided for @categoryBusiness.
  ///
  /// In en, this message translates to:
  /// **'商业'**
  String get categoryBusiness;

  /// No description provided for @categoryProductivity.
  ///
  /// In en, this message translates to:
  /// **'效率'**
  String get categoryProductivity;

  /// No description provided for @categoryCreative.
  ///
  /// In en, this message translates to:
  /// **'创意'**
  String get categoryCreative;

  /// No description provided for @categoryLearning.
  ///
  /// In en, this message translates to:
  /// **'学习'**
  String get categoryLearning;

  /// No description provided for @categoryLife.
  ///
  /// In en, this message translates to:
  /// **'生活'**
  String get categoryLife;

  /// No description provided for @categoryFun.
  ///
  /// In en, this message translates to:
  /// **'趣味'**
  String get categoryFun;

  /// No description provided for @usedCount.
  ///
  /// In en, this message translates to:
  /// **'使用{count}次'**
  String usedCount(Object count);

  /// No description provided for @prompt.
  ///
  /// In en, this message translates to:
  /// **'提示词（Prompt）'**
  String get prompt;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'编辑'**
  String get edit;

  /// 编辑角色
  ///
  /// In en, this message translates to:
  /// **'Edit Role'**
  String get editRole;

  /// No description provided for @newRole.
  ///
  /// In en, this message translates to:
  /// **'新建角色'**
  String get newRole;

  /// 角色名称提示
  ///
  /// In en, this message translates to:
  /// **'Enter role name'**
  String get roleNameHint;

  /// 角色描述提示
  ///
  /// In en, this message translates to:
  /// **'Enter role description'**
  String get roleDescriptionHint;

  /// No description provided for @systemPromptHint.
  ///
  /// In en, this message translates to:
  /// **'输入系统提示词，定义AI的角色和行为...'**
  String get systemPromptHint;

  /// No description provided for @deleteRoleConfirm.
  ///
  /// In en, this message translates to:
  /// **'确定要删除角色「{name}」吗？此操作不可恢复。'**
  String deleteRoleConfirm(Object name);

  /// No description provided for @selectAutoAnalysisPlan.
  ///
  /// In en, this message translates to:
  /// **'选择自动分析方案'**
  String get selectAutoAnalysisPlan;

  /// No description provided for @selectAutoAnalysisPlanDesc.
  ///
  /// In en, this message translates to:
  /// **'选择转写后自动使用的分析角色或模板'**
  String get selectAutoAnalysisPlanDesc;

  /// No description provided for @enableAutoAnalysisFirst.
  ///
  /// In en, this message translates to:
  /// **'请先启用自动分析开关'**
  String get enableAutoAnalysisFirst;

  /// No description provided for @noAvailableRoles.
  ///
  /// In en, this message translates to:
  /// **'暂无可用角色'**
  String get noAvailableRoles;

  /// No description provided for @addFromTemplateLibrary.
  ///
  /// In en, this message translates to:
  /// **'从模板库添加方案'**
  String get addFromTemplateLibrary;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'已添加'**
  String get added;

  /// No description provided for @autoAnalysisInstructions.
  ///
  /// In en, this message translates to:
  /// **'说明'**
  String get autoAnalysisInstructions;

  /// No description provided for @autoAnalysisInstruction1.
  ///
  /// In en, this message translates to:
  /// **'• 开启自动分析后，录音转写完成将自动使用所选方案进行分析'**
  String get autoAnalysisInstruction1;

  /// No description provided for @autoAnalysisInstruction2.
  ///
  /// In en, this message translates to:
  /// **'• 自动分析会消耗API调用次数，请确保API配置正确'**
  String get autoAnalysisInstruction2;

  /// No description provided for @autoAnalysisInstruction3.
  ///
  /// In en, this message translates to:
  /// **'• 可以从模板库添加方案，也可以直接使用系统或自定义角色'**
  String get autoAnalysisInstruction3;

  /// No description provided for @autoAnalysisInstruction4.
  ///
  /// In en, this message translates to:
  /// **'• 保存的模板方案会独立存储，即使模板库更新也不会丢失'**
  String get autoAnalysisInstruction4;

  /// No description provided for @toolConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'工具方案配置'**
  String get toolConfigTitle;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'全部'**
  String get allCategories;

  /// No description provided for @productivityTools.
  ///
  /// In en, this message translates to:
  /// **'效率工具'**
  String get productivityTools;

  /// No description provided for @analysisTools.
  ///
  /// In en, this message translates to:
  /// **'分析工具'**
  String get analysisTools;

  /// No description provided for @managementTools.
  ///
  /// In en, this message translates to:
  /// **'管理工具'**
  String get managementTools;

  /// No description provided for @aiTools.
  ///
  /// In en, this message translates to:
  /// **'AI工具'**
  String get aiTools;

  /// No description provided for @newTemplate.
  ///
  /// In en, this message translates to:
  /// **'新建模板'**
  String get newTemplate;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'默认'**
  String get defaultLabel;

  /// No description provided for @addTemplateFor.
  ///
  /// In en, this message translates to:
  /// **'为{tool}新增模板'**
  String addTemplateFor(Object tool);

  /// 模板名称提示
  ///
  /// In en, this message translates to:
  /// **'Enter template name'**
  String get templateNameHint;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'简要描述这个模板的用途'**
  String get descriptionHint;

  /// No description provided for @aiPrompt.
  ///
  /// In en, this message translates to:
  /// **'系统提示词'**
  String get aiPrompt;

  /// No description provided for @aiPromptHint.
  ///
  /// In en, this message translates to:
  /// **'输入AI的系统提示词'**
  String get aiPromptHint;

  /// No description provided for @editTemplate.
  ///
  /// In en, this message translates to:
  /// **'编辑模板'**
  String get editTemplate;

  /// No description provided for @fillNameAndPrompt.
  ///
  /// In en, this message translates to:
  /// **'请填写名称和提示词'**
  String get fillNameAndPrompt;

  /// No description provided for @localBackupManagement.
  ///
  /// In en, this message translates to:
  /// **'本地备份管理'**
  String get localBackupManagement;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'创建中...'**
  String get creating;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'立即备份'**
  String get backupNow;

  /// No description provided for @restoreFromFile.
  ///
  /// In en, this message translates to:
  /// **'从文件恢复'**
  String get restoreFromFile;

  /// No description provided for @restoring.
  ///
  /// In en, this message translates to:
  /// **'恢复中...'**
  String get restoring;

  /// No description provided for @noBackups.
  ///
  /// In en, this message translates to:
  /// **'暂无备份'**
  String get noBackups;

  /// No description provided for @createFirstBackup.
  ///
  /// In en, this message translates to:
  /// **'点击\"立即备份\"创建您的第一个备份'**
  String get createFirstBackup;

  /// No description provided for @recordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} 条记录'**
  String recordsCount(Object count);

  /// No description provided for @restoreThisBackup.
  ///
  /// In en, this message translates to:
  /// **'恢复此备份'**
  String get restoreThisBackup;

  /// No description provided for @backupNameHint.
  ///
  /// In en, this message translates to:
  /// **'留空将使用默认名称'**
  String get backupNameHint;

  /// No description provided for @selectBackupContent.
  ///
  /// In en, this message translates to:
  /// **'选择备份内容'**
  String get selectBackupContent;

  /// No description provided for @recordsData.
  ///
  /// In en, this message translates to:
  /// **'记录数据'**
  String get recordsData;

  /// No description provided for @recordsDataDesc.
  ///
  /// In en, this message translates to:
  /// **'所有录音记录、文本、标签、周报、脑图等'**
  String get recordsDataDesc;

  /// No description provided for @aiConfigBackup.
  ///
  /// In en, this message translates to:
  /// **'AI 配置'**
  String get aiConfigBackup;

  /// No description provided for @aiConfigBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'API密钥、AI角色、Prompt模板、分析模板、自动分析设置'**
  String get aiConfigBackupDesc;

  /// No description provided for @includeMediaFilesDesc.
  ///
  /// In en, this message translates to:
  /// **'音频、图片等附件（会显著增加备份大小）'**
  String get includeMediaFilesDesc;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'确认恢复'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'恢复备份将覆盖当前所有数据（包括记录、设置等）。\n\n此操作不可撤销，是否继续？'**
  String get restoreConfirmMessage;

  /// No description provided for @backupNotFound.
  ///
  /// In en, this message translates to:
  /// **'备份文件不存在'**
  String get backupNotFound;

  /// No description provided for @backupShareText.
  ///
  /// In en, this message translates to:
  /// **'畅记备份: {name}'**
  String backupShareText(Object name);

  /// No description provided for @deleteBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'确定要删除备份 \"{name}\" 吗？'**
  String deleteBackupConfirm(Object name);

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'清空'**
  String get empty;

  /// No description provided for @recycleBinEmpty.
  ///
  /// In en, this message translates to:
  /// **'回收站为空'**
  String get recycleBinEmpty;

  /// No description provided for @recycleBinRetention.
  ///
  /// In en, this message translates to:
  /// **'删除的记录将在这里保留7天'**
  String get recycleBinRetention;

  /// 剩余天数
  ///
  /// In en, this message translates to:
  /// **'{count} days remaining'**
  String remainingDays(int count);

  /// No description provided for @willBeClearedSoon.
  ///
  /// In en, this message translates to:
  /// **'即将清除'**
  String get willBeClearedSoon;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'创建于 {date}'**
  String createdAt(Object date);

  /// No description provided for @deletedAt.
  ///
  /// In en, this message translates to:
  /// **'删除于 {date}'**
  String deletedAt(Object date);

  /// No description provided for @permanentDelete.
  ///
  /// In en, this message translates to:
  /// **'永久删除'**
  String get permanentDelete;

  /// No description provided for @clearRecordsConfirm.
  ///
  /// In en, this message translates to:
  /// **'将永久删除{count}条记录，此操作不可恢复，是否继续？'**
  String clearRecordsConfirm(Object count);

  /// No description provided for @logScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'运行日志'**
  String get logScreenTitle;

  /// No description provided for @selectTagFilter.
  ///
  /// In en, this message translates to:
  /// **'选择标签筛选'**
  String get selectTagFilter;

  /// No description provided for @tagFilter.
  ///
  /// In en, this message translates to:
  /// **'标签: {tag}'**
  String tagFilter(Object tag);

  /// No description provided for @allLevels.
  ///
  /// In en, this message translates to:
  /// **'全部'**
  String get allLevels;

  /// No description provided for @levelInfo.
  ///
  /// In en, this message translates to:
  /// **'信息'**
  String get levelInfo;

  /// No description provided for @levelWarning.
  ///
  /// In en, this message translates to:
  /// **'警告'**
  String get levelWarning;

  /// No description provided for @levelError.
  ///
  /// In en, this message translates to:
  /// **'错误'**
  String get levelError;

  /// No description provided for @noLogs.
  ///
  /// In en, this message translates to:
  /// **'暂无日志'**
  String get noLogs;

  /// No description provided for @showingCount.
  ///
  /// In en, this message translates to:
  /// **'显示 {count} 条'**
  String showingCount(Object count);

  /// No description provided for @totalCount.
  ///
  /// In en, this message translates to:
  /// **'总计 {count} 条'**
  String totalCount(Object count);

  /// No description provided for @weeklyReportTemplate.
  ///
  /// In en, this message translates to:
  /// **'周报模板'**
  String get weeklyReportTemplate;

  /// No description provided for @mindMapTemplate.
  ///
  /// In en, this message translates to:
  /// **'脑图模板'**
  String get mindMapTemplate;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'系统'**
  String get system;

  /// 模板描述
  ///
  /// In en, this message translates to:
  /// **'Template Description'**
  String get templateDescription;

  /// No description provided for @systemPromptLabel.
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get systemPromptLabel;

  /// No description provided for @noTemplates.
  ///
  /// In en, this message translates to:
  /// **'暂无模板'**
  String get noTemplates;

  /// No description provided for @createNewTemplateHint.
  ///
  /// In en, this message translates to:
  /// **'点击右上角 + 创建新模板'**
  String get createNewTemplateHint;

  /// No description provided for @builtIn.
  ///
  /// In en, this message translates to:
  /// **'内置'**
  String get builtIn;

  /// No description provided for @templateDetail.
  ///
  /// In en, this message translates to:
  /// **'模板详情'**
  String get templateDetail;

  /// No description provided for @templateContentLabel.
  ///
  /// In en, this message translates to:
  /// **'模板内容'**
  String get templateContentLabel;

  /// No description provided for @editTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'编辑模板'**
  String get editTemplateTitle;

  /// No description provided for @createTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'创建新模板'**
  String get createTemplateTitle;

  /// No description provided for @shortDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'一句话描述模板用途'**
  String get shortDescriptionHint;

  /// No description provided for @contentPlaceholderHint.
  ///
  /// In en, this message translates to:
  /// **'提示：使用 [content] 表示用户录音/笔记内容的位置'**
  String get contentPlaceholderHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'保存修改'**
  String get saveChanges;

  /// No description provided for @createTemplate.
  ///
  /// In en, this message translates to:
  /// **'创建模板'**
  String get createTemplate;

  /// No description provided for @templateUpdated.
  ///
  /// In en, this message translates to:
  /// **'模板已更新'**
  String get templateUpdated;

  /// No description provided for @templateCreated.
  ///
  /// In en, this message translates to:
  /// **'模板已创建'**
  String get templateCreated;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'登录后解锁云端AI服务'**
  String get loginSubtitle;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'密码'**
  String get password;

  /// No description provided for @registerGift.
  ///
  /// In en, this message translates to:
  /// **'注册即送100分钟体验额度'**
  String get registerGift;

  /// No description provided for @newUserGiftDetail.
  ///
  /// In en, this message translates to:
  /// **'100分钟转写额度，有效期7天'**
  String get newUserGiftDetail;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'分钟'**
  String get minutes;

  /// No description provided for @retryFailedTranscriptions.
  ///
  /// In en, this message translates to:
  /// **'重新转写'**
  String get retryFailedTranscriptions;

  /// No description provided for @retryFailedTranscriptionsConfirm.
  ///
  /// In en, this message translates to:
  /// **'将处理所有未正常转写的录音，是否继续？'**
  String get retryFailedTranscriptionsConfirm;

  /// No description provided for @retranscribeSuccess.
  ///
  /// In en, this message translates to:
  /// **'转写成功'**
  String get retranscribeSuccess;

  /// No description provided for @retranscribeError.
  ///
  /// In en, this message translates to:
  /// **'转写失败'**
  String get retranscribeError;

  /// No description provided for @generateResult.
  ///
  /// In en, this message translates to:
  /// **'生成结果'**
  String get generateResult;

  /// No description provided for @savedResults.
  ///
  /// In en, this message translates to:
  /// **'已保存的结果'**
  String get savedResults;

  /// No description provided for @savedResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count} 份'**
  String savedResultCount(Object count);

  /// No description provided for @noSavedResults.
  ///
  /// In en, this message translates to:
  /// **'暂无保存的结果'**
  String get noSavedResults;

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'发送邮件'**
  String get sendEmail;

  /// No description provided for @sendEmailDesc.
  ///
  /// In en, this message translates to:
  /// **'调用系统邮件客户端'**
  String get sendEmailDesc;

  /// No description provided for @addToCalendarDesc.
  ///
  /// In en, this message translates to:
  /// **'创建日程提醒'**
  String get addToCalendarDesc;

  /// No description provided for @copyAll.
  ///
  /// In en, this message translates to:
  /// **'复制全部'**
  String get copyAll;

  /// No description provided for @copyAllDesc.
  ///
  /// In en, this message translates to:
  /// **'复制到剪贴板'**
  String get copyAllDesc;

  /// No description provided for @shareDesc.
  ///
  /// In en, this message translates to:
  /// **'分享到其他应用'**
  String get shareDesc;

  /// No description provided for @template.
  ///
  /// In en, this message translates to:
  /// **'模板'**
  String get template;

  /// No description provided for @defaultTemplate.
  ///
  /// In en, this message translates to:
  /// **'默认'**
  String get defaultTemplate;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'收起'**
  String get expand;

  /// No description provided for @switchTemplate.
  ///
  /// In en, this message translates to:
  /// **'切换'**
  String get switchTemplate;

  /// No description provided for @aiAnalyzingData.
  ///
  /// In en, this message translates to:
  /// **'AI正在分析数据...'**
  String get aiAnalyzingData;

  /// No description provided for @usingTemplate.
  ///
  /// In en, this message translates to:
  /// **'使用模板'**
  String get usingTemplate;

  /// No description provided for @noTools.
  ///
  /// In en, this message translates to:
  /// **'暂无工具'**
  String get noTools;

  /// No description provided for @addToolsInSettings.
  ///
  /// In en, this message translates to:
  /// **'请在设置中添加工具'**
  String get addToolsInSettings;

  /// No description provided for @recentlyUsed.
  ///
  /// In en, this message translates to:
  /// **'最近使用'**
  String get recentlyUsed;

  /// No description provided for @workbenchSettings.
  ///
  /// In en, this message translates to:
  /// **'工作台设置'**
  String get workbenchSettings;

  /// No description provided for @cardLayout.
  ///
  /// In en, this message translates to:
  /// **'卡片式'**
  String get cardLayout;

  /// No description provided for @listLayout.
  ///
  /// In en, this message translates to:
  /// **'列表式'**
  String get listLayout;

  /// No description provided for @reorderTools.
  ///
  /// In en, this message translates to:
  /// **'拖拽调整工具顺序'**
  String get reorderTools;

  /// No description provided for @customizeVisibleTools.
  ///
  /// In en, this message translates to:
  /// **'自定义显示哪些工具'**
  String get customizeVisibleTools;

  /// No description provided for @resetToInitialLayout.
  ///
  /// In en, this message translates to:
  /// **'重置为初始布局'**
  String get resetToInitialLayout;

  /// No description provided for @settingsRestored.
  ///
  /// In en, this message translates to:
  /// **'已恢复默认设置'**
  String get settingsRestored;

  /// No description provided for @tagManagement.
  ///
  /// In en, this message translates to:
  /// **'标签管理'**
  String get tagManagement;

  /// No description provided for @selectedTags.
  ///
  /// In en, this message translates to:
  /// **'已选标签'**
  String get selectedTags;

  /// No description provided for @availableTags.
  ///
  /// In en, this message translates to:
  /// **'可选标签'**
  String get availableTags;

  /// No description provided for @noMatchingOutputs.
  ///
  /// In en, this message translates to:
  /// **'没有符合条件的输出'**
  String get noMatchingOutputs;

  /// No description provided for @adjustSearchCriteria.
  ///
  /// In en, this message translates to:
  /// **'尝试调整搜索条件'**
  String get adjustSearchCriteria;

  /// No description provided for @toolOutputSavedHint.
  ///
  /// In en, this message translates to:
  /// **'使用工具后保存的内容会显示在这里'**
  String get toolOutputSavedHint;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @addedToCalendar.
  ///
  /// In en, this message translates to:
  /// **'已添加到日历'**
  String get addedToCalendar;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'天'**
  String get days;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'记录'**
  String get records;

  /// No description provided for @toolOutput.
  ///
  /// In en, this message translates to:
  /// **'工具输出'**
  String get toolOutput;

  /// No description provided for @aiAnalysisSummary.
  ///
  /// In en, this message translates to:
  /// **'AI分析摘要'**
  String get aiAnalysisSummary;

  /// 已选项目数量
  ///
  /// In en, this message translates to:
  /// **'已选 {count} 项'**
  String selectedItems(int count);

  /// 已选标签
  ///
  /// In en, this message translates to:
  /// **'已选'**
  String get selected;

  /// 选择AI角色标签
  ///
  /// In en, this message translates to:
  /// **'选择AI角色'**
  String get selectAiRole;

  /// 搜索角色或模板提示
  ///
  /// In en, this message translates to:
  /// **'搜索角色或模板...'**
  String get searchRoleOrTemplate;

  /// 没有匹配系统角色提示
  ///
  /// In en, this message translates to:
  /// **'没有匹配的系统角色'**
  String get noMatchingSystemRole;

  /// 没有自定义角色提示
  ///
  /// In en, this message translates to:
  /// **'暂无自定义角色'**
  String get noCustomRole;

  /// 点击创建角色提示
  ///
  /// In en, this message translates to:
  /// **'点击创建你的角色'**
  String get clickToCreateRole;

  /// 没有模板提示
  ///
  /// In en, this message translates to:
  /// **'暂无模板'**
  String get noTemplate;

  /// 数据预览标签
  ///
  /// In en, this message translates to:
  /// **'数据预览'**
  String get dataPreview;

  /// 数据源配置标签
  ///
  /// In en, this message translates to:
  /// **'数据源配置'**
  String get dataSourceConfig;

  /// 确认并执行按钮
  ///
  /// In en, this message translates to:
  /// **'确认并执行'**
  String get confirmAndExecute;

  /// 请选择至少一种数据源提示
  ///
  /// In en, this message translates to:
  /// **'请至少选择一种数据源'**
  String get pleaseSelectAtLeastOneDataSource;

  /// 数据确认标签
  ///
  /// In en, this message translates to:
  /// **'数据确认'**
  String get dataConfirm;

  /// AI 分类标签
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// 效率分类标签
  ///
  /// In en, this message translates to:
  /// **'Efficiency'**
  String get efficiency;

  /// 分析
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// 管理分类标签
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// 首页工具不能隐藏提示
  ///
  /// In en, this message translates to:
  /// **'Home tools cannot be hidden'**
  String get homeToolsCannotBeHidden;

  /// 首页最多5个工具提示
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 tools on home page'**
  String get homeMaxFiveTools;

  /// 隐藏标签
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// 已选择首页显示的工具数量
  ///
  /// In en, this message translates to:
  /// **'{count} tools selected for home display'**
  String toolsSelectedForHomeDisplay(int count);

  /// 工具名称标签
  ///
  /// In en, this message translates to:
  /// **'Tool name'**
  String get toolName;

  /// 在首页显示标签
  ///
  /// In en, this message translates to:
  /// **'Show on home'**
  String get showOnHome;

  /// API密钥必填提示
  ///
  /// In en, this message translates to:
  /// **'API key is required'**
  String get apiKeyRequired;

  /// 模型名称必填提示
  ///
  /// In en, this message translates to:
  /// **'Model name is required'**
  String get modelNameRequired;

  /// 未知错误提示
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// 基础URL提示
  ///
  /// In en, this message translates to:
  /// **'Optional: Custom API base URL'**
  String get baseUrlHint;

  /// 安全提示标题
  ///
  /// In en, this message translates to:
  /// **'Security Notice'**
  String get securityNotice;

  /// 安全提示详情
  ///
  /// In en, this message translates to:
  /// **'Your API key is stored locally and will not be uploaded to the server'**
  String get securityNoticeDetail;

  /// API密钥向导标题
  ///
  /// In en, this message translates to:
  /// **'API Key Wizard'**
  String get apiKeyWizard;

  /// 上一步按钮
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get prevStep;

  /// 选择提供商描述
  ///
  /// In en, this message translates to:
  /// **'Choose an AI service provider'**
  String get selectProviderDesc;

  /// 自定义提供商描述
  ///
  /// In en, this message translates to:
  /// **'Enter custom provider details'**
  String get customProviderDesc;

  /// 选择功能标题
  ///
  /// In en, this message translates to:
  /// **'Select Features'**
  String get selectFeatures;

  /// 选择功能描述
  ///
  /// In en, this message translates to:
  /// **'Choose which features to enable'**
  String get selectFeaturesDesc;

  /// 输入API密钥标题
  ///
  /// In en, this message translates to:
  /// **'Enter API Key'**
  String get enterApiKey;

  /// 输入API密钥描述
  ///
  /// In en, this message translates to:
  /// **'Enter your API key for the selected provider'**
  String get enterApiKeyDesc;

  /// 自定义提供商名称提示
  ///
  /// In en, this message translates to:
  /// **'Custom provider name'**
  String get customProviderNameHint;

  /// 确认配置标题
  ///
  /// In en, this message translates to:
  /// **'Confirm Configuration'**
  String get confirmConfig;

  /// 确认配置描述
  ///
  /// In en, this message translates to:
  /// **'Please confirm your API configuration'**
  String get confirmConfigDesc;

  /// 提供商标签
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// 已选功能标签
  ///
  /// In en, this message translates to:
  /// **'Selected Features'**
  String get selectedFeatures;

  /// 完成按钮
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// 下一步按钮
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextStep;

  /// 输入自定义提供商名称提示
  ///
  /// In en, this message translates to:
  /// **'Please enter custom provider name'**
  String get enterCustomProviderName;

  /// App ID必填提示
  ///
  /// In en, this message translates to:
  /// **'App ID is required'**
  String get appIdRequired;

  /// 没有提示模板
  ///
  /// In en, this message translates to:
  /// **'No prompt templates'**
  String get noPromptTemplates;

  /// 添加提示模板提示
  ///
  /// In en, this message translates to:
  /// **'Add a new prompt template'**
  String get addPromptTemplateHint;

  /// 分析模型标签
  ///
  /// In en, this message translates to:
  /// **'Analysis Model'**
  String get analysisModel;

  /// 摘要模型标签
  ///
  /// In en, this message translates to:
  /// **'Summary Model'**
  String get summaryModel;

  /// 通义千问实时模型
  ///
  /// In en, this message translates to:
  /// **'Qwen Realtime'**
  String get qwenRealtime;

  /// 通义千问音频模型
  ///
  /// In en, this message translates to:
  /// **'Qwen Audio'**
  String get qwenAudio;

  /// Paraformer实时模型
  ///
  /// In en, this message translates to:
  /// **'Paraformer Realtime'**
  String get paraformerRealtime;

  /// Paraformer模型
  ///
  /// In en, this message translates to:
  /// **'Paraformer'**
  String get paraformer;

  /// 通义千问Max模型
  ///
  /// In en, this message translates to:
  /// **'Qwen Max'**
  String get qwenMax;

  /// 通义千问Plus模型
  ///
  /// In en, this message translates to:
  /// **'Qwen Plus'**
  String get qwenPlus;

  /// 通义千问Turbo模型
  ///
  /// In en, this message translates to:
  /// **'Qwen Turbo'**
  String get qwenTurbo;

  /// DeepSeek聊天模型
  ///
  /// In en, this message translates to:
  /// **'DeepSeek Chat'**
  String get deepseekChat;

  /// DeepSeek推理模型
  ///
  /// In en, this message translates to:
  /// **'DeepSeek Reasoner'**
  String get deepseekReasoner;

  /// 文本类型
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// 语音类型
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// 图片类型
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// 更多工具
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String moreTools(int count);

  /// 近7天API调用趋势
  ///
  /// In en, this message translates to:
  /// **'Recent 7 Days API Trend'**
  String get recent7DaysApiTrend;

  /// 永久删除确认消息
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. Are you sure you want to permanently delete this record?'**
  String get permanentDeleteMessage;

  /// 清空回收站确认消息
  ///
  /// In en, this message translates to:
  /// **'All records in the recycle bin will be permanently deleted. This action cannot be undone.'**
  String get emptyRecycleBinMessage;

  /// 清空回收站成功
  ///
  /// In en, this message translates to:
  /// **'Recycle bin emptied successfully'**
  String get emptyRecycleBinSuccess;

  /// 没有已删除的笔记
  ///
  /// In en, this message translates to:
  /// **'No deleted notes'**
  String get noDeletedNotes;

  /// 已删除笔记提示
  ///
  /// In en, this message translates to:
  /// **'Deleted notes will be kept here for 7 days'**
  String get deletedNotesHint;

  /// 恢复按钮
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// 未命名笔记
  ///
  /// In en, this message translates to:
  /// **'Untitled Note'**
  String get untitledNote;

  /// 清空日志成功
  ///
  /// In en, this message translates to:
  /// **'Logs cleared successfully'**
  String get clearLogsSuccess;

  /// 清空日志失败
  ///
  /// In en, this message translates to:
  /// **'Failed to clear logs'**
  String get clearLogsFailed;

  /// 复制成功
  ///
  /// In en, this message translates to:
  /// **'Copied successfully'**
  String get copySuccess;

  /// 日志查看器
  ///
  /// In en, this message translates to:
  /// **'Log Viewer'**
  String get logViewer;

  /// 复制日志
  ///
  /// In en, this message translates to:
  /// **'Copy Logs'**
  String get copyLogs;

  /// 分享日志
  ///
  /// In en, this message translates to:
  /// **'Share Logs'**
  String get shareLogs;

  /// 加载日志失败
  ///
  /// In en, this message translates to:
  /// **'Failed to load logs'**
  String get loadLogsFailed;

  /// 没有日志提示
  ///
  /// In en, this message translates to:
  /// **'No logs available'**
  String get noLogsHint;

  /// 自动分析开关
  ///
  /// In en, this message translates to:
  /// **'Auto Analysis'**
  String get autoAnalysisSwitch;

  /// 启用自动分析
  ///
  /// In en, this message translates to:
  /// **'Enable Auto Analysis'**
  String get autoAnalysisEnabled;

  /// 启用自动分析描述
  ///
  /// In en, this message translates to:
  /// **'Automatically analyze after transcription'**
  String get autoAnalysisEnabledDesc;

  /// 分析模式
  ///
  /// In en, this message translates to:
  /// **'Analysis Mode'**
  String get analysisMode;

  /// 快速分析
  ///
  /// In en, this message translates to:
  /// **'Quick Analysis'**
  String get quickAnalysis;

  /// 快速分析描述
  ///
  /// In en, this message translates to:
  /// **'Fast analysis with basic summary'**
  String get quickAnalysisDesc;

  /// 标准分析
  ///
  /// In en, this message translates to:
  /// **'Standard Analysis'**
  String get standardAnalysis;

  /// 标准分析描述
  ///
  /// In en, this message translates to:
  /// **'Balanced analysis with moderate detail'**
  String get standardAnalysisDesc;

  /// 深度分析
  ///
  /// In en, this message translates to:
  /// **'Deep Analysis'**
  String get deepAnalysis;

  /// 深度分析描述
  ///
  /// In en, this message translates to:
  /// **'Detailed analysis with comprehensive insights'**
  String get deepAnalysisDesc;

  /// 分析延迟
  ///
  /// In en, this message translates to:
  /// **'Analysis Delay'**
  String get analysisDelay;

  /// 延迟秒数
  ///
  /// In en, this message translates to:
  /// **'Delay Seconds'**
  String get delaySeconds;

  /// 延迟秒数描述
  ///
  /// In en, this message translates to:
  /// **'Delay before starting analysis after transcription'**
  String get delaySecondsDesc;

  /// 自动分析项目
  ///
  /// In en, this message translates to:
  /// **'Auto Analysis Items'**
  String get autoAnalysisItems;

  /// 自动摘要
  ///
  /// In en, this message translates to:
  /// **'Auto Summarize'**
  String get autoSummarize;

  /// 自动摘要描述
  ///
  /// In en, this message translates to:
  /// **'Automatically generate summary'**
  String get autoSummarizeDesc;

  /// 自动提取任务
  ///
  /// In en, this message translates to:
  /// **'Auto Extract Tasks'**
  String get autoExtractTasks;

  /// 自动提取任务描述
  ///
  /// In en, this message translates to:
  /// **'Automatically extract tasks from content'**
  String get autoExtractTasksDesc;

  /// 自动建议标签
  ///
  /// In en, this message translates to:
  /// **'Auto Suggest Tags'**
  String get autoSuggestTags;

  /// 自动建议标签描述
  ///
  /// In en, this message translates to:
  /// **'Automatically suggest tags for content'**
  String get autoSuggestTagsDesc;

  /// 分析模板
  ///
  /// In en, this message translates to:
  /// **'Analysis Template'**
  String get analysisTemplate;

  /// 没有分析模板
  ///
  /// In en, this message translates to:
  /// **'No analysis templates'**
  String get noAnalysisTemplates;

  /// 添加分析模板提示
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a new analysis template'**
  String get addAnalysisTemplateHint;

  /// 模板描述提示
  ///
  /// In en, this message translates to:
  /// **'Enter template description'**
  String get templateDescriptionHint;

  /// 模板提示词
  ///
  /// In en, this message translates to:
  /// **'Template Prompt'**
  String get templatePrompt;

  /// 模板提示词提示
  ///
  /// In en, this message translates to:
  /// **'Enter the AI prompt for this template'**
  String get templatePromptHint;

  /// 设为默认描述
  ///
  /// In en, this message translates to:
  /// **'Set as default template for analysis'**
  String get setAsDefaultDesc;

  /// 添加模板
  ///
  /// In en, this message translates to:
  /// **'Add Template'**
  String get addTemplate;

  /// 模板名称必填
  ///
  /// In en, this message translates to:
  /// **'Template name is required'**
  String get templateNameRequired;

  /// 删除模板确认消息
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete template \"{name}\"?'**
  String confirmDeleteTemplateMessage(String name);

  /// 备份成功
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backupSuccess;

  /// 恢复确认消息
  ///
  /// In en, this message translates to:
  /// **'Restoring will overwrite current data. Continue?'**
  String get confirmRestoreMessage;

  /// 删除备份
  ///
  /// In en, this message translates to:
  /// **'Delete Backup'**
  String get confirmDeleteBackup;

  /// 删除备份确认消息
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this backup?'**
  String get confirmDeleteBackupMessage;

  /// 创建备份提示
  ///
  /// In en, this message translates to:
  /// **'Tap \"Create Backup\" to create your first backup'**
  String get createBackupHint;

  /// 重试按钮
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// 摘要
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// 聊天
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// 提示词内容
  ///
  /// In en, this message translates to:
  /// **'Prompt Content'**
  String get promptContent;

  /// 提示词内容提示
  ///
  /// In en, this message translates to:
  /// **'Enter the prompt content'**
  String get promptContentHint;

  /// 编辑提示模板
  ///
  /// In en, this message translates to:
  /// **'Edit Prompt Template'**
  String get editPromptTemplate;

  /// 添加提示模板
  ///
  /// In en, this message translates to:
  /// **'Add Prompt Template'**
  String get addPromptTemplate;

  /// 输入你的想法
  ///
  /// In en, this message translates to:
  /// **'Input your thoughts...'**
  String get inputYourThoughts;

  /// 角色管理
  ///
  /// In en, this message translates to:
  /// **'Role Management'**
  String get roleManagement;

  /// 没有角色
  ///
  /// In en, this message translates to:
  /// **'No roles'**
  String get noRoles;

  /// 添加角色提示
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a role'**
  String get addRoleHint;

  /// 添加角色
  ///
  /// In en, this message translates to:
  /// **'Add Role'**
  String get addRole;

  /// 角色提示词
  ///
  /// In en, this message translates to:
  /// **'Role Prompt'**
  String get rolePrompt;

  /// 角色提示词提示
  ///
  /// In en, this message translates to:
  /// **'Enter the system prompt for this role'**
  String get rolePromptHint;

  /// 角色名称必填
  ///
  /// In en, this message translates to:
  /// **'Role name is required'**
  String get roleNameRequired;

  /// 删除角色确认消息
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete role \"{name}\"?'**
  String confirmDeleteRoleMessage(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
