/// Shared breakpoints for the responsive shell.
abstract final class Breakpoints {
  /// Mobile: 768px and below — top navigation, content underneath.
  static const double mobileMax = 768;

  /// Desktop: 769px and above — left sidebar, content on the right.
  static const double desktopMin = 769;

  static bool isMobile(double width) => width <= mobileMax;
  static bool isDesktop(double width) => width >= desktopMin;
}

/// Scroll pagination reveals items in batches of 10.
abstract final class PaginationRules {
  static const int pageSize = 10;
}
