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

  /// Cancel button text
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

  /// Today date label
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

  /// Delete confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this note?'**
  String get confirmDelete;

  /// Delete confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
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
