import 'package:flutter/widgets.dart';

/// Breakpoints e utilitários simples de layout responsivo do ReplayGO.
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 905;
  static const double desktop = 1240;
}

enum ScreenType { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  ScreenType get screenType {
    final width = screenWidth;
    if (width >= Breakpoints.tablet) return ScreenType.desktop;
    if (width >= Breakpoints.mobile) return ScreenType.tablet;
    return ScreenType.mobile;
  }

  bool get isMobile => screenType == ScreenType.mobile;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop => screenType == ScreenType.desktop;

  /// `true` quando há largura suficiente para uma sidebar fixa (em vez do drawer).
  bool get hasWideLayout => screenWidth >= Breakpoints.tablet;
}

/// Centraliza o conteúdo limitando a largura máxima em telas grandes,
/// mantendo o layout legível em web/desktop sem esticar demais.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 900,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
