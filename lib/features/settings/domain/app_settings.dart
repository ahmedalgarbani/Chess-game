/// Interface language of the app.
enum AppLanguage {
  arabic('ar'),
  english('en');

  const AppLanguage(this.code);

  final String code;

  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => arabic);
}

/// How experienced the player said they are during onboarding.
enum ExperienceLevel { beginner, intermediate, advanced }

/// User preferences, including the optional assistance features
/// ("safeguards") and predictions.
class AppSettings {
  const AppSettings({
    this.language = AppLanguage.arabic,
    this.experience,
    this.playerName = '',
    this.learningMode = true,
    this.showLegalMoves = true,
    this.highlightThreats = true,
    this.blunderGuard = true,
    this.allowUndo = true,
    this.showPredictions = false,
    this.autoQueen = false,
    this.autoFlipBoard = true,
    this.showCoordinates = true,
    this.haptics = true,
    this.sounds = true,
    this.boardThemeId = 'royal',
    this.pieceStyleId = 'royal',
  });

  /// Sensible assistance defaults for each experience level.
  factory AppSettings.forExperience(
    ExperienceLevel level, {
    required AppLanguage language,
    required String playerName,
  }) {
    final beginner = level == ExperienceLevel.beginner;
    final advanced = level == ExperienceLevel.advanced;
    return AppSettings(
      language: language,
      experience: level,
      playerName: playerName,
      learningMode: beginner,
      showLegalMoves: !advanced,
      highlightThreats: !advanced,
      blunderGuard: !advanced,
      allowUndo: !advanced,
      showPredictions: false,
    );
  }

  final AppLanguage language;

  /// Null until onboarding has been completed.
  final ExperienceLevel? experience;
  final String playerName;

  /// Coach explanations during games and unlimited hints.
  final bool learningMode;

  // Safeguards.
  final bool showLegalMoves;
  final bool highlightThreats;
  final bool blunderGuard;
  final bool allowUndo;

  /// Evaluation bar, expected line and threat arrows.
  final bool showPredictions;

  final bool autoQueen;
  final bool autoFlipBoard;
  final bool showCoordinates;
  final bool haptics;
  final bool sounds;
  final String boardThemeId;
  final String pieceStyleId;

  bool get onboardingComplete => experience != null;

  AppSettings copyWith({
    AppLanguage? language,
    ExperienceLevel? experience,
    String? playerName,
    bool? learningMode,
    bool? showLegalMoves,
    bool? highlightThreats,
    bool? blunderGuard,
    bool? allowUndo,
    bool? showPredictions,
    bool? autoQueen,
    bool? autoFlipBoard,
    bool? showCoordinates,
    bool? haptics,
    bool? sounds,
    String? boardThemeId,
    String? pieceStyleId,
  }) {
    return AppSettings(
      language: language ?? this.language,
      experience: experience ?? this.experience,
      playerName: playerName ?? this.playerName,
      learningMode: learningMode ?? this.learningMode,
      showLegalMoves: showLegalMoves ?? this.showLegalMoves,
      highlightThreats: highlightThreats ?? this.highlightThreats,
      blunderGuard: blunderGuard ?? this.blunderGuard,
      allowUndo: allowUndo ?? this.allowUndo,
      showPredictions: showPredictions ?? this.showPredictions,
      autoQueen: autoQueen ?? this.autoQueen,
      autoFlipBoard: autoFlipBoard ?? this.autoFlipBoard,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      haptics: haptics ?? this.haptics,
      sounds: sounds ?? this.sounds,
      boardThemeId: boardThemeId ?? this.boardThemeId,
      pieceStyleId: pieceStyleId ?? this.pieceStyleId,
    );
  }

  Map<String, Object?> toJson() => {
    'language': language.code,
    'experience': experience?.name,
    'playerName': playerName,
    'learningMode': learningMode,
    'showLegalMoves': showLegalMoves,
    'highlightThreats': highlightThreats,
    'blunderGuard': blunderGuard,
    'allowUndo': allowUndo,
    'showPredictions': showPredictions,
    'autoQueen': autoQueen,
    'autoFlipBoard': autoFlipBoard,
    'showCoordinates': showCoordinates,
    'haptics': haptics,
    'sounds': sounds,
    'boardThemeId': boardThemeId,
    'pieceStyleId': pieceStyleId,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    const defaults = AppSettings();
    bool flag(String key, bool fallback) =>
        json[key] is bool ? json[key]! as bool : fallback;
    final experienceName = json['experience'];
    return AppSettings(
      language: AppLanguage.fromCode(json['language'] as String?),
      experience: ExperienceLevel.values
          .where((e) => e.name == experienceName)
          .firstOrNull,
      playerName: json['playerName'] as String? ?? '',
      learningMode: flag('learningMode', defaults.learningMode),
      showLegalMoves: flag('showLegalMoves', defaults.showLegalMoves),
      highlightThreats: flag('highlightThreats', defaults.highlightThreats),
      blunderGuard: flag('blunderGuard', defaults.blunderGuard),
      allowUndo: flag('allowUndo', defaults.allowUndo),
      showPredictions: flag('showPredictions', defaults.showPredictions),
      autoQueen: flag('autoQueen', defaults.autoQueen),
      autoFlipBoard: flag('autoFlipBoard', defaults.autoFlipBoard),
      showCoordinates: flag('showCoordinates', defaults.showCoordinates),
      haptics: flag('haptics', defaults.haptics),
      sounds: flag('sounds', defaults.sounds),
      boardThemeId: json['boardThemeId'] as String? ?? defaults.boardThemeId,
      pieceStyleId: json['pieceStyleId'] as String? ?? defaults.pieceStyleId,
    );
  }
}
