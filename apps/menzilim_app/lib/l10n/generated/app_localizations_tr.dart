// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'MENZİLİM';

  @override
  String get commonRetry => 'Tekrar Dene';

  @override
  String get commonSessionMissing =>
      'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yap.';

  @override
  String commonMinutes(int minutes) {
    return '$minutes dakika';
  }

  @override
  String commonMinutesShort(int minutes) {
    return '$minutes dk';
  }

  @override
  String commonPercent(int value) {
    return '%$value';
  }

  @override
  String commonTaskCompleted(String title) {
    return '$title tamamlandı! 🎉';
  }

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsLanguageTurkish => 'Türkçe';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsThemeSystemHint =>
      'Sistem seçeneği cihazının görünüm ayarını izler.';

  @override
  String get loginTitle => 'Tekrar hoş geldin.';

  @override
  String get loginSubtitle => 'Gelişim yolculuğuna kaldığın yerden devam et.';

  @override
  String get loginFillFields => 'E-posta ve şifre alanlarını doldur.';

  @override
  String get loginSuccess => 'Giriş başarılı.';

  @override
  String get loginFailed =>
      'Giriş yapılamadı. E-posta veya şifreyi kontrol et.';

  @override
  String get loginButton => 'Giriş Yap';

  @override
  String get loginNoAccount => 'Hesabın yok mu? ';

  @override
  String get emailLabel => 'E-posta';

  @override
  String get emailHint => 'ornek@mail.com';

  @override
  String get passwordLabel => 'Şifre';

  @override
  String get registerButton => 'Kayıt Ol';

  @override
  String get registerTitle => 'Yolculuğunu başlat.';

  @override
  String get registerSubtitle =>
      'Hesabını oluştur ve kişisel gelişim yolculuğuna başla.';

  @override
  String get registerFillAll => 'Lütfen tüm alanları doldur.';

  @override
  String get registerInvalidEmail => 'Geçerli bir e-posta adresi gir.';

  @override
  String get registerPasswordTooShort => 'Şifre en az 6 karakter olmalı.';

  @override
  String get registerPasswordsMismatch => 'Şifreler eşleşmiyor.';

  @override
  String get registerSuccess => 'Hesabın başarıyla oluşturuldu.';

  @override
  String get registerUnexpectedError =>
      'Kayıt sırasında beklenmeyen bir hata oluştu.';

  @override
  String get registerConfirmPasswordLabel => 'Şifre Tekrar';

  @override
  String get registerCreateAccount => 'Hesap Oluştur';

  @override
  String get registerHaveAccount => 'Zaten hesabın var mı? Giriş yap';

  @override
  String get commonErrorGeneric => 'Bir hata oluştu.';

  @override
  String get commonBack => 'Geri';

  @override
  String get commonContinue => 'Devam Et';

  @override
  String get onboardingProfessionsLoadError =>
      'Meslekler yüklenirken bir hata oluştu.';

  @override
  String get onboardingSpecializationsLoadError =>
      'Uzmanlıklar yüklenirken bir hata oluştu.';

  @override
  String get onboardingSelectProfession => 'Lütfen bir meslek seç.';

  @override
  String get onboardingSelectSpecialization => 'Lütfen bir uzmanlık alanı seç.';

  @override
  String get onboardingSelectExperience => 'Lütfen deneyim seviyeni seç.';

  @override
  String get onboardingEnterCareerGoal => 'Lütfen kariyer hedefini yaz.';

  @override
  String get onboardingSelectDailyTime => 'Lütfen günlük öğrenme süresini seç.';

  @override
  String get onboardingSaved =>
      'Profilin başarıyla oluşturuldu. MENZİLİM yolculuğun başlıyor!';

  @override
  String get onboardingSaveFailed =>
      'Profilin kaydedilemedi. Lütfen tekrar dene.';

  @override
  String onboardingStep(int current, int total) {
    return '$current / $total';
  }

  @override
  String get onboardingProfessionTitle => 'Kariyer yolculuğuna başlayalım.';

  @override
  String get onboardingProfessionSubtitle =>
      'Hangi alanda kendini geliştirmek istiyorsun?';

  @override
  String get onboardingSpecializationTitle => 'Uzmanlık alanını seç.';

  @override
  String onboardingSpecializationSubtitle(String profession) {
    return '$profession alanında hangi yönde ilerlemek istiyorsun?';
  }

  @override
  String get onboardingExperienceTitle => 'Kendini hangi seviyede görüyorsun?';

  @override
  String get onboardingExperienceSubtitle =>
      'Böylece öğrenme planını mevcut seviyene göre oluşturabiliriz.';

  @override
  String get experienceBeginner => 'Başlangıç';

  @override
  String get experienceBeginnerDescription => 'Temel seviyeden başlıyorum.';

  @override
  String get experienceIntermediate => 'Orta';

  @override
  String get experienceIntermediateDescription =>
      'Temelleri biliyorum, kendimi geliştiriyorum.';

  @override
  String get experienceAdvanced => 'İleri';

  @override
  String get experienceAdvancedDescription =>
      'Deneyimliyim ve uzmanlaşmak istiyorum.';

  @override
  String get onboardingCareerGoalTitle => 'Kariyer hedefin nedir?';

  @override
  String get onboardingCareerGoalSubtitle =>
      'MENZİLİM sana uygun bir yol oluşturabilsin.';

  @override
  String get onboardingCareerGoalHint =>
      'Örn: Backend alanında profesyonelleşmek ve işe girmek istiyorum.';

  @override
  String get onboardingDailyTimeTitle => 'Günde ne kadar zaman ayırabilirsin?';

  @override
  String get onboardingDailyTimeSubtitle =>
      'Gerçekçi bir süre seç. Önemli olan sürdürülebilirlik.';

  @override
  String get dailyTime30 => '30 dakika';

  @override
  String get dailyTime30Description => 'Yoğun günler için';

  @override
  String get dailyTime60 => '1 saat';

  @override
  String get dailyTime60Description => 'Düzenli gelişim için';

  @override
  String get dailyTime90 => '1,5 saat';

  @override
  String get dailyTime90Description => 'Daha hızlı ilerlemek için';

  @override
  String get dailyTime120 => '2 saat';

  @override
  String get dailyTime120Description => 'Yoğun öğrenme için';

  @override
  String get onboardingSaving => 'Kaydediliyor...';

  @override
  String get onboardingFinish => 'MENZİLİM Yolculuğuna Başla';

  @override
  String get dashboardLoadError => 'Dashboard bilgileri yüklenemedi.';

  @override
  String get dashboardRecommendationsLoadError => 'Öneriler yüklenemedi.';

  @override
  String get dashboardSkillsLoadError => 'Beceriler yüklenemedi.';

  @override
  String get dashboardTaskCompleteError =>
      'Görev tamamlanırken bir hata oluştu.';

  @override
  String get contentOpenError => 'İçerik açılamadı.';

  @override
  String get dashboardGreeting => 'Merhaba 👋';

  @override
  String get dashboardHeadline => 'Gelişim yolculuğuna devam et.';

  @override
  String get dashboardSubheadline => 'Bugün kendin için bir adım daha at.';

  @override
  String get dashboardTodayGoal => 'Bugünkü Hedef';

  @override
  String dashboardDailyGoal(int minutes) {
    return 'Günlük öğrenme hedefin: $minutes dakika';
  }

  @override
  String dashboardMinutesCompleted(int minutes) {
    return '$minutes dakika tamamlandı';
  }

  @override
  String get dashboardProfileTitle => 'Profilin';

  @override
  String get profileProfession => 'Meslek';

  @override
  String get profileSpecialization => 'Uzmanlık';

  @override
  String get profileLevel => 'Seviye';

  @override
  String get profileCareerGoal => 'Kariyer hedefi';

  @override
  String get dashboardProgressTitle => 'İlerleme';

  @override
  String get dashboardDailyPlan => 'Günlük Plan';

  @override
  String dashboardTasksCompleted(int completed, int total) {
    return '$completed / $total görev tamamlandı';
  }

  @override
  String dashboardMinutesOfTotal(int completed, int total) {
    return '$completed / $total dakika';
  }

  @override
  String get dashboardContent => 'İçerik';

  @override
  String dashboardContentCompleted(int count) {
    return '$count tamamlandı';
  }

  @override
  String dashboardContentInProgress(int count) {
    return '$count devam ediyor';
  }

  @override
  String get dailyPlanTitle => 'Bugünün Yol Haritası';

  @override
  String get dailyPlanEmpty => 'Bugün için henüz görev bulunmuyor.';

  @override
  String get dailyPlanTaskFallbackDescription =>
      'Bugünkü gelişim planındaki görev.';

  @override
  String get recommendationsTitle => 'Sana Özel İçerikler';

  @override
  String get recommendationsEmpty => 'Şu an sana özel yeni içerik yok.';

  @override
  String get dashboardContinueLearning => 'Öğrenmeye Devam Et';

  @override
  String get dashboardAskCoach => 'AI Koç\'a Sor';

  @override
  String get dashboardViewProgress => 'İlerlememi Gör';

  @override
  String get taskGoToContent => 'İçeriğe Git';

  @override
  String get recommendationInProgress => 'Devam ediyor';

  @override
  String get recommendationNew => 'Yeni';

  @override
  String get recommendationStart => 'Başla';

  @override
  String get skillsTitle => 'Yeteneklerim';

  @override
  String get discoverTitle => 'Keşfet';

  @override
  String get newsSectionTitle => 'Bugün Senin Alanında';

  @override
  String get newsViewAll => 'Tüm Haberler';

  @override
  String get newsLoadError => 'Haberler yüklenemedi.';

  @override
  String get newsEmpty => 'Şu an alanında gösterilecek haber yok.';

  @override
  String get skillsSummaryTitle => 'Becerilerim';

  @override
  String skillsSummaryCounts(int total, int started) {
    return '$total yetenek · $started tanesinde ilerleme';
  }

  @override
  String get skillsSummaryEmpty => 'Henüz bir yetenekte ilerleme kaydetmedin.';

  @override
  String get skillsViewAll => 'Tüm Yetenekleri Gör';

  @override
  String get skillsLoadError => 'Yetenekler yüklenemedi.';

  @override
  String get skillsEmpty => 'Uzmanlık alanın için henüz yetenek bulunmuyor.';

  @override
  String get skillsMapTitle => 'Yetenek haritan';

  @override
  String skillsMapSubtitle(int total, int started) {
    return '$total yetenekten $started tanesinde ilerleme kaydettin.';
  }

  @override
  String skillsStatContent(int completed, int total) {
    return 'İçerik: $completed / $total';
  }

  @override
  String skillsStatQuiz(int attempted, int total) {
    return 'Quiz: $attempted / $total';
  }

  @override
  String skillsStatInProgress(int count) {
    return 'Devam eden: $count';
  }

  @override
  String skillsStatBestScore(int score) {
    return 'En iyi skor: %$score';
  }

  @override
  String skillsStatLatestScore(int score) {
    return 'Son skor: %$score';
  }

  @override
  String get skillsNoMaterial =>
      'Bu yetenek için henüz içerik veya quiz eklenmedi.';

  @override
  String get progressTitle => 'Genel İlerleme';

  @override
  String get progressLoadError => 'İlerleme yüklenemedi.';

  @override
  String get progressNoData => 'İlerleme verisi bulunamadı.';

  @override
  String get progressOverview => 'Genel Bakış';

  @override
  String get progressCompletedTasks => 'Tamamlanan Görev';

  @override
  String get progressUnitTotal => 'toplam';

  @override
  String get progressLearningTime => 'Öğrenme Süresi';

  @override
  String get progressUnitMinutes => 'dakika';

  @override
  String get progressCompletedPlans => 'Tamamlanan Plan';

  @override
  String get progressUnitPlans => 'plan';

  @override
  String get progressActiveDays => 'Aktif Gün';

  @override
  String get progressUnitDays => 'gün';

  @override
  String get progressToday => 'Bugün';

  @override
  String get progressTodayPlan => 'Bugünkü Plan';

  @override
  String get progressNoPlanToday => 'Bugün Plan Yok';

  @override
  String progressPercentSuffix(int value) {
    return '$value%';
  }

  @override
  String get progressTasks => 'Görevler';

  @override
  String get progressDuration => 'Süre';

  @override
  String progressMinutesOfTotal(int completed, int total) {
    return '$completed/$total dk';
  }

  @override
  String get progressContentTitle => 'İçerik İlerlemesi';

  @override
  String get progressCompleted => 'Tamamlanan';

  @override
  String get progressInProgress => 'Devam Eden';

  @override
  String get progressQuizTitle => 'Quiz İlerlemesi';

  @override
  String get progressQuizSummary => 'Quiz Özeti';

  @override
  String progressQuizAttempts(int count) {
    return '$count deneme';
  }

  @override
  String get progressNoQuizAttempts => 'Henüz quiz denemesi yapmadın.';

  @override
  String get progressBestScore => 'En İyi Skor';

  @override
  String get progressAverage => 'Ortalama';

  @override
  String get progressLatestScore => 'Son Skor';

  @override
  String get progressSkillsTitle => 'Beceriler';

  @override
  String progressSkillsSummary(int total, int started) {
    return '$total beceriden $started tanesinde ilerleme var';
  }

  @override
  String get progressStrongestSkills => 'En Güçlü Beceriler';

  @override
  String get progressFocusSkills => 'Odak Beceriler (İlerlemesi Düşük)';

  @override
  String get quizTitle => 'Quiz';

  @override
  String get quizLoadError => 'Quiz yüklenirken bir hata oluştu.';

  @override
  String get quizSubmitError => 'Quiz gönderilirken bir hata oluştu.';

  @override
  String get quizNotFound => 'Quiz bulunamadı.';

  @override
  String get quizNoQuestions => 'Bu quiz için henüz soru bulunmuyor.';

  @override
  String quizQuestionProgress(int current, int total) {
    return 'Soru $current / $total';
  }

  @override
  String get quizFinish => 'Quiz\'i Bitir';

  @override
  String get quizNext => 'Sonraki';

  @override
  String get quizResultTitle => 'Quiz Sonucu';

  @override
  String quizResultCorrectOfTotal(int correct, int total) {
    return '$correct / $total Doğru';
  }

  @override
  String get quizResultSuccess => 'Başarı';

  @override
  String quizResultCorrect(int count) {
    return '$count Doğru';
  }

  @override
  String quizResultWrong(int count) {
    return '$count Yanlış';
  }

  @override
  String get quizRetake => 'Tekrar Çöz';

  @override
  String get quizBackToDashboard => 'Dashboard\'a Dön';

  @override
  String get coachTitle => 'AI Koç';

  @override
  String get coachIntro =>
      'Kariyer hedefine göre kişisel bir yol arkadaşın. Aklına takılanı sor.';

  @override
  String get coachHint => 'Sorunu buraya yaz...';

  @override
  String get coachSend => 'Gönder';

  @override
  String get coachAnswering => 'Yanıtlanıyor...';

  @override
  String get coachUnreachable =>
      'AI koçuna ulaşılamadı. Lütfen tekrar deneyin.';

  @override
  String get discoverLoadError => 'İçerikler yüklenemedi.';

  @override
  String get discoverEmpty => 'Şu an sana uygun içerik bulunmuyor.';

  @override
  String get discoverHeadline => 'Senin için seçtiklerimiz';

  @override
  String get discoverSubtitle =>
      'Mesleğine ve gelişim yolculuğuna uygun içerikler.';

  @override
  String get contentDetailTitle => 'İçerik Detayı';

  @override
  String get contentProgressLoadError => 'İçerik ilerlemesi yüklenemedi.';

  @override
  String get contentCompletedToast => 'İçerik tamamlandı! 🎉';

  @override
  String get contentCompleteError => 'İçerik tamamlanırken bir hata oluştu.';

  @override
  String get contentInvalidLink => 'Geçersiz içerik bağlantısı.';

  @override
  String get contentCompletedBadge => 'Tamamlandı ✓';

  @override
  String get contentAbout => 'Hakkında';

  @override
  String get contentOpen => 'İçeriği Aç';

  @override
  String get contentCompletedButton => 'İçerik Tamamlandı';

  @override
  String get contentMarkComplete => 'Tamamladım';

  @override
  String get newsScreenTitle => 'Senin Alanında Gündem';

  @override
  String get newsReadMore => 'Haberi İncele';

  @override
  String get newsInvalidLink => 'Geçersiz haber bağlantısı.';

  @override
  String get newsOpenError => 'Haber açılamadı.';

  @override
  String monthName(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'Ocak',
      'm2': 'Şubat',
      'm3': 'Mart',
      'm4': 'Nisan',
      'm5': 'Mayıs',
      'm6': 'Haziran',
      'm7': 'Temmuz',
      'm8': 'Ağustos',
      'm9': 'Eylül',
      'm10': 'Ekim',
      'm11': 'Kasım',
      'm12': 'Aralık',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String newsDate(int day, String month, String year) {
    return '$day $month $year';
  }
}
