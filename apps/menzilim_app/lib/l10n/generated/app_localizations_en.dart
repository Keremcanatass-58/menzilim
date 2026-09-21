// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MENZİLİM';

  @override
  String get commonRetry => 'Try Again';

  @override
  String get commonSessionMissing => 'Session not found. Please sign in again.';

  @override
  String commonMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return '$minutes $_temp0';
  }

  @override
  String commonMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String commonPercent(int value) {
    return '$value%';
  }

  @override
  String commonTaskCompleted(String title) {
    return '$title completed! 🎉';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageTurkish => 'Türkçe';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystemHint =>
      'System follows your device appearance.';

  @override
  String get loginTitle => 'Welcome back.';

  @override
  String get loginSubtitle =>
      'Continue your growth journey where you left off.';

  @override
  String get loginFillFields => 'Please fill in your email and password.';

  @override
  String get loginSuccess => 'Signed in successfully.';

  @override
  String get loginFailed => 'Could not sign in. Check your email or password.';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginNoAccount => 'Don\'t have an account? ';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get registerButton => 'Sign Up';

  @override
  String get registerTitle => 'Start your journey.';

  @override
  String get registerSubtitle =>
      'Create your account and start your personal growth journey.';

  @override
  String get registerFillAll => 'Please fill in all fields.';

  @override
  String get registerInvalidEmail => 'Enter a valid email address.';

  @override
  String get registerPasswordTooShort =>
      'Password must be at least 6 characters.';

  @override
  String get registerPasswordsMismatch => 'Passwords do not match.';

  @override
  String get registerSuccess => 'Your account has been created.';

  @override
  String get registerUnexpectedError =>
      'An unexpected error occurred during sign-up.';

  @override
  String get registerConfirmPasswordLabel => 'Confirm Password';

  @override
  String get registerCreateAccount => 'Create Account';

  @override
  String get registerHaveAccount => 'Already have an account? Sign in';

  @override
  String get commonErrorGeneric => 'Something went wrong.';

  @override
  String get commonBack => 'Back';

  @override
  String get commonContinue => 'Continue';

  @override
  String get onboardingProfessionsLoadError => 'Could not load professions.';

  @override
  String get onboardingSpecializationsLoadError =>
      'Could not load specializations.';

  @override
  String get onboardingSelectProfession => 'Please choose a profession.';

  @override
  String get onboardingSelectSpecialization =>
      'Please choose a specialization.';

  @override
  String get onboardingSelectExperience =>
      'Please choose your experience level.';

  @override
  String get onboardingEnterCareerGoal => 'Please enter your career goal.';

  @override
  String get onboardingSelectDailyTime =>
      'Please choose your daily learning time.';

  @override
  String get onboardingSaved =>
      'Your profile is ready. Your MENZİLİM journey begins!';

  @override
  String get onboardingSaveFailed =>
      'Your profile could not be saved. Please try again.';

  @override
  String onboardingStep(int current, int total) {
    return '$current / $total';
  }

  @override
  String get onboardingProfessionTitle => 'Let\'s start your career journey.';

  @override
  String get onboardingProfessionSubtitle =>
      'Which field do you want to grow in?';

  @override
  String get onboardingSpecializationTitle => 'Choose your specialization.';

  @override
  String onboardingSpecializationSubtitle(String profession) {
    return 'Which direction do you want to take in $profession?';
  }

  @override
  String get onboardingExperienceTitle => 'What level do you see yourself at?';

  @override
  String get onboardingExperienceSubtitle =>
      'This lets us build your learning plan around your current level.';

  @override
  String get experienceBeginner => 'Beginner';

  @override
  String get experienceBeginnerDescription => 'I\'m starting from the basics.';

  @override
  String get experienceIntermediate => 'Intermediate';

  @override
  String get experienceIntermediateDescription =>
      'I know the basics and I\'m improving.';

  @override
  String get experienceAdvanced => 'Advanced';

  @override
  String get experienceAdvancedDescription =>
      'I\'m experienced and want to specialize.';

  @override
  String get onboardingCareerGoalTitle => 'What is your career goal?';

  @override
  String get onboardingCareerGoalSubtitle =>
      'So MENZİLİM can build a path that fits you.';

  @override
  String get onboardingCareerGoalHint =>
      'E.g. I want to become a professional backend developer and get hired.';

  @override
  String get onboardingDailyTimeTitle =>
      'How much time can you spend each day?';

  @override
  String get onboardingDailyTimeSubtitle =>
      'Pick a realistic time. Consistency is what matters.';

  @override
  String get dailyTime30 => '30 minutes';

  @override
  String get dailyTime30Description => 'For busy days';

  @override
  String get dailyTime60 => '1 hour';

  @override
  String get dailyTime60Description => 'For steady progress';

  @override
  String get dailyTime90 => '1.5 hours';

  @override
  String get dailyTime90Description => 'To progress faster';

  @override
  String get dailyTime120 => '2 hours';

  @override
  String get dailyTime120Description => 'For intensive learning';

  @override
  String get onboardingSaving => 'Saving...';

  @override
  String get onboardingFinish => 'Start Your MENZİLİM Journey';

  @override
  String get dashboardLoadError => 'Could not load your dashboard.';

  @override
  String get dashboardRecommendationsLoadError =>
      'Could not load recommendations.';

  @override
  String get dashboardSkillsLoadError => 'Could not load skills.';

  @override
  String get dashboardTaskCompleteError =>
      'Something went wrong while completing the task.';

  @override
  String get contentOpenError => 'Could not open the content.';

  @override
  String get dashboardGreeting => 'Hello 👋';

  @override
  String get dashboardHeadline => 'Keep up your growth journey.';

  @override
  String get dashboardSubheadline => 'Take one more step for yourself today.';

  @override
  String get dashboardTodayGoal => 'Today\'s Goal';

  @override
  String dashboardDailyGoal(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return 'Your daily learning goal: $minutes $_temp0';
  }

  @override
  String dashboardMinutesCompleted(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return '$minutes $_temp0 completed';
  }

  @override
  String get dashboardProfileTitle => 'Your Profile';

  @override
  String get profileProfession => 'Profession';

  @override
  String get profileSpecialization => 'Specialization';

  @override
  String get profileLevel => 'Level';

  @override
  String get profileCareerGoal => 'Career goal';

  @override
  String get dashboardProgressTitle => 'Progress';

  @override
  String get dashboardDailyPlan => 'Daily Plan';

  @override
  String dashboardTasksCompleted(int completed, int total) {
    return '$completed / $total tasks completed';
  }

  @override
  String dashboardMinutesOfTotal(int completed, int total) {
    return '$completed / $total minutes';
  }

  @override
  String get dashboardContent => 'Content';

  @override
  String dashboardContentCompleted(int count) {
    return '$count completed';
  }

  @override
  String dashboardContentInProgress(int count) {
    return '$count in progress';
  }

  @override
  String get dailyPlanTitle => 'Today\'s Roadmap';

  @override
  String get dailyPlanEmpty => 'No tasks for today yet.';

  @override
  String get dailyPlanTaskFallbackDescription =>
      'A task from today\'s growth plan.';

  @override
  String get recommendationsTitle => 'Recommended for You';

  @override
  String get recommendationsEmpty =>
      'No new recommendations for you right now.';

  @override
  String get dashboardContinueLearning => 'Continue Learning';

  @override
  String get dashboardAskCoach => 'Ask the AI Coach';

  @override
  String get dashboardViewProgress => 'View My Progress';

  @override
  String get taskGoToContent => 'Go to Content';

  @override
  String get recommendationInProgress => 'In progress';

  @override
  String get recommendationNew => 'New';

  @override
  String get recommendationStart => 'Start';

  @override
  String get skillsTitle => 'My Skills';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get newsSectionTitle => 'In Your Field Today';

  @override
  String get newsViewAll => 'All News';

  @override
  String get newsLoadError => 'Could not load news.';

  @override
  String get newsEmpty => 'No news for your field right now.';

  @override
  String get skillsSummaryTitle => 'My Skills';

  @override
  String skillsSummaryCounts(int total, int started) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'skills',
      one: 'skill',
    );
    return '$total $_temp0 · progress in $started';
  }

  @override
  String get skillsSummaryEmpty =>
      'You haven\'t made progress in any skill yet.';

  @override
  String get skillsViewAll => 'View All Skills';

  @override
  String get skillsLoadError => 'Could not load skills.';

  @override
  String get skillsEmpty => 'There are no skills for your specialization yet.';

  @override
  String get skillsMapTitle => 'Your skill map';

  @override
  String skillsMapSubtitle(int total, int started) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'skills',
      one: 'skill',
    );
    return 'You\'ve made progress in $started of $total $_temp0.';
  }

  @override
  String skillsStatContent(int completed, int total) {
    return 'Content: $completed / $total';
  }

  @override
  String skillsStatQuiz(int attempted, int total) {
    return 'Quiz: $attempted / $total';
  }

  @override
  String skillsStatInProgress(int count) {
    return 'In progress: $count';
  }

  @override
  String skillsStatBestScore(int score) {
    return 'Best score: $score%';
  }

  @override
  String skillsStatLatestScore(int score) {
    return 'Latest score: $score%';
  }

  @override
  String get skillsNoMaterial =>
      'No content or quiz has been added for this skill yet.';

  @override
  String get progressTitle => 'Overall Progress';

  @override
  String get progressLoadError => 'Could not load progress.';

  @override
  String get progressNoData => 'No progress data found.';

  @override
  String get progressOverview => 'Overview';

  @override
  String get progressCompletedTasks => 'Completed Tasks';

  @override
  String get progressUnitTotal => 'total';

  @override
  String get progressLearningTime => 'Learning Time';

  @override
  String get progressUnitMinutes => 'minutes';

  @override
  String get progressCompletedPlans => 'Completed Plans';

  @override
  String get progressUnitPlans => 'plans';

  @override
  String get progressActiveDays => 'Active Days';

  @override
  String get progressUnitDays => 'days';

  @override
  String get progressToday => 'Today';

  @override
  String get progressTodayPlan => 'Today\'s Plan';

  @override
  String get progressNoPlanToday => 'No Plan Today';

  @override
  String progressPercentSuffix(int value) {
    return '$value%';
  }

  @override
  String get progressTasks => 'Tasks';

  @override
  String get progressDuration => 'Time';

  @override
  String progressMinutesOfTotal(int completed, int total) {
    return '$completed/$total min';
  }

  @override
  String get progressContentTitle => 'Content Progress';

  @override
  String get progressCompleted => 'Completed';

  @override
  String get progressInProgress => 'In Progress';

  @override
  String get progressQuizTitle => 'Quiz Progress';

  @override
  String get progressQuizSummary => 'Quiz Summary';

  @override
  String progressQuizAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'attempts',
      one: 'attempt',
    );
    return '$count $_temp0';
  }

  @override
  String get progressNoQuizAttempts => 'You haven\'t taken a quiz yet.';

  @override
  String get progressBestScore => 'Best Score';

  @override
  String get progressAverage => 'Average';

  @override
  String get progressLatestScore => 'Latest Score';

  @override
  String get progressSkillsTitle => 'Skills';

  @override
  String progressSkillsSummary(int total, int started) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'skills',
      one: 'skill',
    );
    return 'Progress in $started of $total $_temp0';
  }

  @override
  String get progressStrongestSkills => 'Strongest Skills';

  @override
  String get progressFocusSkills => 'Focus Skills (Low Progress)';

  @override
  String get quizTitle => 'Quiz';

  @override
  String get quizLoadError => 'Could not load the quiz.';

  @override
  String get quizSubmitError => 'Could not submit the quiz.';

  @override
  String get quizNotFound => 'Quiz not found.';

  @override
  String get quizNoQuestions => 'This quiz has no questions yet.';

  @override
  String quizQuestionProgress(int current, int total) {
    return 'Question $current / $total';
  }

  @override
  String get quizFinish => 'Finish Quiz';

  @override
  String get quizNext => 'Next';

  @override
  String get quizResultTitle => 'Quiz Result';

  @override
  String quizResultCorrectOfTotal(int correct, int total) {
    return '$correct / $total Correct';
  }

  @override
  String get quizResultSuccess => 'Score';

  @override
  String quizResultCorrect(int count) {
    return '$count Correct';
  }

  @override
  String quizResultWrong(int count) {
    return '$count Wrong';
  }

  @override
  String get quizRetake => 'Retake';

  @override
  String get quizBackToDashboard => 'Back to Dashboard';

  @override
  String get coachTitle => 'AI Coach';

  @override
  String get coachIntro =>
      'A personal companion tuned to your career goal. Ask whatever is on your mind.';

  @override
  String get coachHint => 'Type your question here...';

  @override
  String get coachSend => 'Send';

  @override
  String get coachAnswering => 'Answering...';

  @override
  String get coachUnreachable =>
      'Could not reach the AI coach. Please try again.';

  @override
  String get discoverLoadError => 'Could not load content.';

  @override
  String get discoverEmpty => 'There is no suitable content for you right now.';

  @override
  String get discoverHeadline => 'Picked for you';

  @override
  String get discoverSubtitle =>
      'Content that fits your profession and growth journey.';

  @override
  String get contentDetailTitle => 'Content Details';

  @override
  String get contentProgressLoadError => 'Could not load content progress.';

  @override
  String get contentCompletedToast => 'Content completed! 🎉';

  @override
  String get contentCompleteError =>
      'Something went wrong while completing the content.';

  @override
  String get contentInvalidLink => 'Invalid content link.';

  @override
  String get contentCompletedBadge => 'Completed ✓';

  @override
  String get contentAbout => 'About';

  @override
  String get contentOpen => 'Open Content';

  @override
  String get contentCompletedButton => 'Content Completed';

  @override
  String get contentMarkComplete => 'Mark as Complete';

  @override
  String get newsScreenTitle => 'News in Your Field';

  @override
  String get newsReadMore => 'Read Article';

  @override
  String get newsInvalidLink => 'Invalid news link.';

  @override
  String get newsOpenError => 'Could not open the article.';

  @override
  String monthName(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'January',
      'm2': 'February',
      'm3': 'March',
      'm4': 'April',
      'm5': 'May',
      'm6': 'June',
      'm7': 'July',
      'm8': 'August',
      'm9': 'September',
      'm10': 'October',
      'm11': 'November',
      'm12': 'December',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String newsDate(int day, String month, String year) {
    return '$month $day, $year';
  }

  @override
  String get newsSectionSubtitle => 'The latest in your field.';

  @override
  String get recommendationsSubtitle =>
      'Chosen from your profile and progress.';

  @override
  String get dailyPlanSubtitle => 'Small steps to finish today.';

  @override
  String get dashboardTasksShort => 'Tasks';

  @override
  String get dashboardCoachPitch =>
      'Ask where you are stuck and get an answer tuned to your goal.';

  @override
  String get dashboardLearnPitch =>
      'Keep learning with content picked for your field.';

  @override
  String get taskTypeLearn => 'Learn';

  @override
  String get taskTypePractice => 'Practice';

  @override
  String get taskTypeQuiz => 'Quiz';

  @override
  String get taskTypeReview => 'Review';

  @override
  String get navHome => 'Home';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navSkills => 'Skills';

  @override
  String get navProgress => 'Progress';

  @override
  String get navProfile => 'Profile';

  @override
  String get coachEmptyTitle => 'Your companion is ready.';

  @override
  String get coachSuggestionsTitle => 'Example questions';

  @override
  String get coachSuggestion1 => 'What should I focus on this week?';

  @override
  String get coachSuggestion2 =>
      'Which skills should I build to reach my goal?';

  @override
  String get coachSuggestion3 => 'How can I progress with 30 minutes a day?';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceSubtitle =>
      'Language and theme preferences are stored on your device.';

  @override
  String get appTagline => 'Set your goal. Discover your path.';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLogoutHint =>
      'Your session on this device will be closed.';

  @override
  String get sessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get navToday => 'Today';

  @override
  String get navPath => 'My Path';

  @override
  String get navCoach => 'Coach';

  @override
  String get todayFocusTitle => 'Today\'s main task';

  @override
  String get todayStart => 'Start';

  @override
  String get todayAllDone => 'You finished today.';

  @override
  String get todayAllDoneHint =>
      'A new plan will be ready tomorrow. You can keep going with your project.';

  @override
  String get todayOtherSteps => 'Other steps today';

  @override
  String get dashboardProjectTitle => 'My Project';

  @override
  String get dashboardProjectSubtitle =>
      'This is where what you learn turns into a real product.';

  @override
  String get dashboardPathTitle => 'My Path';

  @override
  String get dashboardPathSubtitle => 'Where are you on the way to your goal?';

  @override
  String get dashboardDiscoverSubtitle =>
      'Content and updates picked from your field.';

  @override
  String get dashboardViewAll => 'View All';

  @override
  String get projectTitle => 'My Project';

  @override
  String projectStepsProgress(int completed, int total) {
    return '$completed/$total steps';
  }

  @override
  String get projectNextStepLabel => 'Next step';

  @override
  String get projectStepStatusLocked => 'Locked';

  @override
  String get projectStepStatusAvailable => 'Next';

  @override
  String get projectStepStatusCompleted => 'Completed';

  @override
  String get projectStepCompleteAction => 'Complete Step';

  @override
  String get projectStepLockedHint =>
      'This step unlocks once you complete the previous one.';

  @override
  String get projectStepOpenContent => 'Open Content';

  @override
  String get projectCompleteError => 'The step could not be completed.';

  @override
  String get projectLoadError => 'Your project could not be loaded.';

  @override
  String get projectEmptyTitle => 'You don\'t have a project yet.';

  @override
  String get projectEmptyHint =>
      'A project for your specialization is on the way. Meanwhile you can continue with today\'s plan.';

  @override
  String get projectEmptyAction => 'Go to Today';

  @override
  String get projectCompletedTitle => 'You completed your project.';

  @override
  String get projectCompletedHint =>
      'You can add this project to your portfolio and move on to a new goal.';

  @override
  String get projectStepsTitle => 'Project steps';

  @override
  String get projectRoadmapTitle => 'The path ahead';

  @override
  String get pathIntroTitle => 'Here is your path.';

  @override
  String get pathIntroSubtitle =>
      'Built from your goal. You can update it any time from your profile.';

  @override
  String get pathIntroGoalTitle => 'Your goal';

  @override
  String get pathIntroOutcomeTitle => 'At the end of this path';

  @override
  String get pathIntroCta => 'Start the Journey';

  @override
  String pathIntroDailyTime(int minutes) {
    return '$minutes minutes a day';
  }

  @override
  String get profileScreenTitle => 'Profile';

  @override
  String get profileDailyTime => 'Daily time';

  @override
  String get profileProgressTitle => 'Progress summary';

  @override
  String get profileEditTitle => 'Update your path';

  @override
  String get profileEditSubtitle =>
      'You can change your specialization, level, goal and daily time.';

  @override
  String get profileEditAction => 'Edit';

  @override
  String get profileSaveAction => 'Save';

  @override
  String get profileSaved => 'Your profile has been updated.';

  @override
  String get profileSaveError => 'Your profile could not be updated.';

  @override
  String get profileLoadError => 'Your profile could not be loaded.';

  @override
  String get profileSettingsTitle => 'Settings and account';

  @override
  String get profileSettingsSubtitle => 'Language, theme and session.';

  @override
  String get profileOpenSettings => 'Open Settings';

  @override
  String get quizAnswerCorrectTitle => 'Correct answer';

  @override
  String get quizAnswerWrongTitle => 'That answer isn\'t right';

  @override
  String quizCorrectAnswerIs(String option) {
    return 'Correct answer: $option';
  }

  @override
  String get quizReviewTitle => 'Questions you missed';

  @override
  String get quizReviewAllCorrect => 'You answered every question correctly.';

  @override
  String get onboardingComingSoon => 'Coming soon';

  @override
  String get onboardingComingSoonHint =>
      'Content for this field is on the way.';

  @override
  String get levelNone => 'Not started yet';

  @override
  String get gapStatusReached => 'Target reached';

  @override
  String get gapStatusDeveloping => 'Developing';

  @override
  String get gapStatusNeedsWork => 'Needs work';

  @override
  String get gapStatusNotStarted => 'Not started yet';

  @override
  String get skillGapTitle => 'Skills for your goal';

  @override
  String get skillGapSubtitle =>
      'Where you are and the level your path aims for.';

  @override
  String get skillGapDashboardTitle => 'Toward your goal';

  @override
  String skillGapDeveloping(int count) {
    return '$count skills in progress';
  }

  @override
  String get skillGapAllReached =>
      'You reached the target in every skill on your path.';

  @override
  String get skillGapCurrentLabel => 'Now';

  @override
  String get skillGapTargetLabel => 'Target';

  @override
  String skillGapProgressExplained(int percent) {
    return '$percent% progress in content and quizzes';
  }

  @override
  String get skillGapViewPath => 'See My Path';

  @override
  String get skillGapPriorityTitle => 'Focus next';

  @override
  String get skillGapLoadError => 'Your skill status could not be loaded.';

  @override
  String get skillGapEmptyTitle =>
      'The skill map for this specialization isn\'t ready yet.';

  @override
  String get pathGoalTitle => 'My Goal';

  @override
  String get pathJourneyTitle => 'My Journey';

  @override
  String get pathSkillsTitle => 'My Skills';

  @override
  String get stepDetailTitle => 'Project Step';

  @override
  String stepDetailOrder(int order) {
    return 'Step $order of the project';
  }

  @override
  String stepDetailOrderOfTotal(int order, int total) {
    return 'Step $order of $total';
  }

  @override
  String get stepDetailWhyTitle => 'Why does this step matter?';

  @override
  String stepDetailWhyBody(String skill) {
    return 'Finishing this step makes your project a bit more real and moves your $skill skill forward.';
  }

  @override
  String get stepDetailWhyBodyGeneric =>
      'Finishing this step makes your project a bit more real.';

  @override
  String get stepDetailChecklistTitle => 'What to do';

  @override
  String get stepDetailChecklistRead => 'Read the related content';

  @override
  String get stepDetailChecklistApply => 'Apply the step in your project';

  @override
  String get stepDetailChecklistVerify => 'Check that it works';

  @override
  String get stepDetailContentTitle => 'Content to study';

  @override
  String get stepDetailQuizTitle => 'Test your knowledge';

  @override
  String get stepDetailOpenQuiz => 'Open Quiz';

  @override
  String get stepDetailSkillLabel => 'Related skill';

  @override
  String get stepDetailLockedTitle => 'This step isn\'t unlocked yet.';

  @override
  String get stepDoneTitle => 'Step completed.';

  @override
  String stepDoneProgress(int completed, int total) {
    return '$completed of $total steps completed.';
  }

  @override
  String get stepDoneUnlocked => 'The next step is unlocked.';

  @override
  String stepDoneSkill(String skill) {
    return 'You made progress in $skill.';
  }

  @override
  String get stepDoneNextLabel => 'Next step';

  @override
  String get stepDoneNextCta => 'Go to the next step';

  @override
  String get stepDoneProjectFinished =>
      'You completed your project. You now have something to show.';

  @override
  String get stepDoneClose => 'Close';

  @override
  String todayProjectHint(String goal) {
    return 'This step takes you toward: $goal';
  }

  @override
  String get taskTypeProject => 'Project';
}
