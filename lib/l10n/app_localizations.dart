import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ga.dart';
import 'app_localizations_ru.dart';
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
/// import 'l10n/app_localizations.dart';
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
    Locale('ga'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @addGame.
  ///
  /// In en, this message translates to:
  /// **'Add Game'**
  String get addGame;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @allGames.
  ///
  /// In en, this message translates to:
  /// **'All games'**
  String get allGames;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @chooseADownloadFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose a download folder'**
  String get chooseADownloadFolder;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @collectionName.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get collectionName;

  /// No description provided for @collections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @deleteArchiveAfterExtraction.
  ///
  /// In en, this message translates to:
  /// **'Delete archive after extraction'**
  String get deleteArchiveAfterExtraction;

  /// No description provided for @describeWhatWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Describe what went wrong…'**
  String get describeWhatWentWrong;

  /// No description provided for @downloadFolder.
  ///
  /// In en, this message translates to:
  /// **'Download folder'**
  String get downloadFolder;

  /// No description provided for @excludeDownloadFolder.
  ///
  /// In en, this message translates to:
  /// **'Exclude download folder'**
  String get excludeDownloadFolder;

  /// No description provided for @exclusionRequestSentToWindowsDefender.
  ///
  /// In en, this message translates to:
  /// **'Exclusion request sent to Windows Defender.'**
  String get exclusionRequestSentToWindowsDefender;

  /// No description provided for @extract.
  ///
  /// In en, this message translates to:
  /// **'Extract'**
  String get extract;

  /// No description provided for @extractAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Extract automatically'**
  String get extractAutomatically;

  /// No description provided for @finishSignIn.
  ///
  /// In en, this message translates to:
  /// **'Finish sign-in'**
  String get finishSignIn;

  /// No description provided for @fpsCounterWhilePlaying.
  ///
  /// In en, this message translates to:
  /// **'FPS counter while playing'**
  String get fpsCounterWhilePlaying;

  /// No description provided for @hideAdultGames.
  ///
  /// In en, this message translates to:
  /// **'Hide adult games'**
  String get hideAdultGames;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @installAllRuntimes.
  ///
  /// In en, this message translates to:
  /// **'Install all runtimes'**
  String get installAllRuntimes;

  /// No description provided for @installRuntimes.
  ///
  /// In en, this message translates to:
  /// **'Install runtimes'**
  String get installRuntimes;

  /// No description provided for @mostViewed.
  ///
  /// In en, this message translates to:
  /// **'Most viewed'**
  String get mostViewed;

  /// No description provided for @nameAZ.
  ///
  /// In en, this message translates to:
  /// **'Name A–Z'**
  String get nameAZ;

  /// No description provided for @newCollection.
  ///
  /// In en, this message translates to:
  /// **'New Collection'**
  String get newCollection;

  /// No description provided for @noCollectionsYet.
  ///
  /// In en, this message translates to:
  /// **'No collections yet.'**
  String get noCollectionsYet;

  /// No description provided for @noDownloadsYetBrowseTheCatalogAndPickAGame.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet. Browse the catalog and pick a game.'**
  String get noDownloadsYetBrowseTheCatalogAndPickAGame;

  /// No description provided for @noFavoritesYetTapTheHeartOnALibraryGame.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet. Tap the heart on a library game.'**
  String get noFavoritesYetTapTheHeartOnALibraryGame;

  /// No description provided for @noGameExecutablesFoundInThatFolder.
  ///
  /// In en, this message translates to:
  /// **'No game executables found in that folder.'**
  String get noGameExecutablesFoundInThatFolder;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get openFolder;

  /// No description provided for @openedTheOfficialInstallersInYourBrowser.
  ///
  /// In en, this message translates to:
  /// **'Opened the official installers in your browser.'**
  String get openedTheOfficialInstallersInYourBrowser;

  /// No description provided for @pasteTheAuthCodeFromYourBrowser.
  ///
  /// In en, this message translates to:
  /// **'Paste the auth code from your browser'**
  String get pasteTheAuthCodeFromYourBrowser;

  /// No description provided for @recentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get recentlyAdded;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get refreshStatus;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @removeFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove from library'**
  String get removeFromLibrary;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @scanForGames.
  ///
  /// In en, this message translates to:
  /// **'Scan for Games'**
  String get scanForGames;

  /// No description provided for @searchGames.
  ///
  /// In en, this message translates to:
  /// **'Search games…'**
  String get searchGames;

  /// No description provided for @searchLibrary.
  ///
  /// In en, this message translates to:
  /// **'Search library…'**
  String get searchLibrary;

  /// No description provided for @sendReport.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get sendReport;

  /// No description provided for @setExecutable.
  ///
  /// In en, this message translates to:
  /// **'Set executable'**
  String get setExecutable;

  /// No description provided for @showHideShortcut.
  ///
  /// In en, this message translates to:
  /// **'Show / hide shortcut'**
  String get showHideShortcut;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInWithUploadhaven.
  ///
  /// In en, this message translates to:
  /// **'Sign in with UploadHaven'**
  String get signInWithUploadhaven;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size: '**
  String get size;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @steamunlockedOrg.
  ///
  /// In en, this message translates to:
  /// **'steamunlocked.org'**
  String get steamunlockedOrg;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @thisDownloadsTheOfficialMicrosoftInstallersForVisualCAndDirectxAndOpensThemForYouContinue.
  ///
  /// In en, this message translates to:
  /// **'This downloads the official Microsoft installers for Visual C++ and DirectX and opens them for you. Continue?'**
  String
  get thisDownloadsTheOfficialMicrosoftInstallersForVisualCAndDirectxAndOpensThemForYouContinue;

  /// No description provided for @traditionalEnglish.
  ///
  /// In en, this message translates to:
  /// **'Traditional English'**
  String get traditionalEnglish;

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// No description provided for @uploadhavenCom.
  ///
  /// In en, this message translates to:
  /// **'uploadhaven.com'**
  String get uploadhavenCom;

  /// No description provided for @windowsCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Windows compatibility'**
  String get windowsCompatibility;

  /// No description provided for @windowsCompatibilityLayer.
  ///
  /// In en, this message translates to:
  /// **'Windows compatibility layer'**
  String get windowsCompatibilityLayer;

  /// No description provided for @yourLibraryIsEmptyDownloadGamesOrScanAFolder.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty. Download games or scan a folder.'**
  String get yourLibraryIsEmptyDownloadGamesOrScanAFolder;

  /// No description provided for @uploadhavenPro.
  ///
  /// In en, this message translates to:
  /// **'UploadHaven Pro'**
  String get uploadhavenPro;

  /// No description provided for @freeAccount.
  ///
  /// In en, this message translates to:
  /// **'Free account'**
  String get freeAccount;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @connectionDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Connection diagnostics'**
  String get connectionDiagnostics;

  /// No description provided for @reportABug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get reportABug;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get manageSubscription;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed'**
  String get signInFailed;

  /// No description provided for @reportSentThankYou.
  ///
  /// In en, this message translates to:
  /// **'Report sent. Thank you!'**
  String get reportSentThankYou;

  /// No description provided for @couldNotSendYouCanOnlySendOneReportPerHour.
  ///
  /// In en, this message translates to:
  /// **'Could not send. You can only send one report per hour.'**
  String get couldNotSendYouCanOnlySendOneReportPerHour;

  /// No description provided for @couldNotLoadTheCatalogCheckYourConnectionAndRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load the catalog. Check your connection and retry.'**
  String get couldNotLoadTheCatalogCheckYourConnectionAndRetry;

  /// No description provided for @runningWindowsGamesHere.
  ///
  /// In en, this message translates to:
  /// **'Running Windows games here'**
  String get runningWindowsGamesHere;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @chooseTheGameExecutable.
  ///
  /// In en, this message translates to:
  /// **'Choose the game executable'**
  String get chooseTheGameExecutable;

  /// No description provided for @chooseDownloadFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose download folder'**
  String get chooseDownloadFolder;

  /// No description provided for @chooseAFolderToScanForGames.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder to scan for games'**
  String get chooseAFolderToScanForGames;

  /// No description provided for @chooseWineCrossoverBinary.
  ///
  /// In en, this message translates to:
  /// **'Choose wine/crossover binary'**
  String get chooseWineCrossoverBinary;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get upToDate;

  /// No description provided for @couldNotLaunchTheGame.
  ///
  /// In en, this message translates to:
  /// **'Could not launch the game.'**
  String get couldNotLaunchTheGame;

  /// No description provided for @steamunlockedLauncher.
  ///
  /// In en, this message translates to:
  /// **'SteamUnlocked Launcher'**
  String get steamunlockedLauncher;

  /// No description provided for @couldNotResolveADownloadLink.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve a download link'**
  String get couldNotResolveADownloadLink;

  /// No description provided for @chooseADownloadFolderInSettingsFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a download folder in Settings first'**
  String get chooseADownloadFolderInSettingsFirst;

  /// No description provided for @couldNotSend.
  ///
  /// In en, this message translates to:
  /// **'Could not send'**
  String get couldNotSend;

  /// No description provided for @noExecutableSet.
  ///
  /// In en, this message translates to:
  /// **'No executable set'**
  String get noExecutableSet;

  /// No description provided for @concurrentDownloads.
  ///
  /// In en, this message translates to:
  /// **'Concurrent downloads'**
  String get concurrentDownloads;

  /// No description provided for @proMembersCanRunUpTo5AtOnce.
  ///
  /// In en, this message translates to:
  /// **'Pro members can run up to 5 at once'**
  String get proMembersCanRunUpTo5AtOnce;

  /// No description provided for @experimentalNeedsACompatibleOverlayToolEGMangohudOnLinux.
  ///
  /// In en, this message translates to:
  /// **'Experimental — needs a compatible overlay tool (e.g. MangoHud on Linux)'**
  String get experimentalNeedsACompatibleOverlayToolEGMangohudOnLinux;

  /// No description provided for @runtimeInstallersAreAWindowsOnlyFeature.
  ///
  /// In en, this message translates to:
  /// **'Runtime installers are a Windows-only feature.'**
  String get runtimeInstallersAreAWindowsOnlyFeature;

  /// No description provided for @windowsDefender.
  ///
  /// In en, this message translates to:
  /// **'Windows Defender'**
  String get windowsDefender;

  /// No description provided for @defenderCanSlowDownOrBreakDownloadsExcludeYourDownloadFolderFromScanning.
  ///
  /// In en, this message translates to:
  /// **'Defender can slow down or break downloads. Exclude your download folder from scanning.'**
  String
  get defenderCanSlowDownOrBreakDownloadsExcludeYourDownloadFolderFromScanning;

  /// No description provided for @mostWindowsGamesNeedVisualCDirectxOrNetRuntimesInstallThemOnceAndEveryGameBenefits.
  ///
  /// In en, this message translates to:
  /// **'Most Windows games need Visual C++, DirectX or .NET runtimes. Install them once and every game benefits.'**
  String
  get mostWindowsGamesNeedVisualCDirectxOrNetRuntimesInstallThemOnceAndEveryGameBenefits;

  /// No description provided for @gamesLaunchThroughSteamProtonWhenInstalledOrWineAsAFallbackInstallProtonFromSteamForTheBestResults.
  ///
  /// In en, this message translates to:
  /// **'Games launch through Steam Proton when installed, or Wine as a fallback. Install Proton from Steam for the best results.'**
  String
  get gamesLaunchThroughSteamProtonWhenInstalledOrWineAsAFallbackInstallProtonFromSteamForTheBestResults;

  /// No description provided for @macosHasNoNativeExeSupportPointSettingsToAWineBuildFromCrossoverTheGamePortingToolkitOrWhiskyAndGamesWillLaunchThroughIt.
  ///
  /// In en, this message translates to:
  /// **'macOS has no native .exe support. Point Settings to a Wine build from CrossOver, the Game Porting Toolkit or Whisky, and games will launch through it.'**
  String
  get macosHasNoNativeExeSupportPointSettingsToAWineBuildFromCrossoverTheGamePortingToolkitOrWhiskyAndGamesWillLaunchThroughIt;

  /// No description provided for @youAreOnWindowsGamesJustRunNothingExtraNeeded.
  ///
  /// In en, this message translates to:
  /// **'You are on Windows — games just run. Nothing extra needed.'**
  String get youAreOnWindowsGamesJustRunNothingExtraNeeded;

  /// No description provided for @gamesRunThroughSteamProtonOrWineWhenFoundOnThisSystem.
  ///
  /// In en, this message translates to:
  /// **'Games run through Steam Proton or Wine when found on this system.'**
  String get gamesRunThroughSteamProtonOrWineWhenFoundOnThisSystem;

  /// No description provided for @useCrossoverGamePortingToolkitOrWhiskySetTheWineBinaryPathHere.
  ///
  /// In en, this message translates to:
  /// **'Use CrossOver, Game Porting Toolkit or Whisky — set the wine binary path here'**
  String get useCrossoverGamePortingToolkitOrWhiskySetTheWineBinaryPathHere;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @ctrlShiftF10.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+Shift+F10'**
  String get ctrlShiftF10;

  /// No description provided for @altShiftF11.
  ///
  /// In en, this message translates to:
  /// **'Alt+Shift+F11'**
  String get altShiftF11;

  /// No description provided for @browseAndDownloadGames.
  ///
  /// In en, this message translates to:
  /// **'Browse and download games'**
  String get browseAndDownloadGames;

  /// No description provided for @signInForProFeatures.
  ///
  /// In en, this message translates to:
  /// **'Sign in for Pro features'**
  String get signInForProFeatures;

  /// No description provided for @chooseWhereDownloadedGamesAreStoredAndHowTheyRun.
  ///
  /// In en, this message translates to:
  /// **'Choose where downloaded games are stored and how they run'**
  String get chooseWhereDownloadedGamesAreStoredAndHowTheyRun;

  /// No description provided for @dns.
  ///
  /// In en, this message translates to:
  /// **'DNS'**
  String get dns;

  /// No description provided for @tcp.
  ///
  /// In en, this message translates to:
  /// **'TCP'**
  String get tcp;

  /// No description provided for @tls.
  ///
  /// In en, this message translates to:
  /// **'TLS'**
  String get tls;

  /// No description provided for @api.
  ///
  /// In en, this message translates to:
  /// **'API'**
  String get api;

  /// No description provided for @testing.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get testing;

  /// No description provided for @runConnectivityTest.
  ///
  /// In en, this message translates to:
  /// **'Run connectivity test'**
  String get runConnectivityTest;

  /// No description provided for @proRequiredForMore.
  ///
  /// In en, this message translates to:
  /// **'Pro required for more'**
  String get proRequiredForMore;

  /// No description provided for @inDownloads.
  ///
  /// In en, this message translates to:
  /// **'In Downloads'**
  String get inDownloads;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @queued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get queued;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @extracting.
  ///
  /// In en, this message translates to:
  /// **'extracting'**
  String get extracting;

  /// No description provided for @resolving.
  ///
  /// In en, this message translates to:
  /// **'Resolving…'**
  String get resolving;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @noProtonWineFoundInstallProtonViaSteamOrConfigureARunnerInSettings.
  ///
  /// In en, this message translates to:
  /// **'No Proton/Wine found. Install Proton via Steam or configure a runner in Settings.'**
  String get noProtonWineFoundInstallProtonViaSteamOrConfigureARunnerInSettings;

  /// No description provided for @installCrossoverOrSetAWineWhiskyBinaryInSettingsToPlayWindowsGames.
  ///
  /// In en, this message translates to:
  /// **'Install CrossOver or set a Wine/whisky binary in Settings to play Windows games.'**
  String get installCrossoverOrSetAWineWhiskyBinaryInSettingsToPlayWindowsGames;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @browseDownloadAndPlayYourGames.
  ///
  /// In en, this message translates to:
  /// **'Browse, download and play your games'**
  String get browseDownloadAndPlayYourGames;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version '**
  String get version;

  /// No description provided for @yourDownloadFolderIsWhereGamesLandAfterExtraction.
  ///
  /// In en, this message translates to:
  /// **'Your download folder is where games land after extraction.'**
  String get yourDownloadFolderIsWhereGamesLandAfterExtraction;

  /// No description provided for @newVersion.
  ///
  /// In en, this message translates to:
  /// **'New version'**
  String get newVersion;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **' available'**
  String get available;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open '**
  String get open;

  /// No description provided for @onGitlab.
  ///
  /// In en, this message translates to:
  /// **' on GitLab'**
  String get onGitlab;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'games'**
  String get games;

  /// No description provided for @downloadS.
  ///
  /// In en, this message translates to:
  /// **'download(s)'**
  String get downloadS;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get active;

  /// No description provided for @concurrent.
  ///
  /// In en, this message translates to:
  /// **'Concurrent'**
  String get concurrent;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories: '**
  String get categories;

  /// No description provided for @latency.
  ///
  /// In en, this message translates to:
  /// **'Latency: '**
  String get latency;

  /// No description provided for @ms.
  ///
  /// In en, this message translates to:
  /// **' ms'**
  String get ms;

  /// No description provided for @collectionsFor.
  ///
  /// In en, this message translates to:
  /// **'Collections for '**
  String get collectionsFor;

  /// No description provided for @simultaneousDownloads.
  ///
  /// In en, this message translates to:
  /// **'Simultaneous downloads: '**
  String get simultaneousDownloads;

  /// No description provided for @sizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeLabel;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @readyToExtract.
  ///
  /// In en, this message translates to:
  /// **'Ready to extract'**
  String get readyToExtract;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;
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
      <String>['en', 'ga', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ga':
      return AppLocalizationsGa();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
