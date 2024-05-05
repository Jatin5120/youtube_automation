/// `AppConstants` is a singleton class with all static variables.
///
/// It contains all constants that are to be used within the project
///
/// If need to check the translated strings that are used in UI (Views) of the app, check TranslationKeys
class AppConstants {
  const AppConstants._();

  static const String name = 'YoutubeAutomation';

  static const Duration timeOutDuration = Duration(seconds: 180);

  static const double desktopLargeBreakPoint = 1920;
  static const double desktopBreakPoint = 1366;
  static const double tabletBreakPoint = 1024;
  static const double mobileBreakPoint = 612;

  static const String youtubeBase = 'https://www.youtube.com/';

  static const List<String> targetCountries = ['US', "GB", "CA", "AU", "NZ", "IE", "DK"];

  static const List<String> csvMimes = [
    'application/csv',
    'application/x-csv',
    'text/csv',
    'text/comma-separated-values',
    'text/x-comma-separated-values',
    'text/tab-separated-values',
  ];
}
