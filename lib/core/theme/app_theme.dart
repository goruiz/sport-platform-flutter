import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';

/// El tema único (oscuro) de la app. Define el aspecto por defecto de cada componente de Material
/// para que botones, campos, diálogos y hojas se vean igual en todas las pantallas sin repetir estilos.
class AppTheme {
  static ThemeData get sportsPlatform {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primaryLight,
      onPrimary: AppColors.primaryDark,
      surface: AppColors.sheetBackground,
      onSurface: AppColors.white,
      onSurfaceVariant: AppColors.whiteSubtle,
      outline: AppColors.inputBorder,
      error: AppColors.error,
    );

    return ThemeData(
      fontFamily: 'sans-serif',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundEnd,
      appBarTheme: _appBarTheme,
      navigationBarTheme: _navigationBarTheme,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
      ),
      filledButtonTheme: FilledButtonThemeData(style: _filledButtonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _filledButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: _outlinedButtonStyle),
      textButtonTheme: TextButtonThemeData(style: _textButtonStyle),
      inputDecorationTheme: _inputDecorationTheme,
      chipTheme: _chipTheme,
      segmentedButtonTheme: _segmentedButtonTheme,
      tabBarTheme: _tabBarTheme,
      dialogTheme: _dialogTheme,
      bottomSheetTheme: _bottomSheetTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.inputBorder,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primaryLight,
        textColor: AppColors.white,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primaryLight,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.sheetBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.inputBorder),
        ),
      ),
    );
  }

  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: AppColors.primaryDark,
    foregroundColor: AppColors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: AppColors.white,
      fontSize: 19,
      fontWeight: FontWeight.w700,
    ),
    iconTheme: IconThemeData(color: AppColors.white),
    actionsIconTheme: IconThemeData(color: AppColors.white),
  );

  /// La barra inferior: el destino activo se marca con una «píldora» y todos llevan su nombre.
  static final NavigationBarThemeData _navigationBarTheme = NavigationBarThemeData(
    backgroundColor: AppColors.primaryDark,
    indicatorColor: AppColors.primary.withValues(alpha: 0.55),
    surfaceTintColor: Colors.transparent,
    height: 68,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected)
            ? AppColors.white
            : AppColors.whiteSubtle,
        size: 24,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontSize: 12,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w700
            : FontWeight.w500,
        color: states.contains(WidgetState.selected)
            ? AppColors.white
            : AppColors.whiteSubtle,
      ),
    ),
  );

  static final ButtonStyle _filledButtonStyle = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(64, AppSizes.touchTarget)),
    elevation: const WidgetStatePropertyAll(0),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? AppColors.white.withValues(alpha: 0.12)
          : AppColors.action,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? AppColors.white.withValues(alpha: 0.38)
          : AppColors.white,
    ),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
  );

  static final ButtonStyle _outlinedButtonStyle = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(64, AppSizes.touchTarget)),
    foregroundColor: const WidgetStatePropertyAll(AppColors.white),
    side: const WidgetStatePropertyAll(BorderSide(color: AppColors.inputBorder)),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
  );

  static final ButtonStyle _textButtonStyle = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
    foregroundColor: const WidgetStatePropertyAll(AppColors.primaryLight),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );

  static final InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.inputFill,
    hintStyle: const TextStyle(color: AppColors.whiteSubtle),
    labelStyle: const TextStyle(color: AppColors.whiteSubtle),
    errorStyle: const TextStyle(color: AppColors.error),
    prefixIconColor: AppColors.whiteSubtle,
    suffixIconColor: AppColors.whiteSubtle,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: _inputBorder(AppColors.inputBorder),
    enabledBorder: _inputBorder(AppColors.inputBorder),
    focusedBorder: _inputBorder(AppColors.primaryLight, width: 1.5),
    errorBorder: _inputBorder(AppColors.error),
    focusedErrorBorder: _inputBorder(AppColors.error, width: 1.5),
  );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  /// Las «fichas» de filtro: la elegida se rellena de verde y se lee a simple vista.
  static final ChipThemeData _chipTheme = ChipThemeData(
    backgroundColor: AppColors.inputFill,
    selectedColor: AppColors.primary.withValues(alpha: 0.55),
    showCheckmark: false,
    labelStyle: WidgetStateTextStyle.resolveWith(
      (states) => TextStyle(
        color: states.contains(WidgetState.selected)
            ? AppColors.white
            : AppColors.whiteSubtle,
        fontSize: 13.5,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w700
            : FontWeight.w600,
      ),
    ),
    side: const BorderSide(color: AppColors.inputBorder),
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
  );

  static final SegmentedButtonThemeData _segmentedButtonTheme =
      SegmentedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary.withValues(alpha: 0.55)
            : AppColors.inputFill,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.white
            : AppColors.whiteSubtle,
      ),
      side: const WidgetStatePropertyAll(
        BorderSide(color: AppColors.inputBorder),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );

  static const TabBarThemeData _tabBarTheme = TabBarThemeData(
    labelColor: AppColors.white,
    unselectedLabelColor: AppColors.whiteSubtle,
    indicatorColor: AppColors.primaryLight,
    dividerColor: AppColors.inputBorder,
    labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static final DialogThemeData _dialogTheme = DialogThemeData(
    backgroundColor: AppColors.sheetBackground,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    titleTextStyle: const TextStyle(
      color: AppColors.white,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    contentTextStyle: const TextStyle(
      color: AppColors.whiteSubtle,
      fontSize: 14,
      height: 1.4,
    ),
  );

  static const BottomSheetThemeData _bottomSheetTheme = BottomSheetThemeData(
    backgroundColor: AppColors.sheetBackground,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
  );
}
