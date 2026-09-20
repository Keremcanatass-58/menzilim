import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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
    Locale('tr'),
  ];

  /// Marka adı; çevrilmez.
  ///
  /// In tr, this message translates to:
  /// **'MENZİLİM'**
  String get appName;

  /// No description provided for @commonRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get commonRetry;

  /// No description provided for @commonSessionMissing.
  ///
  /// In tr, this message translates to:
  /// **'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yap.'**
  String get commonSessionMissing;

  /// No description provided for @commonMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dakika'**
  String commonMinutes(int minutes);

  /// No description provided for @commonMinutesShort.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dk'**
  String commonMinutesShort(int minutes);

  /// No description provided for @commonPercent.
  ///
  /// In tr, this message translates to:
  /// **'%{value}'**
  String commonPercent(int value);

  /// No description provided for @commonTaskCompleted.
  ///
  /// In tr, this message translates to:
  /// **'{title} tamamlandı! 🎉'**
  String commonTaskCompleted(String title);

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get settingsLanguage;

  /// Dil adı kendi dilinde gösterilir.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get settingsLanguageTurkish;

  /// Dil adı kendi dilinde gösterilir.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsTheme.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystemHint.
  ///
  /// In tr, this message translates to:
  /// **'Sistem seçeneği cihazının görünüm ayarını izler.'**
  String get settingsThemeSystemHint;

  /// No description provided for @loginTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar hoş geldin.'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim yolculuğuna kaldığın yerden devam et.'**
  String get loginSubtitle;

  /// No description provided for @loginFillFields.
  ///
  /// In tr, this message translates to:
  /// **'E-posta ve şifre alanlarını doldur.'**
  String get loginFillFields;

  /// No description provided for @loginSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Giriş başarılı.'**
  String get loginSuccess;

  /// No description provided for @loginFailed.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapılamadı. E-posta veya şifreyi kontrol et.'**
  String get loginFailed;

  /// No description provided for @loginButton.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get loginButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu? '**
  String get loginNoAccount;

  /// No description provided for @emailLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In tr, this message translates to:
  /// **'ornek@mail.com'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get passwordLabel;

  /// No description provided for @registerButton.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get registerButton;

  /// No description provided for @registerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğunu başlat.'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabını oluştur ve kişisel gelişim yolculuğuna başla.'**
  String get registerSubtitle;

  /// No description provided for @registerFillAll.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen tüm alanları doldur.'**
  String get registerFillAll;

  /// No description provided for @registerInvalidEmail.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi gir.'**
  String get registerInvalidEmail;

  /// No description provided for @registerPasswordTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı.'**
  String get registerPasswordTooShort;

  /// No description provided for @registerPasswordsMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor.'**
  String get registerPasswordsMismatch;

  /// No description provided for @registerSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın başarıyla oluşturuldu.'**
  String get registerSuccess;

  /// No description provided for @registerUnexpectedError.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt sırasında beklenmeyen bir hata oluştu.'**
  String get registerUnexpectedError;

  /// No description provided for @registerConfirmPasswordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Tekrar'**
  String get registerConfirmPasswordLabel;

  /// No description provided for @registerCreateAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Oluştur'**
  String get registerCreateAccount;

  /// No description provided for @registerHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı? Giriş yap'**
  String get registerHaveAccount;

  /// No description provided for @commonErrorGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu.'**
  String get commonErrorGeneric;

  /// No description provided for @commonBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get commonBack;

  /// No description provided for @commonContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get commonContinue;

  /// No description provided for @onboardingProfessionsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Meslekler yüklenirken bir hata oluştu.'**
  String get onboardingProfessionsLoadError;

  /// No description provided for @onboardingSpecializationsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Uzmanlıklar yüklenirken bir hata oluştu.'**
  String get onboardingSpecializationsLoadError;

  /// No description provided for @onboardingSelectProfession.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir meslek seç.'**
  String get onboardingSelectProfession;

  /// No description provided for @onboardingSelectSpecialization.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir uzmanlık alanı seç.'**
  String get onboardingSelectSpecialization;

  /// No description provided for @onboardingSelectExperience.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen deneyim seviyeni seç.'**
  String get onboardingSelectExperience;

  /// No description provided for @onboardingEnterCareerGoal.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen kariyer hedefini yaz.'**
  String get onboardingEnterCareerGoal;

  /// No description provided for @onboardingSelectDailyTime.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen günlük öğrenme süresini seç.'**
  String get onboardingSelectDailyTime;

  /// No description provided for @onboardingSaved.
  ///
  /// In tr, this message translates to:
  /// **'Profilin başarıyla oluşturuldu. MENZİLİM yolculuğun başlıyor!'**
  String get onboardingSaved;

  /// No description provided for @onboardingSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Profilin kaydedilemedi. Lütfen tekrar dene.'**
  String get onboardingSaveFailed;

  /// No description provided for @onboardingStep.
  ///
  /// In tr, this message translates to:
  /// **'{current} / {total}'**
  String onboardingStep(int current, int total);

  /// No description provided for @onboardingProfessionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kariyer yolculuğuna başlayalım.'**
  String get onboardingProfessionTitle;

  /// No description provided for @onboardingProfessionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hangi alanda kendini geliştirmek istiyorsun?'**
  String get onboardingProfessionSubtitle;

  /// No description provided for @onboardingSpecializationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uzmanlık alanını seç.'**
  String get onboardingSpecializationTitle;

  /// No description provided for @onboardingSpecializationSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{profession} alanında hangi yönde ilerlemek istiyorsun?'**
  String onboardingSpecializationSubtitle(String profession);

  /// No description provided for @onboardingExperienceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kendini hangi seviyede görüyorsun?'**
  String get onboardingExperienceTitle;

  /// No description provided for @onboardingExperienceSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Böylece öğrenme planını mevcut seviyene göre oluşturabiliriz.'**
  String get onboardingExperienceSubtitle;

  /// No description provided for @experienceBeginner.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get experienceBeginner;

  /// No description provided for @experienceBeginnerDescription.
  ///
  /// In tr, this message translates to:
  /// **'Temel seviyeden başlıyorum.'**
  String get experienceBeginnerDescription;

  /// No description provided for @experienceIntermediate.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get experienceIntermediate;

  /// No description provided for @experienceIntermediateDescription.
  ///
  /// In tr, this message translates to:
  /// **'Temelleri biliyorum, kendimi geliştiriyorum.'**
  String get experienceIntermediateDescription;

  /// No description provided for @experienceAdvanced.
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get experienceAdvanced;

  /// No description provided for @experienceAdvancedDescription.
  ///
  /// In tr, this message translates to:
  /// **'Deneyimliyim ve uzmanlaşmak istiyorum.'**
  String get experienceAdvancedDescription;

  /// No description provided for @onboardingCareerGoalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kariyer hedefin nedir?'**
  String get onboardingCareerGoalTitle;

  /// No description provided for @onboardingCareerGoalSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'MENZİLİM sana uygun bir yol oluşturabilsin.'**
  String get onboardingCareerGoalSubtitle;

  /// No description provided for @onboardingCareerGoalHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Backend alanında profesyonelleşmek ve işe girmek istiyorum.'**
  String get onboardingCareerGoalHint;

  /// No description provided for @onboardingDailyTimeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günde ne kadar zaman ayırabilirsin?'**
  String get onboardingDailyTimeTitle;

  /// No description provided for @onboardingDailyTimeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Gerçekçi bir süre seç. Önemli olan sürdürülebilirlik.'**
  String get onboardingDailyTimeSubtitle;

  /// No description provided for @dailyTime30.
  ///
  /// In tr, this message translates to:
  /// **'30 dakika'**
  String get dailyTime30;

  /// No description provided for @dailyTime30Description.
  ///
  /// In tr, this message translates to:
  /// **'Yoğun günler için'**
  String get dailyTime30Description;

  /// No description provided for @dailyTime60.
  ///
  /// In tr, this message translates to:
  /// **'1 saat'**
  String get dailyTime60;

  /// No description provided for @dailyTime60Description.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli gelişim için'**
  String get dailyTime60Description;

  /// No description provided for @dailyTime90.
  ///
  /// In tr, this message translates to:
  /// **'1,5 saat'**
  String get dailyTime90;

  /// No description provided for @dailyTime90Description.
  ///
  /// In tr, this message translates to:
  /// **'Daha hızlı ilerlemek için'**
  String get dailyTime90Description;

  /// No description provided for @dailyTime120.
  ///
  /// In tr, this message translates to:
  /// **'2 saat'**
  String get dailyTime120;

  /// No description provided for @dailyTime120Description.
  ///
  /// In tr, this message translates to:
  /// **'Yoğun öğrenme için'**
  String get dailyTime120Description;

  /// No description provided for @onboardingSaving.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor...'**
  String get onboardingSaving;

  /// No description provided for @onboardingFinish.
  ///
  /// In tr, this message translates to:
  /// **'MENZİLİM Yolculuğuna Başla'**
  String get onboardingFinish;

  /// No description provided for @dashboardLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Dashboard bilgileri yüklenemedi.'**
  String get dashboardLoadError;

  /// No description provided for @dashboardRecommendationsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Öneriler yüklenemedi.'**
  String get dashboardRecommendationsLoadError;

  /// No description provided for @dashboardSkillsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Beceriler yüklenemedi.'**
  String get dashboardSkillsLoadError;

  /// No description provided for @dashboardTaskCompleteError.
  ///
  /// In tr, this message translates to:
  /// **'Görev tamamlanırken bir hata oluştu.'**
  String get dashboardTaskCompleteError;

  /// No description provided for @contentOpenError.
  ///
  /// In tr, this message translates to:
  /// **'İçerik açılamadı.'**
  String get contentOpenError;

  /// No description provided for @dashboardGreeting.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba 👋'**
  String get dashboardGreeting;

  /// No description provided for @dashboardHeadline.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim yolculuğuna devam et.'**
  String get dashboardHeadline;

  /// No description provided for @dashboardSubheadline.
  ///
  /// In tr, this message translates to:
  /// **'Bugün kendin için bir adım daha at.'**
  String get dashboardSubheadline;

  /// No description provided for @dashboardTodayGoal.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü Hedef'**
  String get dashboardTodayGoal;

  /// No description provided for @dashboardDailyGoal.
  ///
  /// In tr, this message translates to:
  /// **'Günlük öğrenme hedefin: {minutes} dakika'**
  String dashboardDailyGoal(int minutes);

  /// No description provided for @dashboardMinutesCompleted.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dakika tamamlandı'**
  String dashboardMinutesCompleted(int minutes);

  /// No description provided for @dashboardProfileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profilin'**
  String get dashboardProfileTitle;

  /// No description provided for @profileProfession.
  ///
  /// In tr, this message translates to:
  /// **'Meslek'**
  String get profileProfession;

  /// No description provided for @profileSpecialization.
  ///
  /// In tr, this message translates to:
  /// **'Uzmanlık'**
  String get profileSpecialization;

  /// No description provided for @profileLevel.
  ///
  /// In tr, this message translates to:
  /// **'Seviye'**
  String get profileLevel;

  /// No description provided for @profileCareerGoal.
  ///
  /// In tr, this message translates to:
  /// **'Kariyer hedefi'**
  String get profileCareerGoal;

  /// No description provided for @dashboardProgressTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme'**
  String get dashboardProgressTitle;

  /// No description provided for @dashboardDailyPlan.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Plan'**
  String get dashboardDailyPlan;

  /// No description provided for @dashboardTasksCompleted.
  ///
  /// In tr, this message translates to:
  /// **'{completed} / {total} görev tamamlandı'**
  String dashboardTasksCompleted(int completed, int total);

  /// No description provided for @dashboardMinutesOfTotal.
  ///
  /// In tr, this message translates to:
  /// **'{completed} / {total} dakika'**
  String dashboardMinutesOfTotal(int completed, int total);

  /// No description provided for @dashboardContent.
  ///
  /// In tr, this message translates to:
  /// **'İçerik'**
  String get dashboardContent;

  /// No description provided for @dashboardContentCompleted.
  ///
  /// In tr, this message translates to:
  /// **'{count} tamamlandı'**
  String dashboardContentCompleted(int count);

  /// No description provided for @dashboardContentInProgress.
  ///
  /// In tr, this message translates to:
  /// **'{count} devam ediyor'**
  String dashboardContentInProgress(int count);

  /// No description provided for @dailyPlanTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün Yol Haritası'**
  String get dailyPlanTitle;

  /// No description provided for @dailyPlanEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bugün için henüz görev bulunmuyor.'**
  String get dailyPlanEmpty;

  /// No description provided for @dailyPlanTaskFallbackDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü gelişim planındaki görev.'**
  String get dailyPlanTaskFallbackDescription;

  /// No description provided for @recommendationsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sana Özel İçerikler'**
  String get recommendationsTitle;

  /// No description provided for @recommendationsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Şu an sana özel yeni içerik yok.'**
  String get recommendationsEmpty;

  /// No description provided for @dashboardContinueLearning.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenmeye Devam Et'**
  String get dashboardContinueLearning;

  /// No description provided for @dashboardAskCoach.
  ///
  /// In tr, this message translates to:
  /// **'AI Koç\'a Sor'**
  String get dashboardAskCoach;

  /// No description provided for @dashboardViewProgress.
  ///
  /// In tr, this message translates to:
  /// **'İlerlememi Gör'**
  String get dashboardViewProgress;

  /// No description provided for @taskGoToContent.
  ///
  /// In tr, this message translates to:
  /// **'İçeriğe Git'**
  String get taskGoToContent;

  /// No description provided for @recommendationInProgress.
  ///
  /// In tr, this message translates to:
  /// **'Devam ediyor'**
  String get recommendationInProgress;

  /// No description provided for @recommendationNew.
  ///
  /// In tr, this message translates to:
  /// **'Yeni'**
  String get recommendationNew;

  /// No description provided for @recommendationStart.
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get recommendationStart;

  /// No description provided for @skillsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeteneklerim'**
  String get skillsTitle;

  /// No description provided for @discoverTitle.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get discoverTitle;

  /// No description provided for @newsSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugün Senin Alanında'**
  String get newsSectionTitle;

  /// No description provided for @newsViewAll.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Haberler'**
  String get newsViewAll;

  /// No description provided for @newsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Haberler yüklenemedi.'**
  String get newsLoadError;

  /// No description provided for @newsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Şu an alanında gösterilecek haber yok.'**
  String get newsEmpty;

  /// No description provided for @skillsSummaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Becerilerim'**
  String get skillsSummaryTitle;

  /// No description provided for @skillsSummaryCounts.
  ///
  /// In tr, this message translates to:
  /// **'{total} yetenek · {started} tanesinde ilerleme'**
  String skillsSummaryCounts(int total, int started);

  /// No description provided for @skillsSummaryEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir yetenekte ilerleme kaydetmedin.'**
  String get skillsSummaryEmpty;

  /// No description provided for @skillsViewAll.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Yetenekleri Gör'**
  String get skillsViewAll;

  /// No description provided for @skillsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Yetenekler yüklenemedi.'**
  String get skillsLoadError;

  /// No description provided for @skillsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Uzmanlık alanın için henüz yetenek bulunmuyor.'**
  String get skillsEmpty;

  /// No description provided for @skillsMapTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yetenek haritan'**
  String get skillsMapTitle;

  /// No description provided for @skillsMapSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{total} yetenekten {started} tanesinde ilerleme kaydettin.'**
  String skillsMapSubtitle(int total, int started);

  /// No description provided for @skillsStatContent.
  ///
  /// In tr, this message translates to:
  /// **'İçerik: {completed} / {total}'**
  String skillsStatContent(int completed, int total);

  /// No description provided for @skillsStatQuiz.
  ///
  /// In tr, this message translates to:
  /// **'Quiz: {attempted} / {total}'**
  String skillsStatQuiz(int attempted, int total);

  /// No description provided for @skillsStatInProgress.
  ///
  /// In tr, this message translates to:
  /// **'Devam eden: {count}'**
  String skillsStatInProgress(int count);

  /// No description provided for @skillsStatBestScore.
  ///
  /// In tr, this message translates to:
  /// **'En iyi skor: %{score}'**
  String skillsStatBestScore(int score);

  /// No description provided for @skillsStatLatestScore.
  ///
  /// In tr, this message translates to:
  /// **'Son skor: %{score}'**
  String skillsStatLatestScore(int score);

  /// No description provided for @skillsNoMaterial.
  ///
  /// In tr, this message translates to:
  /// **'Bu yetenek için henüz içerik veya quiz eklenmedi.'**
  String get skillsNoMaterial;

  /// No description provided for @progressTitle.
  ///
  /// In tr, this message translates to:
  /// **'Genel İlerleme'**
  String get progressTitle;

  /// No description provided for @progressLoadError.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme yüklenemedi.'**
  String get progressLoadError;

  /// No description provided for @progressNoData.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme verisi bulunamadı.'**
  String get progressNoData;

  /// No description provided for @progressOverview.
  ///
  /// In tr, this message translates to:
  /// **'Genel Bakış'**
  String get progressOverview;

  /// No description provided for @progressCompletedTasks.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan Görev'**
  String get progressCompletedTasks;

  /// No description provided for @progressUnitTotal.
  ///
  /// In tr, this message translates to:
  /// **'toplam'**
  String get progressUnitTotal;

  /// No description provided for @progressLearningTime.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenme Süresi'**
  String get progressLearningTime;

  /// No description provided for @progressUnitMinutes.
  ///
  /// In tr, this message translates to:
  /// **'dakika'**
  String get progressUnitMinutes;

  /// No description provided for @progressCompletedPlans.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan Plan'**
  String get progressCompletedPlans;

  /// No description provided for @progressUnitPlans.
  ///
  /// In tr, this message translates to:
  /// **'plan'**
  String get progressUnitPlans;

  /// No description provided for @progressActiveDays.
  ///
  /// In tr, this message translates to:
  /// **'Aktif Gün'**
  String get progressActiveDays;

  /// No description provided for @progressUnitDays.
  ///
  /// In tr, this message translates to:
  /// **'gün'**
  String get progressUnitDays;

  /// No description provided for @progressToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get progressToday;

  /// No description provided for @progressTodayPlan.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü Plan'**
  String get progressTodayPlan;

  /// No description provided for @progressNoPlanToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün Plan Yok'**
  String get progressNoPlanToday;

  /// No description provided for @progressPercentSuffix.
  ///
  /// In tr, this message translates to:
  /// **'{value}%'**
  String progressPercentSuffix(int value);

  /// No description provided for @progressTasks.
  ///
  /// In tr, this message translates to:
  /// **'Görevler'**
  String get progressTasks;

  /// No description provided for @progressDuration.
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get progressDuration;

  /// No description provided for @progressMinutesOfTotal.
  ///
  /// In tr, this message translates to:
  /// **'{completed}/{total} dk'**
  String progressMinutesOfTotal(int completed, int total);

  /// No description provided for @progressContentTitle.
  ///
  /// In tr, this message translates to:
  /// **'İçerik İlerlemesi'**
  String get progressContentTitle;

  /// No description provided for @progressCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan'**
  String get progressCompleted;

  /// No description provided for @progressInProgress.
  ///
  /// In tr, this message translates to:
  /// **'Devam Eden'**
  String get progressInProgress;

  /// No description provided for @progressQuizTitle.
  ///
  /// In tr, this message translates to:
  /// **'Quiz İlerlemesi'**
  String get progressQuizTitle;

  /// No description provided for @progressQuizSummary.
  ///
  /// In tr, this message translates to:
  /// **'Quiz Özeti'**
  String get progressQuizSummary;

  /// No description provided for @progressQuizAttempts.
  ///
  /// In tr, this message translates to:
  /// **'{count} deneme'**
  String progressQuizAttempts(int count);

  /// No description provided for @progressNoQuizAttempts.
  ///
  /// In tr, this message translates to:
  /// **'Henüz quiz denemesi yapmadın.'**
  String get progressNoQuizAttempts;

  /// No description provided for @progressBestScore.
  ///
  /// In tr, this message translates to:
  /// **'En İyi Skor'**
  String get progressBestScore;

  /// No description provided for @progressAverage.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama'**
  String get progressAverage;

  /// No description provided for @progressLatestScore.
  ///
  /// In tr, this message translates to:
  /// **'Son Skor'**
  String get progressLatestScore;

  /// No description provided for @progressSkillsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Beceriler'**
  String get progressSkillsTitle;

  /// No description provided for @progressSkillsSummary.
  ///
  /// In tr, this message translates to:
  /// **'{total} beceriden {started} tanesinde ilerleme var'**
  String progressSkillsSummary(int total, int started);

  /// No description provided for @progressStrongestSkills.
  ///
  /// In tr, this message translates to:
  /// **'En Güçlü Beceriler'**
  String get progressStrongestSkills;

  /// No description provided for @progressFocusSkills.
  ///
  /// In tr, this message translates to:
  /// **'Odak Beceriler (İlerlemesi Düşük)'**
  String get progressFocusSkills;

  /// No description provided for @quizTitle.
  ///
  /// In tr, this message translates to:
  /// **'Quiz'**
  String get quizTitle;

  /// No description provided for @quizLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Quiz yüklenirken bir hata oluştu.'**
  String get quizLoadError;

  /// No description provided for @quizSubmitError.
  ///
  /// In tr, this message translates to:
  /// **'Quiz gönderilirken bir hata oluştu.'**
  String get quizSubmitError;

  /// No description provided for @quizNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Quiz bulunamadı.'**
  String get quizNotFound;

  /// No description provided for @quizNoQuestions.
  ///
  /// In tr, this message translates to:
  /// **'Bu quiz için henüz soru bulunmuyor.'**
  String get quizNoQuestions;

  /// No description provided for @quizQuestionProgress.
  ///
  /// In tr, this message translates to:
  /// **'Soru {current} / {total}'**
  String quizQuestionProgress(int current, int total);

  /// No description provided for @quizFinish.
  ///
  /// In tr, this message translates to:
  /// **'Quiz\'i Bitir'**
  String get quizFinish;

  /// No description provided for @quizNext.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki'**
  String get quizNext;

  /// No description provided for @quizResultTitle.
  ///
  /// In tr, this message translates to:
  /// **'Quiz Sonucu'**
  String get quizResultTitle;

  /// No description provided for @quizResultCorrectOfTotal.
  ///
  /// In tr, this message translates to:
  /// **'{correct} / {total} Doğru'**
  String quizResultCorrectOfTotal(int correct, int total);

  /// No description provided for @quizResultSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Başarı'**
  String get quizResultSuccess;

  /// No description provided for @quizResultCorrect.
  ///
  /// In tr, this message translates to:
  /// **'{count} Doğru'**
  String quizResultCorrect(int count);

  /// No description provided for @quizResultWrong.
  ///
  /// In tr, this message translates to:
  /// **'{count} Yanlış'**
  String quizResultWrong(int count);

  /// No description provided for @quizRetake.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Çöz'**
  String get quizRetake;

  /// No description provided for @quizBackToDashboard.
  ///
  /// In tr, this message translates to:
  /// **'Dashboard\'a Dön'**
  String get quizBackToDashboard;

  /// No description provided for @coachTitle.
  ///
  /// In tr, this message translates to:
  /// **'AI Koç'**
  String get coachTitle;

  /// No description provided for @coachIntro.
  ///
  /// In tr, this message translates to:
  /// **'Kariyer hedefine göre kişisel bir yol arkadaşın. Aklına takılanı sor.'**
  String get coachIntro;

  /// No description provided for @coachHint.
  ///
  /// In tr, this message translates to:
  /// **'Sorunu buraya yaz...'**
  String get coachHint;

  /// No description provided for @coachSend.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get coachSend;

  /// No description provided for @coachAnswering.
  ///
  /// In tr, this message translates to:
  /// **'Yanıtlanıyor...'**
  String get coachAnswering;

  /// No description provided for @coachUnreachable.
  ///
  /// In tr, this message translates to:
  /// **'AI koçuna ulaşılamadı. Lütfen tekrar deneyin.'**
  String get coachUnreachable;

  /// No description provided for @discoverLoadError.
  ///
  /// In tr, this message translates to:
  /// **'İçerikler yüklenemedi.'**
  String get discoverLoadError;

  /// No description provided for @discoverEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Şu an sana uygun içerik bulunmuyor.'**
  String get discoverEmpty;

  /// No description provided for @discoverHeadline.
  ///
  /// In tr, this message translates to:
  /// **'Senin için seçtiklerimiz'**
  String get discoverHeadline;

  /// No description provided for @discoverSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Mesleğine ve gelişim yolculuğuna uygun içerikler.'**
  String get discoverSubtitle;

  /// No description provided for @contentDetailTitle.
  ///
  /// In tr, this message translates to:
  /// **'İçerik Detayı'**
  String get contentDetailTitle;

  /// No description provided for @contentProgressLoadError.
  ///
  /// In tr, this message translates to:
  /// **'İçerik ilerlemesi yüklenemedi.'**
  String get contentProgressLoadError;

  /// No description provided for @contentCompletedToast.
  ///
  /// In tr, this message translates to:
  /// **'İçerik tamamlandı! 🎉'**
  String get contentCompletedToast;

  /// No description provided for @contentCompleteError.
  ///
  /// In tr, this message translates to:
  /// **'İçerik tamamlanırken bir hata oluştu.'**
  String get contentCompleteError;

  /// No description provided for @contentInvalidLink.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz içerik bağlantısı.'**
  String get contentInvalidLink;

  /// No description provided for @contentCompletedBadge.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı ✓'**
  String get contentCompletedBadge;

  /// No description provided for @contentAbout.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get contentAbout;

  /// No description provided for @contentOpen.
  ///
  /// In tr, this message translates to:
  /// **'İçeriği Aç'**
  String get contentOpen;

  /// No description provided for @contentCompletedButton.
  ///
  /// In tr, this message translates to:
  /// **'İçerik Tamamlandı'**
  String get contentCompletedButton;

  /// No description provided for @contentMarkComplete.
  ///
  /// In tr, this message translates to:
  /// **'Tamamladım'**
  String get contentMarkComplete;

  /// No description provided for @newsScreenTitle.
  ///
  /// In tr, this message translates to:
  /// **'Senin Alanında Gündem'**
  String get newsScreenTitle;

  /// No description provided for @newsReadMore.
  ///
  /// In tr, this message translates to:
  /// **'Haberi İncele'**
  String get newsReadMore;

  /// No description provided for @newsInvalidLink.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz haber bağlantısı.'**
  String get newsInvalidLink;

  /// No description provided for @newsOpenError.
  ///
  /// In tr, this message translates to:
  /// **'Haber açılamadı.'**
  String get newsOpenError;

  /// Ay adı; month değeri m1..m12.
  ///
  /// In tr, this message translates to:
  /// **'{month, select, m1{Ocak} m2{Şubat} m3{Mart} m4{Nisan} m5{Mayıs} m6{Haziran} m7{Temmuz} m8{Ağustos} m9{Eylül} m10{Ekim} m11{Kasım} m12{Aralık} other{}}'**
  String monthName(String month);

  /// Haber tarihi; month, monthName ile üretilir.
  ///
  /// In tr, this message translates to:
  /// **'{day} {month} {year}'**
  String newsDate(int day, String month, String year);

  /// No description provided for @newsSectionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Alanındaki güncel gelişmeler.'**
  String get newsSectionSubtitle;

  /// No description provided for @recommendationsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Profiline ve ilerlemene göre seçildi.'**
  String get recommendationsSubtitle;

  /// No description provided for @dailyPlanSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünü tamamlamak için küçük adımlar.'**
  String get dailyPlanSubtitle;

  /// No description provided for @dashboardTasksShort.
  ///
  /// In tr, this message translates to:
  /// **'Görev'**
  String get dashboardTasksShort;

  /// No description provided for @dashboardCoachPitch.
  ///
  /// In tr, this message translates to:
  /// **'Takıldığın yeri sor, hedefine göre yanıt al.'**
  String get dashboardCoachPitch;

  /// No description provided for @dashboardLearnPitch.
  ///
  /// In tr, this message translates to:
  /// **'Alanına uygun içeriklerle öğrenmeye devam et.'**
  String get dashboardLearnPitch;

  /// No description provided for @taskTypeLearn.
  ///
  /// In tr, this message translates to:
  /// **'Öğren'**
  String get taskTypeLearn;

  /// No description provided for @taskTypePractice.
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get taskTypePractice;

  /// No description provided for @taskTypeQuiz.
  ///
  /// In tr, this message translates to:
  /// **'Test'**
  String get taskTypeQuiz;

  /// No description provided for @taskTypeReview.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar'**
  String get taskTypeReview;

  /// No description provided for @navHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get navHome;

  /// No description provided for @navDiscover.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get navDiscover;

  /// No description provided for @navSkills.
  ///
  /// In tr, this message translates to:
  /// **'Yetenekler'**
  String get navSkills;

  /// No description provided for @navProgress.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme'**
  String get navProgress;

  /// No description provided for @navProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @coachEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yol arkadaşın hazır.'**
  String get coachEmptyTitle;

  /// No description provided for @coachSuggestionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Örnek sorular'**
  String get coachSuggestionsTitle;

  /// No description provided for @coachSuggestion1.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta neye odaklanmalıyım?'**
  String get coachSuggestion1;

  /// No description provided for @coachSuggestion2.
  ///
  /// In tr, this message translates to:
  /// **'Hedefime ulaşmak için hangi becerileri geliştirmeliyim?'**
  String get coachSuggestion2;

  /// No description provided for @coachSuggestion3.
  ///
  /// In tr, this message translates to:
  /// **'Günlük 30 dakikayla nasıl ilerleyebilirim?'**
  String get coachSuggestion3;

  /// No description provided for @settingsAppearance.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Dil ve tema tercihleri cihazında saklanır.'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @appTagline.
  ///
  /// In tr, this message translates to:
  /// **'Hedefini belir. Yolunu keşfet.'**
  String get appTagline;

  /// No description provided for @settingsAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get settingsAccount;

  /// No description provided for @settingsLogout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutHint.
  ///
  /// In tr, this message translates to:
  /// **'Oturumun bu cihazda kapatılır.'**
  String get settingsLogoutHint;

  /// No description provided for @sessionExpired.
  ///
  /// In tr, this message translates to:
  /// **'Oturumun sona erdi. Lütfen tekrar giriş yap.'**
  String get sessionExpired;

  /// No description provided for @navToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get navToday;

  /// No description provided for @navPath.
  ///
  /// In tr, this message translates to:
  /// **'Yolum'**
  String get navPath;

  /// No description provided for @navCoach.
  ///
  /// In tr, this message translates to:
  /// **'Koç'**
  String get navCoach;

  /// No description provided for @todayFocusTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün ana görevi'**
  String get todayFocusTitle;

  /// No description provided for @todayStart.
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get todayStart;

  /// No description provided for @todayAllDone.
  ///
  /// In tr, this message translates to:
  /// **'Bugünü tamamladın.'**
  String get todayAllDone;

  /// No description provided for @todayAllDoneHint.
  ///
  /// In tr, this message translates to:
  /// **'Yarın yeni bir plan hazır olacak. Dilersen projenden devam et.'**
  String get todayAllDoneHint;

  /// No description provided for @todayOtherSteps.
  ///
  /// In tr, this message translates to:
  /// **'Günün diğer adımları'**
  String get todayOtherSteps;

  /// No description provided for @dashboardProjectTitle.
  ///
  /// In tr, this message translates to:
  /// **'Projem'**
  String get dashboardProjectTitle;

  /// No description provided for @dashboardProjectSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Öğrendiklerin burada gerçek bir ürüne dönüşüyor.'**
  String get dashboardProjectSubtitle;

  /// No description provided for @dashboardPathTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yolum'**
  String get dashboardPathTitle;

  /// No description provided for @dashboardPathSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedefine giden yolda neredesin?'**
  String get dashboardPathSubtitle;

  /// No description provided for @dashboardDiscoverSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Alanından seçilmiş içerik ve gelişmeler.'**
  String get dashboardDiscoverSubtitle;

  /// No description provided for @dashboardViewAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Gör'**
  String get dashboardViewAll;

  /// No description provided for @projectTitle.
  ///
  /// In tr, this message translates to:
  /// **'Projem'**
  String get projectTitle;

  /// No description provided for @projectStepsProgress.
  ///
  /// In tr, this message translates to:
  /// **'{completed}/{total} adım'**
  String projectStepsProgress(int completed, int total);

  /// No description provided for @projectNextStepLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki adım'**
  String get projectNextStepLabel;

  /// No description provided for @projectStepStatusLocked.
  ///
  /// In tr, this message translates to:
  /// **'Kilitli'**
  String get projectStepStatusLocked;

  /// No description provided for @projectStepStatusAvailable.
  ///
  /// In tr, this message translates to:
  /// **'Sıradaki'**
  String get projectStepStatusAvailable;

  /// No description provided for @projectStepStatusCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get projectStepStatusCompleted;

  /// No description provided for @projectStepCompleteAction.
  ///
  /// In tr, this message translates to:
  /// **'Adımı Tamamla'**
  String get projectStepCompleteAction;

  /// No description provided for @projectStepLockedHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu adım, önceki adımı tamamlayınca açılır.'**
  String get projectStepLockedHint;

  /// No description provided for @projectStepOpenContent.
  ///
  /// In tr, this message translates to:
  /// **'İçeriği Aç'**
  String get projectStepOpenContent;

  /// No description provided for @projectCompleteError.
  ///
  /// In tr, this message translates to:
  /// **'Adım tamamlanamadı.'**
  String get projectCompleteError;

  /// No description provided for @projectLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Projen yüklenemedi.'**
  String get projectLoadError;

  /// No description provided for @projectEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir projen yok.'**
  String get projectEmptyTitle;

  /// No description provided for @projectEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Uzmanlığın için proje hazırlanıyor. Bu arada bugünkü planından devam edebilirsin.'**
  String get projectEmptyHint;

  /// No description provided for @projectEmptyAction.
  ///
  /// In tr, this message translates to:
  /// **'Bugüne Dön'**
  String get projectEmptyAction;

  /// No description provided for @projectCompletedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Projeni tamamladın.'**
  String get projectCompletedTitle;

  /// No description provided for @projectCompletedHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu projeyi portfolyona ekleyebilir ve yeni bir hedefe geçebilirsin.'**
  String get projectCompletedHint;

  /// No description provided for @projectStepsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Proje adımları'**
  String get projectStepsTitle;

  /// No description provided for @projectRoadmapTitle.
  ///
  /// In tr, this message translates to:
  /// **'Önündeki yol'**
  String get projectRoadmapTitle;

  /// No description provided for @pathIntroTitle.
  ///
  /// In tr, this message translates to:
  /// **'İşte senin yolun.'**
  String get pathIntroTitle;

  /// No description provided for @pathIntroSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedefine göre hazırlandı. İstediğin zaman profilinden güncelleyebilirsin.'**
  String get pathIntroSubtitle;

  /// No description provided for @pathIntroGoalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedefin'**
  String get pathIntroGoalTitle;

  /// No description provided for @pathIntroOutcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu yolun sonunda'**
  String get pathIntroOutcomeTitle;

  /// No description provided for @pathIntroCta.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğa Başla'**
  String get pathIntroCta;

  /// No description provided for @pathIntroDailyTime.
  ///
  /// In tr, this message translates to:
  /// **'Günlük {minutes} dakika'**
  String pathIntroDailyTime(int minutes);

  /// No description provided for @profileScreenTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profileScreenTitle;

  /// No description provided for @profileDailyTime.
  ///
  /// In tr, this message translates to:
  /// **'Günlük süre'**
  String get profileDailyTime;

  /// No description provided for @profileProgressTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme özeti'**
  String get profileProgressTitle;

  /// No description provided for @profileEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yolunu güncelle'**
  String get profileEditTitle;

  /// No description provided for @profileEditSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uzmanlığını, seviyeni, hedefini ve günlük süreni değiştirebilirsin.'**
  String get profileEditSubtitle;

  /// No description provided for @profileEditAction.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get profileEditAction;

  /// No description provided for @profileSaveAction.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get profileSaveAction;

  /// No description provided for @profileSaved.
  ///
  /// In tr, this message translates to:
  /// **'Profilin güncellendi.'**
  String get profileSaved;

  /// No description provided for @profileSaveError.
  ///
  /// In tr, this message translates to:
  /// **'Profil güncellenemedi.'**
  String get profileSaveError;

  /// No description provided for @profileLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Profil yüklenemedi.'**
  String get profileLoadError;

  /// No description provided for @profileSettingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar ve hesap'**
  String get profileSettingsTitle;

  /// No description provided for @profileSettingsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Dil, tema ve oturum.'**
  String get profileSettingsSubtitle;

  /// No description provided for @profileOpenSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları Aç'**
  String get profileOpenSettings;

  /// No description provided for @quizAnswerCorrectTitle.
  ///
  /// In tr, this message translates to:
  /// **'Doğru cevap'**
  String get quizAnswerCorrectTitle;

  /// No description provided for @quizAnswerWrongTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu cevap doğru değil'**
  String get quizAnswerWrongTitle;

  /// No description provided for @quizCorrectAnswerIs.
  ///
  /// In tr, this message translates to:
  /// **'Doğru cevap: {option}'**
  String quizCorrectAnswerIs(String option);

  /// No description provided for @quizReviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yanlış yaptığın sorular'**
  String get quizReviewTitle;

  /// No description provided for @quizReviewAllCorrect.
  ///
  /// In tr, this message translates to:
  /// **'Tüm soruları doğru bildin.'**
  String get quizReviewAllCorrect;

  /// No description provided for @onboardingComingSoon.
  ///
  /// In tr, this message translates to:
  /// **'Yakında'**
  String get onboardingComingSoon;

  /// No description provided for @onboardingComingSoonHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu meslek için içerikler hazırlanıyor.'**
  String get onboardingComingSoonHint;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
