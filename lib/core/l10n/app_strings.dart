import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../engine/chess_engine.dart';
import '../../features/game/domain/coach/coach_note.dart';
import '../../features/game/domain/game_outcome.dart';
import '../../features/progress/domain/achievement.dart';
import '../../features/progress/domain/player_rank.dart';
import '../../features/settings/domain/app_settings.dart';

/// All user-facing text in Arabic and English, side by side.
///
/// Access it with `context.s` (see [AppStringsX]).
class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isArabic => language == AppLanguage.arabic;

  String _t(String ar, String en) => isArabic ? ar : en;

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      const AppStrings(AppLanguage.arabic);

  // ---------------------------------------------------------------------------
  // General
  // ---------------------------------------------------------------------------

  String get appName => _t('رقعة', 'Ruqa');
  String get appTagline => _t('شطرنج بروحٍ عربية', 'Chess with an Arabic soul');
  String get ok => _t('حسناً', 'OK');
  String get cancel => _t('إلغاء', 'Cancel');
  String get close => _t('إغلاق', 'Close');
  String get continueLabel => _t('متابعة', 'Continue');
  String get start => _t('ابدأ', 'Start');
  String get yes => _t('نعم', 'Yes');
  String get no => _t('لا', 'No');
  String get accept => _t('قبول', 'Accept');
  String get decline => _t('رفض', 'Decline');
  String get coins => _t('عملة', 'coins');
  String get locked => _t('مقفل', 'Locked');
  String get white => _t('الأبيض', 'White');
  String get black => _t('الأسود', 'Black');
  String get random => _t('عشوائي', 'Random');
  String get you => _t('أنت', 'You');
  String get computer => _t('الكمبيوتر', 'Computer');
  String get playerOne => _t('اللاعب الأول', 'Player 1');
  String get playerTwo => _t('اللاعب الثاني', 'Player 2');
  String get friend => _t('صديقك', 'Your friend');

  String colorName(PieceColor color) =>
      color == PieceColor.white ? white : black;

  String levelLabel(int level) => _t('المستوى $level', 'Level $level');

  String xpProgress(int current, int needed) =>
      _t('$current / $needed خبرة', '$current / $needed XP');

  String pieceName(PieceType type) => switch (type) {
    PieceType.pawn => _t('البيدق', 'pawn'),
    PieceType.knight => _t('الحصان', 'knight'),
    PieceType.bishop => _t('الفيل', 'bishop'),
    PieceType.rook => _t('القلعة', 'rook'),
    PieceType.queen => _t('الوزير', 'queen'),
    PieceType.king => _t('الملك', 'king'),
  };

  String pieceTitle(PieceType type) => switch (type) {
    PieceType.pawn => _t('البيدق', 'Pawn'),
    PieceType.knight => _t('الحصان', 'Knight'),
    PieceType.bishop => _t('الفيل', 'Bishop'),
    PieceType.rook => _t('القلعة', 'Rook'),
    PieceType.queen => _t('الوزير', 'Queen'),
    PieceType.king => _t('الملك', 'King'),
  };

  String _placed(PlacedPiece piece) =>
      '${pieceName(piece.type)} (${Square.name(piece.square)})';

  String _list(Iterable<String> items) => items.join(_t('، ', ', '));

  String rankTitle(RankTitle title) => switch (title) {
    RankTitle.novice => _t('مبتدئ', 'Novice'),
    RankTitle.amateur => _t('هاوٍ', 'Amateur'),
    RankTitle.clubPlayer => _t('لاعب نادٍ', 'Club player'),
    RankTitle.pro => _t('محترف', 'Pro'),
    RankTitle.expert => _t('خبير', 'Expert'),
    RankTitle.master => _t('أستاذ', 'Master'),
    RankTitle.grandmaster => _t('أستاذ كبير', 'Grandmaster'),
  };

  // ---------------------------------------------------------------------------
  // Onboarding
  // ---------------------------------------------------------------------------

  String get welcomeTitle => _t('أهلاً بك في رقعة', 'Welcome to Ruqa');
  String get welcomeSubtitle => _t(
    'الشطرنج الكلاسيكي بتصميم فاخر، ومدرّب ذكي يرافقك نقلة بنقلة.',
    'Classic chess with a luxurious look and a smart coach by your side, move by move.',
  );
  String get yourName => _t('اسمك', 'Your name');
  String get namePlaceholder =>
      _t('اكتب اسمك (اختياري)', 'Type your name (optional)');
  String get experienceQuestion =>
      _t('ما مستواك في الشطرنج؟', 'How well do you play?');
  String get letsGo => _t('لنبدأ!', "Let's go!");
  String get languageLabel => _t('اللغة', 'Language');

  String experienceName(ExperienceLevel level) => switch (level) {
    ExperienceLevel.beginner => _t(
      'مبتدئ — أتعلّم الآن',
      'Beginner — learning now',
    ),
    ExperienceLevel.intermediate => _t('أعرف القوانين', 'I know the rules'),
    ExperienceLevel.advanced => _t('لاعب متمرّس', 'Experienced player'),
  };

  String experienceDescription(ExperienceLevel level) => switch (level) {
    ExperienceLevel.beginner => _t(
      'دروس أساسية أولاً، شرح لكل نقلة، وتلميحات بلا حدود.',
      'Basic lessons first, every move explained, unlimited hints.',
    ),
    ExperienceLevel.intermediate => _t(
      'مساعدات اختيارية وتحديات تزداد صعوبة تدريجياً.',
      'Optional assistance and gradually harder challenges.',
    ),
    ExperienceLevel.advanced => _t(
      'بدون مساعدات. تحدَّ أقوى المستويات مباشرة.',
      'No assistance. Take on the strongest levels.',
    ),
  };

  // ---------------------------------------------------------------------------
  // Home
  // ---------------------------------------------------------------------------

  String greeting(String name) => name.isEmpty
      ? _t('أهلاً بك', 'Welcome')
      : _t('أهلاً، $name', 'Hi, $name');

  String get dailyRewardTitle => _t('مكافأة اليوم', 'Daily reward');
  String dailyRewardBody(int coins) => _t(
    'استلم $coins عملة اليوم، وعُد غداً لمكافأة أكبر!',
    'Collect $coins coins today and come back tomorrow for more!',
  );
  String dailyStreak(int days) =>
      _t('سلسلة الأيام: $days', 'Streak: $days days');
  String get claim => _t('استلم', 'Claim');
  String dailyClaimed(int coins) =>
      _t('حصلت على $coins عملة!', 'You got $coins coins!');

  String get modeComputer => _t('تحدَّ الكمبيوتر', 'Challenge the computer');
  String modeComputerSubtitle(int level) => _t(
    '10 مستويات — أنت الآن في المستوى $level',
    '10 levels — you are on level $level',
  );
  String get modeLocal => _t('لاعبان على جهاز واحد', 'Two players, one device');
  String get modeLocalSubtitle =>
      _t('العب مع صديقك على نفس الهاتف', 'Play a friend on the same phone');
  String get modeLan => _t('العب مع صديق عبر الشبكة', 'Play a friend on Wi-Fi');
  String get modeLanSubtitle =>
      _t('جهازان على نفس شبكة الواي فاي', 'Two devices on the same network');
  String get modeLearn => _t('تعلّم الشطرنج', 'Learn chess');
  String modeLearnSubtitle(int done, int total) =>
      _t('أكملت $done من $total دروس', '$done of $total lessons done');
  String get modeProfile =>
      _t('الإنجازات والمجموعة', 'Achievements & collection');
  String get modeProfileSubtitle =>
      _t('الأوسمة، الثيمات والإحصائيات', 'Badges, themes and statistics');
  String get quickPlay => _t('مباراة حرة', 'Free play');
  String get quickPlaySubtitle =>
      _t('اختر أي مستوى مفتوح وإعداداتك', 'Any unlocked level, your settings');
  String get continueLearning => _t('تابع التعلّم', 'Continue learning');
  String get settings => _t('الإعدادات', 'Settings');

  // ---------------------------------------------------------------------------
  // Levels
  // ---------------------------------------------------------------------------

  String get levelsTitle => _t('رحلة التحدي', 'The challenge journey');
  String get levelsSubtitle => _t(
    'اهزم كل مستوى لتفتح التالي واجمع النجوم.',
    'Beat each level to unlock the next and collect stars.',
  );

  String aiLevelName(int level) => switch (level) {
    1 => _t('البيدق الصغير', 'Little Pawn'),
    2 => _t('البيدق الشجاع', 'Brave Pawn'),
    3 => _t('الحصان', 'The Knight'),
    4 => _t('الفيل', 'The Bishop'),
    5 => _t('القلعة', 'The Rook'),
    6 => _t('الوزير', 'The Vizier'),
    7 => _t('الملك', 'The King'),
    8 => _t('الأستاذ', 'The Master'),
    9 => _t('الأستاذ الكبير', 'The Grandmaster'),
    _ => _t('الأسطورة', 'The Legend'),
  };

  String aiLevelDescription(int level) => switch (level) {
    1 => _t(
      'يتعلّم مثلك ويرتكب أخطاء كثيرة.',
      'Still learning, makes many mistakes.',
    ),
    2 => _t(
      'يأكل كل ما يراه ولا ينتبه للفخاخ.',
      'Grabs everything, ignores traps.',
    ),
    3 => _t(
      'يرى خطوة للأمام ويخطئ أحياناً.',
      'Looks one move ahead, slips sometimes.',
    ),
    4 => _t(
      'أكثر حذراً، لكن له نقاط ضعف.',
      'More careful, but has weak spots.',
    ),
    5 => _t('يعاقب القطع غير المحمية.', 'Punishes loose pieces.'),
    6 => _t(
      'لاعب نادٍ قوي ونادراً ما يخطئ.',
      'A solid club player, rarely slips.',
    ),
    7 => _t('يحسب بعمق ولا يرحم.', 'Calculates deeply and shows no mercy.'),
    8 => _t('تكتيكات حادة وخطط واضحة.', 'Sharp tactics and clear plans.'),
    9 => _t('قوة احترافية حقيقية.', 'True professional strength.'),
    _ => _t(
      'أقوى ما في المحرك. هل تجرؤ؟',
      'The engine at full power. Dare you?',
    ),
  };

  String approxRating(int rating) =>
      _t('قوة تقريبية: $rating', 'Approx. rating: $rating');
  String get levelLocked => _t(
    'اهزم المستوى السابق لفتح هذا المستوى.',
    'Beat the previous level to unlock this one.',
  );
  String get chooseColor => _t('اختر لونك', 'Choose your colour');
  String get timeControl => _t('المؤقت', 'Clock');
  String get noTimer => _t('بدون مؤقت', 'No clock');
  String minutes(int count) => _t('$count د', '$count min');
  String get startGame => _t('ابدأ المباراة', 'Start game');
  String get chooseLevel => _t('اختر المستوى', 'Choose a level');

  // ---------------------------------------------------------------------------
  // Local game setup
  // ---------------------------------------------------------------------------

  String get localSetupTitle =>
      _t('لاعبان على جهاز واحد', 'Two players, one device');
  String get whitePlayerName => _t('اسم لاعب الأبيض', "White player's name");
  String get blackPlayerName => _t('اسم لاعب الأسود', "Black player's name");
  String get autoFlipBoard =>
      _t('قلب الرقعة تلقائياً بعد كل نقلة', 'Flip the board after every move');

  // ---------------------------------------------------------------------------
  // Game screen
  // ---------------------------------------------------------------------------

  String get yourTurn => _t('دورك', 'Your turn');
  String get thinking => _t('يفكّر…', 'Thinking…');
  String turnOf(PieceColor color) => color == PieceColor.white
      ? _t('دور الأبيض', "White's turn")
      : _t('دور الأسود', "Black's turn");
  String get check => _t('كش!', 'Check!');
  String get hint => _t('تلميح', 'Hint');
  String get undo => _t('تراجع', 'Undo');
  String get flip => _t('اقلب', 'Flip');
  String get resign => _t('استسلام', 'Resign');
  String get offerDraw => _t('تعادل', 'Draw');
  String get predictions => _t('التنبؤات', 'Predictions');
  String get coach => _t('المدرّب', 'Coach');
  String get moves => _t('النقلات', 'Moves');
  String get reactions => _t('تفاعل', 'React');
  String hintsLeft(int count) => _t('متبقٍ $count', '$count left');
  String get unlimited => _t('بلا حدود', 'Unlimited');
  String get confirmResignTitle => _t('هل تريد الاستسلام؟', 'Resign the game?');
  String get confirmResignBody =>
      _t('ستُحتسب المباراة خسارة.', 'The game will count as a loss.');
  String get confirmDrawTitle =>
      _t('إنهاء المباراة بالتعادل؟', 'End the game in a draw?');
  String get confirmLeaveTitle => _t('مغادرة المباراة؟', 'Leave the game?');
  String get confirmLeaveBody =>
      _t('لن يتم حفظ هذه المباراة.', 'This game will not be saved.');
  String get leave => _t('مغادرة', 'Leave');
  String get drawDeclined =>
      _t('رفض الخصم التعادل.', 'The draw offer was declined.');
  String get opponentOffersDraw =>
      _t('الخصم يعرض التعادل', 'Your opponent offers a draw');
  String get drawOfferSent => _t('أُرسل عرض التعادل…', 'Draw offer sent…');
  String get hintLimitReached => _t(
    'انتهت تلميحات هذه المباراة. فعّل وضع التعلّم لتلميحات بلا حدود.',
    'No hints left this game. Turn on learning mode for unlimited hints.',
  );
  String get opponentLeft => _t('غادر الخصم المباراة.', 'Your opponent left.');
  String get rematchDeclined =>
      _t('رفض الخصم مباراة الإعادة.', 'Rematch declined.');
  String get checkingMove => _t('نتحقق من النقلة…', 'Checking your move…');
  String get choosePromotion =>
      _t('اختر قطعة الترقية', 'Choose a promotion piece');

  String get riskyTitle => _t('انتبه! نقلة خطيرة', 'Careful! Risky move');
  String riskyLoss(String? reply) => reply == null
      ? _t('هذه النقلة قد تخسر قطعة مهمة.', 'This move may lose material.')
      : _t(
          'هذه النقلة قد تخسر قطعة: يستطيع الخصم الرد بـ $reply.',
          'This move may lose material: your opponent can answer $reply.',
        );
  String get riskyMate =>
      _t('هذه النقلة تسمح للخصم بكش مات!', 'This move allows checkmate!');
  String riskyBetter(String move) =>
      _t('اقتراح أفضل: $move', 'A better idea: $move');
  String get riskyPlayAnyway => _t('العب على أي حال', 'Play it anyway');
  String get riskyChooseAnother => _t('اختر نقلة أخرى', 'Choose another move');

  String get evaluationEqual => _t('الوضعية متكافئة', 'The position is equal');
  String evaluationAdvantage(PieceColor color, String pawns) =>
      color == PieceColor.white
      ? _t('أفضلية للأبيض $pawns', 'White is better $pawns')
      : _t('أفضلية للأسود $pawns', 'Black is better $pawns');
  String evaluationMate(PieceColor color, int moves) =>
      color == PieceColor.white
      ? _t('الأبيض يكش مات خلال $moves', 'White mates in $moves')
      : _t('الأسود يكش مات خلال $moves', 'Black mates in $moves');
  String get predictedLine => _t('الحركات المتوقعة', 'Expected line');
  String threat(String san) => _t('تهديد الخصم: $san', 'Threat: $san');
  String get analyzing => _t('يحلّل…', 'Analysing…');

  // ---------------------------------------------------------------------------
  // Game over
  // ---------------------------------------------------------------------------

  String get youWon => _t('فوز رائع!', 'You won!');
  String get youLost => _t('خسارة هذه المرة', 'You lost this time');
  String get draw => _t('تعادل', 'Draw');
  String wins(String name) => _t('فاز $name', '$name wins');

  String outcomeReason(OutcomeReason reason) => switch (reason) {
    OutcomeReason.checkmate => _t('بكش مات', 'by checkmate'),
    OutcomeReason.stalemate => _t('بالجمود (لا نقلات ممكنة)', 'by stalemate'),
    OutcomeReason.insufficientMaterial => _t(
      'لعدم كفاية القطع للكش مات',
      'by insufficient material',
    ),
    OutcomeReason.fiftyMoveRule => _t(
      'بقاعدة الخمسين نقلة',
      'by the fifty-move rule',
    ),
    OutcomeReason.threefoldRepetition => _t(
      'بتكرار الوضعية ثلاث مرات',
      'by threefold repetition',
    ),
    OutcomeReason.resignation => _t('بالاستسلام', 'by resignation'),
    OutcomeReason.timeout => _t('بانتهاء الوقت', 'on time'),
    OutcomeReason.agreement => _t('بالاتفاق', 'by agreement'),
    OutcomeReason.opponentLeft => _t('لمغادرة الخصم', 'opponent left'),
  };

  String get rewards => _t('المكافآت', 'Rewards');
  String xpGained(int xp) => _t('+$xp خبرة', '+$xp XP');
  String coinsGained(int coins) => _t('+$coins عملة', '+$coins coins');
  String levelUp(int level) =>
      _t('ارتقيت إلى المستوى $level!', 'You reached level $level!');
  String levelUnlocked(int level) =>
      _t('فُتح المستوى $level!', 'Level $level unlocked!');
  String get newAchievement => _t('إنجاز جديد', 'New achievement');
  String get playAgain => _t('العب مجدداً', 'Play again');
  String get nextLevel => _t('المستوى التالي', 'Next level');
  String get backHome => _t('الرئيسية', 'Home');
  String get rematch => _t('مباراة إعادة', 'Rematch');
  String get rematchWaiting =>
      _t('بانتظار موافقة الخصم…', 'Waiting for your opponent…');
  String get rematchOffered =>
      _t('الخصم يطلب مباراة إعادة', 'Your opponent wants a rematch');
  String get viewBoard => _t('عرض الرقعة', 'View board');

  // ---------------------------------------------------------------------------
  // Coach
  // ---------------------------------------------------------------------------

  String coachNote(CoachNote note) => switch (note) {
    WelcomeNote(:final learnerColor) =>
      learnerColor == PieceColor.white
          ? _t(
              'أنت تلعب بالأبيض، والأبيض يبدأ دائماً. اضغط على أي قطعة لترى حركاتها الممكنة.',
              'You play White, and White always starts. Tap any piece to see where it can go.',
            )
          : _t(
              'أنت تلعب بالأسود. الأبيض يبدأ أولاً، انتظر نقلته ثم اضغط على قطعك لترى حركاتها.',
              'You play Black. White moves first; then tap your pieces to see their moves.',
            ),
    PieceIntroNote(:final type) => pieceRule(type),
    MoveDescriptionNote(:final move) => _t(
      'الخصم حرّك ${pieceName(move.piece.type)} من ${Square.name(move.from)} إلى ${Square.name(move.to)}.',
      'Your opponent moved the ${pieceName(move.piece.type)} from ${Square.name(move.from)} to ${Square.name(move.to)}.',
    ),
    CaptureNote(:final captured, :final byLearner) =>
      byLearner
          ? _t(
              'أحسنت! أكلت ${pieceName(captured)} (قيمته ${captured.value}).',
              'Nice! You captured a ${pieceName(captured)} (worth ${captured.value}).',
            )
          : _t(
              'الخصم أكل ${pieceName(captured)} الخاص بك.',
              'Your opponent captured your ${pieceName(captured)}.',
            ),
    CheckNote(:final byLearner) =>
      byLearner
          ? _t(
              'كش! ملك الخصم مهدد، وعليه أن يحميه الآن.',
              'Check! The enemy king is attacked and must be protected.',
            )
          : _t(
              'ملكك في كش! احمه بتحريكه، أو بوضع قطعة في الطريق، أو بأكل القطعة المهاجمة.',
              'Your king is in check! Move it, block the attack, or capture the attacker.',
            ),
    CastlingNote(:final byLearner) =>
      byLearner
          ? _t(
              'تبييت ممتاز! أصبح ملكك في أمان ودخلت القلعة إلى اللعب.',
              'Great castling! Your king is safer and your rook joins the game.',
            )
          : _t(
              'الخصم بيّت ملكه ليحميه.',
              'Your opponent castled to protect the king.',
            ),
    EnPassantNote() => _t(
      'أكل بالمرور: حركة خاصة يأكل فيها البيدق بيدقاً تقدّم خانتين ووقف بجانبه.',
      'En passant: a special pawn capture of a pawn that just moved two squares beside it.',
    ),
    PromotionNote(:final promotedTo, :final byLearner) =>
      byLearner
          ? _t(
              'ترقية! وصل بيدقك إلى الصف الأخير وأصبح ${pieceName(promotedTo)}.',
              'Promotion! Your pawn reached the last rank and became a ${pieceName(promotedTo)}.',
            )
          : _t(
              'الخصم رقّى بيدقاً إلى ${pieceName(promotedTo)}!',
              'Your opponent promoted a pawn to a ${pieceName(promotedTo)}!',
            ),
    AttackNote(:final attacker, :final targets, :final byLearner) =>
      byLearner
          ? _t(
              '${pieceName(attacker)} يهاجم الآن: ${_list(targets.map(_placed))}.',
              'Your ${pieceName(attacker)} now attacks: ${_list(targets.map(_placed))}.',
            )
          : _t(
              'انتبه: ${pieceName(attacker)} الخصم يهاجم ${_list(targets.map(_placed))}.',
              "Watch out: the enemy ${pieceName(attacker)} attacks your ${_list(targets.map(_placed))}.",
            ),
    HangingNote(:final pieces) => _t(
      'قطع في خطر: ${_list(pieces.map(_placed))} — مهددة ولا تحميها قطعة كافية.',
      'In danger: ${_list(pieces.map(_placed))} — attacked and not safely defended.',
    ),
    OpeningTipNote(:final tip) => openingTip(tip),
    MoveQualityNote(:final quality, :final betterSan) => moveQuality(
      quality,
      betterSan,
    ),
    HintNote(:final san, :final reason, :final mateIn) =>
      '${_t('تلميح', 'Hint')}: $san — ${hintReason(reason, mateIn)}',
  };

  String pieceRule(PieceType type) => switch (type) {
    PieceType.pawn => _t(
      'البيدق يتقدم للأمام خانة واحدة (أو خانتين في أول حركة له)، ويأكل قطرياً فقط.',
      'The pawn moves forward one square (two on its first move) and captures diagonally.',
    ),
    PieceType.knight => _t(
      'الحصان يتحرك على شكل حرف L، وهو الوحيد الذي يقفز فوق القطع.',
      'The knight moves in an L shape and is the only piece that jumps over others.',
    ),
    PieceType.bishop => _t(
      'الفيل يتحرك قطرياً لأي مسافة، ويبقى دائماً على مربعات من نفس اللون.',
      'The bishop moves diagonally any distance and always stays on one colour.',
    ),
    PieceType.rook => _t(
      'القلعة تتحرك أفقياً أو عمودياً لأي مسافة.',
      'The rook moves horizontally or vertically any distance.',
    ),
    PieceType.queen => _t(
      'الوزير أقوى قطعة: يتحرك كالقلعة والفيل معاً.',
      'The queen is the strongest piece: she moves like a rook and a bishop combined.',
    ),
    PieceType.king => _t(
      'الملك يتحرك خانة واحدة في أي اتجاه، ويجب حمايته دائماً.',
      'The king moves one square in any direction and must always be kept safe.',
    ),
  };

  String openingTip(OpeningTip tip) => switch (tip) {
    OpeningTip.controlCenter => _t(
      'نصيحة: ابدأ بالسيطرة على المركز بتحريك بيدق e أو d خطوتين.',
      'Tip: start by controlling the centre — push the e- or d-pawn two squares.',
    ),
    OpeningTip.developPieces => _t(
      'نصيحة: أخرج الأحصنة والأفيال مبكراً لتشارك في اللعب.',
      'Tip: bring out your knights and bishops early.',
    ),
    OpeningTip.castleEarly => _t(
      'نصيحة: بيّت ملكك مبكراً ليكون في أمان.',
      'Tip: castle early to keep your king safe.',
    ),
    OpeningTip.queenTooEarly => _t(
      'نصيحة: لا تُخرج الوزير مبكراً، فقد يطارده الخصم ويكسب الوقت.',
      'Tip: avoid bringing the queen out early; she can be chased around.',
    ),
    OpeningTip.samePieceTwice => _t(
      'نصيحة: تجنّب تحريك نفس القطعة مرتين في الافتتاح، وطوّر قطعاً أخرى.',
      'Tip: avoid moving the same piece twice in the opening; develop others.',
    ),
  };

  String moveQuality(MoveQuality quality, String? better) {
    final hint = better == null
        ? ''
        : _t(' الأفضل كان $better.', ' Better was $better.');
    return switch (quality) {
      MoveQuality.best => _t('نقلة ممتازة! ⭐', 'Excellent move! ⭐'),
      MoveQuality.good => _t('نقلة جيدة 👍', 'Good move 👍'),
      MoveQuality.inaccuracy => _t('نقلة غير دقيقة.$hint', 'Inaccuracy.$hint'),
      MoveQuality.mistake => _t('خطأ.$hint', 'Mistake.$hint'),
      MoveQuality.blunder => _t('خطأ فادح!$hint', 'Blunder!$hint'),
    };
  }

  String hintReason(HintReason reason, int? mateIn) => switch (reason) {
    HintReason.mate => _t(
      'تؤدي إلى كش مات خلال ${mateIn ?? 1}!',
      'leads to checkmate in ${mateIn ?? 1}!',
    ),
    HintReason.winsMaterial => _t('تكسب قطعة.', 'wins material.'),
    HintReason.savesPiece => _t(
      'تنقذ قطعتك المهددة.',
      'saves your attacked piece.',
    ),
    HintReason.castles => _t(
      'تحمي ملكك بالتبييت.',
      'castles your king to safety.',
    ),
    HintReason.develops => _t('تطوّر قطعة جديدة.', 'develops a new piece.'),
    HintReason.controlsCenter => _t(
      'تسيطر على المركز.',
      'controls the centre.',
    ),
    HintReason.promotes => _t('ترقّي البيدق!', 'promotes the pawn!'),
    HintReason.givesCheck => _t('تضع ملك الخصم في كش.', 'gives check.'),
    HintReason.improves => _t(
      'أفضل نقلة حسب المحرك.',
      "the engine's best move.",
    ),
  };

  // ---------------------------------------------------------------------------
  // Lessons
  // ---------------------------------------------------------------------------

  String get lessonsTitle => _t('أكاديمية رقعة', 'Ruqa Academy');
  String get lessonsSubtitle => _t(
    'من أول حركة إلى أول كش مات — خطوة بخطوة.',
    'From your first move to your first checkmate — step by step.',
  );
  String lessonStep(int step, int total) =>
      _t('الخطوة $step من $total', 'Step $step of $total');
  String get lessonCompleted => _t('أكملت الدرس!', 'Lesson complete!');
  String get nextLesson => _t('الدرس التالي', 'Next lesson');
  String get nextStep => _t('التالي', 'Next');
  String get tryAgain =>
      _t('ليست هذه. حاول مرة أخرى!', 'Not quite. Try again!');
  String get wellDone => _t('أحسنت!', 'Well done!');
  String get restartStep => _t('أعد هذه الخطوة', 'Restart this step');
  String starsLeft(int count) =>
      _t('النجوم المتبقية: $count', 'Stars left: $count');
  String get completed => _t('مكتمل', 'Completed');
  String get startLesson => _t('ابدأ الدرس', 'Start lesson');
  String get playFirstGame => _t('العب أول مباراة', 'Play your first game');

  // ---------------------------------------------------------------------------
  // Profile, achievements and collection
  // ---------------------------------------------------------------------------

  String get profileTitle => _t('ملفي', 'My profile');
  String get achievementsTab => _t('الإنجازات', 'Achievements');
  String get collectionTab => _t('المجموعة', 'Collection');
  String get statsTab => _t('الإحصائيات', 'Statistics');
  String get boardThemes => _t('الرقعات', 'Boards');
  String get pieceStyles => _t('القطع', 'Pieces');
  String get inUse => _t('مستخدمة', 'In use');
  String get use => _t('استخدم', 'Use');
  String get notEnoughCoins =>
      _t('لا تملك عملات كافية بعد.', 'Not enough coins yet.');
  String purchased(String name) => _t('أصبحت "$name" لك!', '"$name" is yours!');

  String achievementTitle(Achievement achievement) => switch (achievement) {
    Achievement.firstGame => _t('البداية', 'First steps'),
    Achievement.firstWin => _t('أول انتصار', 'First victory'),
    Achievement.castling => _t('الملك في أمان', 'Safe king'),
    Achievement.promotion => _t('ترقية', 'Promotion'),
    Achievement.enPassant => _t('الأكل بالمرور', 'En passant'),
    Achievement.pureWin => _t('بلا مساعدة', 'No help needed'),
    Achievement.quickWin => _t('الضربة السريعة', 'Lightning strike'),
    Achievement.checkmates5 => _t('فنان الكش مات', 'Checkmate artist'),
    Achievement.beatLevel5 => _t('قاهر القلعة', 'Rook breaker'),
    Achievement.beatLevel10 => _t('الأسطورة', 'Legend'),
    Achievement.allLessons => _t('التلميذ النجيب', 'Star pupil'),
    Achievement.friendlyGame => _t('مباراة ودية', 'Friendly match'),
    Achievement.lanGame => _t('لاعب الشبكة', 'Network player'),
    Achievement.dailyStreak3 => _t('ثلاثة أيام متتالية', 'Three-day streak'),
    Achievement.tenWins => _t('عشرة انتصارات', 'Ten victories'),
  };

  String achievementDescription(
    Achievement achievement,
  ) => switch (achievement) {
    Achievement.firstGame => _t(
      'أنهِ أول مباراة لك.',
      'Finish your first game.',
    ),
    Achievement.firstWin => _t(
      'اهزم الكمبيوتر لأول مرة.',
      'Beat the computer once.',
    ),
    Achievement.castling => _t('بيّت ملكك في مباراة.', 'Castle in a game.'),
    Achievement.promotion => _t('رقِّ بيدقاً في مباراة.', 'Promote a pawn.'),
    Achievement.enPassant => _t('نفّذ الأكل بالمرور.', 'Capture en passant.'),
    Achievement.pureWin => _t(
      'افز دون تلميحات أو تراجع.',
      'Win without hints or undo.',
    ),
    Achievement.quickWin => _t(
      'افز في 20 نقلة أو أقل.',
      'Win in 20 moves or fewer.',
    ),
    Achievement.checkmates5 => _t(
      'افز بكش مات 5 مرات.',
      'Win by checkmate 5 times.',
    ),
    Achievement.beatLevel5 => _t('اهزم المستوى 5.', 'Beat level 5.'),
    Achievement.beatLevel10 => _t('اهزم المستوى 10.', 'Beat level 10.'),
    Achievement.allLessons => _t('أكمل كل الدروس.', 'Complete every lesson.'),
    Achievement.friendlyGame => _t(
      'العب مباراة على جهاز واحد.',
      'Play on one device.',
    ),
    Achievement.lanGame => _t(
      'العب مباراة عبر الشبكة.',
      'Play over the network.',
    ),
    Achievement.dailyStreak3 => _t(
      'استلم المكافأة 3 أيام متتالية.',
      'Claim the daily reward 3 days running.',
    ),
    Achievement.tenWins => _t('حقق 10 انتصارات.', 'Win 10 games.'),
  };

  String boardThemeName(String id) => switch (id) {
    'royal' => _t('ملكي', 'Royal'),
    'midnight' => _t('منتصف الليل', 'Midnight'),
    'emerald' => _t('زمردي', 'Emerald'),
    'desert' => _t('صحراوي', 'Desert'),
    'coral' => _t('مرجاني', 'Coral'),
    'ocean' => _t('بحري', 'Ocean'),
    'marble' => _t('رخامي', 'Marble'),
    'golden' => _t('ذهبي', 'Golden'),
    _ => id,
  };

  String pieceStyleName(String id) => switch (id) {
    'royal' => _t('اللؤلؤ والذهب', 'Pearl & gold'),
    'classic' => _t('كلاسيكي', 'Classic'),
    'emeraldRuby' => _t('زمرد وياقوت', 'Emerald & ruby'),
    'sapphireGold' => _t('ذهب وياقوت أزرق', 'Gold & sapphire'),
    'marble' => _t('رخام', 'Marble'),
    _ => id,
  };

  String get gamesPlayed => _t('المباريات', 'Games');
  String get winsLabel => _t('انتصارات', 'Wins');
  String get lossesLabel => _t('هزائم', 'Losses');
  String get drawsLabel => _t('تعادلات', 'Draws');
  String get winRate => _t('نسبة الفوز', 'Win rate');
  String get checkmatesLabel => _t('كش مات', 'Checkmates');
  String get starsLabel => _t('النجوم', 'Stars');
  String get lessonsLabel => _t('الدروس', 'Lessons');

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  String get learningSection =>
      _t('التعلّم والمساعدة', 'Learning & assistance');
  String get learningMode =>
      _t('وضع التعلّم (المدرّب)', 'Learning mode (coach)');
  String get learningModeDesc => _t(
    'شرح لكل نقلة، نصائح مستمرة، وتلميحات بلا حدود.',
    'Every move explained, ongoing tips and unlimited hints.',
  );
  String get safeguardsSection =>
      _t('التأمينات (مساعدات اختيارية)', 'Safeguards (optional assistance)');
  String get showLegalMoves => _t('إظهار النقلات الممكنة', 'Show legal moves');
  String get showLegalMovesDesc => _t(
    'نقاط على المربعات المتاحة للقطعة المختارة.',
    'Dots on the squares a piece can reach.',
  );
  String get highlightThreats =>
      _t('تمييز القطع المهددة', 'Highlight threatened pieces');
  String get highlightThreatsDesc => _t(
    'إطار أحمر حول قطعك المعرّضة للأكل.',
    'A red frame around your pieces that can be captured.',
  );
  String get blunderGuard => _t('الحماية من الأخطاء الفادحة', 'Blunder guard');
  String get blunderGuardDesc => _t(
    'يطلب تأكيداً قبل نقلة تخسر قطعة أو تسمح بكش مات.',
    'Asks for confirmation before a move that loses material or allows mate.',
  );
  String get allowUndo => _t('السماح بالتراجع', 'Allow undo');
  String get allowUndoDesc => _t(
    'التراجع عن النقلات ضد الكمبيوتر وعلى جهاز واحد.',
    'Take back moves against the computer and on one device.',
  );
  String get predictionsSection =>
      _t('التنبؤات المستقبلية', 'Future predictions');
  String get showPredictions => _t('إظهار التنبؤات', 'Show predictions');
  String get showPredictionsDesc => _t(
    'شريط التقييم، الحركات المتوقعة القادمة، وأسهم تهديدات الخصم.',
    'Evaluation bar, the expected next moves and arrows for threats.',
  );
  String get boardSection => _t('الرقعة واللعب', 'Board & play');
  String get autoQueen =>
      _t('الترقية التلقائية إلى وزير', 'Always promote to a queen');
  String get showCoordinates => _t('إظهار الإحداثيات', 'Show coordinates');
  String get autoFlipSetting =>
      _t('قلب الرقعة تلقائياً (جهاز واحد)', 'Auto-flip board (one device)');
  String get feedbackSection => _t('الصوت والاهتزاز', 'Sound & haptics');
  String get haptics => _t('الاهتزاز', 'Haptics');
  String get sounds => _t('أصوات النقلات', 'Move sounds');
  String get profileSection => _t('الملف الشخصي', 'Profile');
  String get experience => _t('مستوى الخبرة', 'Experience');
  String get resetProgress => _t('إعادة ضبط التقدم', 'Reset progress');
  String get resetConfirm => _t(
    'سيُحذف كل تقدمك وعملاتك وإنجازاتك. هل أنت متأكد؟',
    'All your progress, coins and achievements will be deleted. Are you sure?',
  );
  String get progressReset => _t('تمت إعادة الضبط.', 'Progress reset.');
  String get appearanceSection => _t('المظهر', 'Appearance');

  // ---------------------------------------------------------------------------
  // LAN
  // ---------------------------------------------------------------------------

  String get lanTitle => _t('اللعب عبر الشبكة', 'Network play');
  String get lanIntro => _t(
    'تأكد أنك وصديقك متصلان بنفس شبكة الواي فاي (أو نقطة اتصال أحدكما).',
    'Make sure you and your friend are on the same Wi-Fi (or one phone’s hotspot).',
  );
  String get hostGame => _t('أنشئ مباراة', 'Host a game');
  String get hostGameDesc => _t(
    'سيظهر اسمك لصديقك لينضم إليك.',
    'Your friend will see your name and join.',
  );
  String get joinGame => _t('انضم لمباراة', 'Join a game');
  String get joinGameDesc =>
      _t('ابحث عن مباراة صديقك القريبة.', "Find your friend's game nearby.");
  String get yourColor => _t('لونك', 'Your colour');
  String get startHosting => _t('ابدأ الاستضافة', 'Start hosting');
  String get waitingForOpponent =>
      _t('بانتظار انضمام صديقك…', 'Waiting for your friend to join…');
  String get yourAddress => _t('عنوانك على الشبكة', 'Your network address');
  String get addressHelp => _t(
    'إن لم تظهر مباراتك لصديقك، يمكنه إدخال هذا العنوان يدوياً.',
    'If your friend cannot see the game, they can type this address.',
  );
  String get searchingGames =>
      _t('نبحث عن مباريات قريبة…', 'Looking for nearby games…');
  String get noGamesFound => _t(
    'لا توجد مباريات بعد. اطلب من صديقك أن ينشئ مباراة.',
    'No games yet. Ask your friend to host one.',
  );
  String get enterAddress =>
      _t('أو أدخل العنوان يدوياً', 'Or enter the address');
  String get addressHint => _t('مثال: 192.168.1.5', 'e.g. 192.168.1.5');
  String get connect => _t('اتصل', 'Connect');
  String get connecting => _t('جارٍ الاتصال…', 'Connecting…');
  String get connectionFailed => _t(
    'تعذّر الاتصال. تأكد من العنوان ومن أنكما على نفس الشبكة.',
    'Could not connect. Check the address and that you share a network.',
  );
  String get lanUnsupported => _t(
    'اللعب عبر الشبكة غير متاح على هذه المنصة. جرّبه على الهاتف.',
    'Network play is not available on this platform. Try it on a phone.',
  );
  String hostedBy(String name) => _t('مباراة $name', "$name's game");
}

/// Supplies [AppStrings] through Flutter's localization system.
class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLanguage.values.any((l) => l.code == locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(AppLanguage.fromCode(locale.languageCode)));

  @override
  bool shouldReload(AppStringsDelegate old) => false;
}

extension AppStringsX on BuildContext {
  AppStrings get s => AppStrings.of(this);
}
