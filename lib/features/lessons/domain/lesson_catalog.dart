import '../../../engine/chess_engine.dart';
import 'lesson.dart';

/// The beginner curriculum, from the board to the first checkmate.
abstract final class LessonCatalog {
  static Lesson? byId(String id) =>
      lessons.where((lesson) => lesson.id == id).firstOrNull;

  static const lessons = <Lesson>[
    Lesson(
      id: 'board',
      icon: PieceType.king,
      title: LocalizedText('الرقعة والقطع', 'The board and pieces'),
      summary: LocalizedText(
        'تعرّف على الرقعة، القطع، وهدف اللعبة.',
        'Meet the board, the pieces and the goal of the game.',
      ),
      steps: [
        LessonStep(
          fen: startingFen,
          highlights: ['h1', 'a8'],
          text: LocalizedText(
            'الرقعة 8×8، أي 64 مربعاً. ضعها بحيث يكون المربع الفاتح في الزاوية اليمنى من جهتك (h1).',
            'The board has 8×8 = 64 squares. Place it so the light square is in your right-hand corner (h1).',
          ),
        ),
        LessonStep(
          fen: startingFen,
          text: LocalizedText(
            'لكل لاعب 16 قطعة: 8 بيادق، حصانان، فيلان، قلعتان، وزير وملك. الأبيض يبدأ دائماً.',
            'Each player has 16 pieces: 8 pawns, 2 knights, 2 bishops, 2 rooks, a queen and a king. White always moves first.',
          ),
        ),
        LessonStep(
          fen: '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1',
          highlights: ['g8'],
          text: LocalizedText(
            'الهدف: محاصرة ملك الخصم بحيث يُهاجَم ولا يستطيع الهروب. هذا اسمه «كش مات» وبه تنتهي المباراة.',
            'The goal: attack the enemy king so it cannot escape. That is called “checkmate”, and it ends the game.',
          ),
        ),
      ],
    ),
    Lesson(
      id: 'pawn',
      icon: PieceType.pawn,
      title: LocalizedText('البيدق', 'The pawn'),
      summary: LocalizedText(
        'جندي صغير يتقدم للأمام ويأكل قطرياً.',
        'A small soldier that marches forward and captures diagonally.',
      ),
      steps: [
        LessonStep(
          fen: '8/8/8/8/8/8/4P3/8 w - - 0 1',
          goal: CollectStarsGoal(['e4', 'e6']),
          text: LocalizedText(
            'البيدق يتقدم للأمام خانة واحدة، وفي أول حركة له يمكنه التقدم خانتين. اجمع النجوم!',
            'The pawn moves forward one square, or two on its very first move. Collect the stars!',
          ),
        ),
        LessonStep(
          fen: '8/8/8/2p5/3p4/4P3/8/8 w - - 0 1',
          goal: CaptureAllGoal(),
          text: LocalizedText(
            'البيدق يأكل قطرياً للأمام فقط. كُل البيدقين الأسودين.',
            'The pawn captures one square diagonally forward. Capture both black pawns.',
          ),
        ),
      ],
    ),
    Lesson(
      id: 'rook',
      icon: PieceType.rook,
      title: LocalizedText('القلعة (الرخ)', 'The rook'),
      summary: LocalizedText(
        'تتحرك في خطوط مستقيمة أفقية وعمودية.',
        'Moves in straight lines, across and up.',
      ),
      steps: [
        LessonStep(
          fen: '8/8/8/8/8/8/8/R7 w - - 0 1',
          goal: CollectStarsGoal(['a6', 'f6', 'f2']),
          text: LocalizedText(
            'القلعة تتحرك أفقياً أو عمودياً لأي مسافة. اجمع النجوم بأقل عدد من النقلات.',
            'The rook moves horizontally or vertically any distance. Collect the stars.',
          ),
        ),
        LessonStep(
          fen: '8/p6n/8/8/8/8/8/R7 w - - 0 1',
          goal: CaptureAllGoal(),
          text: LocalizedText(
            'القلعة تأكل القطعة التي تقف في طريقها. كُل القطعتين السوداوين.',
            'The rook captures whatever stands on its path. Capture both black pieces.',
          ),
        ),
      ],
    ),
    Lesson(
      id: 'bishop',
      icon: PieceType.bishop,
      title: LocalizedText('الفيل', 'The bishop'),
      summary: LocalizedText(
        'يتحرك قطرياً ويبقى على لون واحد.',
        'Moves diagonally and keeps to one colour.',
      ),
      steps: [
        LessonStep(
          fen: '8/8/8/8/8/8/8/2B5 w - - 0 1',
          goal: CollectStarsGoal(['f4', 'h6', 'e3']),
          text: LocalizedText(
            'الفيل يتحرك قطرياً لأي مسافة. لاحظ أنه يبقى دائماً على مربعات من نفس اللون!',
            'The bishop moves diagonally any distance. Notice it always stays on squares of one colour!',
          ),
        ),
        LessonStep(
          fen: '8/8/5p2/8/3n4/8/8/B7 w - - 0 1',
          goal: CaptureAllGoal(),
          text: LocalizedText(
            'كُل الحصان ثم البيدق باستخدام الفيل.',
            'Use your bishop to capture the knight and then the pawn.',
          ),
        ),
      ],
    ),
    Lesson(
      id: 'queen',
      icon: PieceType.queen,
      title: LocalizedText('الوزير', 'The queen'),
      summary: LocalizedText(
        'أقوى قطعة: قلعة وفيل في قطعة واحدة.',
        'The strongest piece: rook and bishop in one.',
      ),
      steps: [
        LessonStep(
          fen: '8/8/8/8/8/8/8/3Q4 w - - 0 1',
          goal: CollectStarsGoal(['d5', 'h5', 'e8']),
          text: LocalizedText(
            'الوزير يتحرك أفقياً وعمودياً وقطرياً لأي مسافة. اجمع النجوم.',
            'The queen moves horizontally, vertically and diagonally any distance. Collect the stars.',
          ),
        ),
      ],
    ),
    Lesson(
      id: 'knight',
      icon: PieceType.knight,
      title: LocalizedText('الحصان', 'The knight'),
      summary: LocalizedText(
        'يقفز على شكل حرف L فوق القطع.',
        'Jumps in an L shape over other pieces.',
      ),
      steps: [
        LessonStep(
          fen: '8/8/8/8/8/8/8/1N6 w - - 0 1',
          goal: CollectStarsGoal(['c3', 'e4', 'f6']),
          text: LocalizedText(
            'الحصان يتحرك خانتين في اتجاه ثم خانة جانبية (شكل L). اجمع النجوم.',
            'The knight moves two squares one way and one to the side (an L). Collect the stars.',
          ),
        ),
        LessonStep(
          fen: '8/8/8/8/8/2ppp3/2pNp3/2ppp3 w - - 0 1',
          goal: CollectStarsGoal(['e4']),
          text: LocalizedText(
            'الحصان هو القطعة الوحيدة التي تقفز فوق غيرها. اقفز خارج الحصار إلى النجمة.',
            'The knight is the only piece that can jump over others. Jump out to the star.',
          ),
        ),
      ],
    ),
    Lesson(
      id: 'king',
      icon: PieceType.king,
      title: LocalizedText('الملك', 'The king'),
      summary: LocalizedText(
        'أهم قطعة: خطوة واحدة في كل اتجاه.',
        'The most important piece: one step any way.',
      ),
      steps: [
        LessonStep(
          fen: '8/8/8/8/8/8/8/4K3 w - - 0 1',
          goal: CollectStarsGoal(['e2', 'f3', 'g3']),
          text: LocalizedText(
            'الملك يتحرك خانة واحدة في أي اتجاه. اجمع النجوم.',
            'The king moves one square in any direction. Collect the stars.',
          ),
        ),
        LessonStep(
          fen: '4k3/8/8/8/8/8/r7/4K3 w - - 0 1',
          highlights: ['a2', 'b2', 'c2', 'd2', 'e2', 'f2', 'g2', 'h2'],
          text: LocalizedText(
            'لا يجوز للملك أن يدخل مربعاً مهدداً. هنا القلعة السوداء تمنع ملكك من الصعود إلى الصف الثاني.',
            'The king may never step onto an attacked square. Here the black rook stops your king from entering the second rank.',
          ),
        ),
      ],
    ),
    Lesson(
      id: 'values',
      icon: PieceType.queen,
      title: LocalizedText('قيمة القطع', 'Piece values'),
      summary: LocalizedText(
        'لكل قطعة قيمة تساعدك على المقايضة.',
        'Every piece has a value that guides trades.',
      ),
      steps: [
        LessonStep(
          fen: startingFen,
          text: LocalizedText(
            'البيدق = 1، الحصان = 3، الفيل = 3، القلعة = 5، الوزير = 9. الملك لا يُقدَّر بثمن!',
            'Pawn = 1, knight = 3, bishop = 3, rook = 5, queen = 9. The king is priceless!',
          ),
        ),
        LessonStep(
          fen: '4k3/8/2q5/1p3r2/3N4/8/8/4K3 w - - 0 1',
          goal: PlayMoveGoal(['d4c6']),
          text: LocalizedText(
            'حصانك يهاجم ثلاث قطع. كُل القطعة الأغلى!',
            'Your knight attacks three pieces. Capture the most valuable one!',
          ),
        ),
      ],
    ),
    Lesson(
      id: 'check',
      icon: PieceType.king,
      title: LocalizedText('الكش', 'Check'),
      summary: LocalizedText(
        'عندما يُهاجَم الملك يجب إنقاذه فوراً.',
        'When the king is attacked it must be saved at once.',
      ),
      steps: [
        LessonStep(
          fen: '4k3/8/8/8/8/8/8/4R1K1 b - - 0 1',
          highlights: ['e8'],
          text: LocalizedText(
            '«كش» يعني أن الملك مهاجَم. يجب على صاحبه إنقاذه: بتحريكه، أو بوضع قطعة في الطريق، أو بأكل المهاجم.',
            '“Check” means the king is attacked. Its owner must save it: move it, block the attack, or capture the attacker.',
          ),
        ),
        LessonStep(
          fen: '4k3/8/8/8/8/8/4r3/4K3 w - - 0 1',
          goal: CaptureAllGoal(),
          text: LocalizedText(
            'ملكك في كش من القلعة! أنقذه بأكلها.',
            'Your king is in check from the rook! Save it by capturing the rook.',
          ),
        ),
      ],
    ),
    Lesson(
      id: 'checkmate',
      icon: PieceType.queen,
      title: LocalizedText('كش مات', 'Checkmate'),
      summary: LocalizedText(
        'اربح المباراة بمحاصرة الملك.',
        'Win the game by trapping the king.',
      ),
      steps: [
        LessonStep(
          fen: '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1',
          goal: CheckmateGoal(),
          text: LocalizedText(
            'كش مات الصف الأخير: الملك محبوس خلف بيادقه. أنهِ المباراة بنقلة واحدة!',
            'Back-rank mate: the king is trapped behind its own pawns. Finish the game in one move!',
          ),
        ),
        LessonStep(
          fen: '7k/8/5K2/8/8/8/8/6Q1 w - - 0 1',
          goal: CheckmateGoal(),
          text: LocalizedText(
            'الوزير والملك يتعاونان. اكتشف الكش مات في نقلة واحدة.',
            'Queen and king work together. Find checkmate in one move.',
          ),
        ),
        LessonStep(
          fen: '7k/R7/8/8/8/8/8/1R4K1 w - - 0 1',
          goal: CheckmateGoal(),
          text: LocalizedText(
            'سلّم القلعتين: قلعة تحرس الصف السابع والأخرى تضرب. كش مات!',
            'The rook ladder: one rook guards the seventh rank, the other strikes. Checkmate!',
          ),
        ),
      ],
    ),
    Lesson(
      id: 'castling',
      icon: PieceType.rook,
      title: LocalizedText('التبييت', 'Castling'),
      summary: LocalizedText(
        'حركة خاصة تحمي الملك وتُفعّل القلعة.',
        'A special move that tucks the king away.',
      ),
      steps: [
        LessonStep(
          fen: '4k3/8/8/8/8/8/PPPPPPPP/R3K2R w KQ - 0 1',
          goal: SpecialMoveGoal({
            MoveKind.castleKingside,
            MoveKind.castleQueenside,
          }),
          text: LocalizedText(
            'التبييت: يتحرك الملك خانتين نحو القلعة، وتقفز القلعة إلى الجهة الأخرى منه. شروطه: لم يتحرك الملك ولا القلعة، الطريق فارغ، والملك ليس في كش. حرّك الملك خانتين!',
            'Castling: the king moves two squares towards a rook, which jumps to its other side. Neither may have moved, the path must be clear and the king not in check. Move the king two squares!',
          ),
        ),
      ],
    ),
    Lesson(
      id: 'enPassant',
      icon: PieceType.pawn,
      title: LocalizedText('الأكل بالمرور', 'En passant'),
      summary: LocalizedText('أكلة خاصة بالبيادق.', 'A special pawn capture.'),
      steps: [
        LessonStep(
          fen: '4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1',
          highlights: ['d6'],
          goal: SpecialMoveGoal({MoveKind.enPassant}),
          text: LocalizedText(
            'البيدق الأسود تقدّم خانتين ووقف بجانب بيدقك. يمكنك أكله «بالمرور» كأنه تقدّم خانة واحدة فقط — لكن في النقلة التالية مباشرة فقط! كُله الآن.',
            'The black pawn just moved two squares and landed beside yours. You may capture it “in passing” as if it had moved one — only right now! Capture it.',
          ),
        ),
      ],
    ),
    Lesson(
      id: 'promotion',
      icon: PieceType.pawn,
      title: LocalizedText('الترقية', 'Promotion'),
      summary: LocalizedText(
        'البيدق الذي يصل للنهاية يتحول لقطعة قوية.',
        'A pawn that reaches the end transforms.',
      ),
      steps: [
        LessonStep(
          fen: '1k6/5P2/8/8/8/8/8/4K3 w - - 0 1',
          goal: SpecialMoveGoal({}, promotion: true),
          text: LocalizedText(
            'عندما يصل البيدق إلى الصف الأخير يتحول إلى وزير أو قلعة أو فيل أو حصان. رقِّ بيدقك!',
            'When a pawn reaches the last rank it becomes a queen, rook, bishop or knight. Promote your pawn!',
          ),
        ),
      ],
    ),
    Lesson(
      id: 'draws',
      icon: PieceType.bishop,
      title: LocalizedText('التعادل', 'Draws'),
      summary: LocalizedText(
        'متى تنتهي المباراة بلا فائز؟',
        'When does a game end without a winner?',
      ),
      steps: [
        LessonStep(
          fen: '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1',
          highlights: ['h8'],
          text: LocalizedText(
            'الجمود (بات): الدور على الأسود، ملكه ليس في كش لكن لا توجد له أي نقلة قانونية. هذا تعادل! انتبه ألا تجمّد خصمك وأنت متقدم.',
            'Stalemate: Black is to move, the king is not in check, but there is no legal move. It is a draw! Avoid this when you are winning.',
          ),
        ),
        LessonStep(
          fen: '8/8/4k3/8/8/2B5/8/4K3 w - - 0 1',
          text: LocalizedText(
            'تعادل أيضاً عند: تكرار نفس الوضعية 3 مرات، أو 50 نقلة بلا أكل ولا تحريك بيدق، أو عدم كفاية القطع للكش مات (مثل ملك وفيل ضد ملك).',
            'Also a draw: the same position three times, 50 moves without a capture or pawn move, or not enough material to mate (like king and bishop against king).',
          ),
        ),
      ],
    ),
    Lesson(
      id: 'opening',
      icon: PieceType.knight,
      title: LocalizedText('مبادئ الافتتاح', 'Opening principles'),
      summary: LocalizedText(
        'كيف تبدأ المباراة بشكل صحيح.',
        'How to start a game well.',
      ),
      steps: [
        LessonStep(
          fen: startingFen,
          highlights: ['d4', 'e4', 'd5', 'e5'],
          text: LocalizedText(
            'المبادئ الذهبية: 1) سيطر على المركز. 2) أخرج الأحصنة والأفيال. 3) بيّت ملكك مبكراً. 4) لا تُخرج الوزير مبكراً.',
            'Golden rules: 1) control the centre, 2) develop knights and bishops, 3) castle early, 4) do not bring the queen out too soon.',
          ),
        ),
        LessonStep(
          fen: startingFen,
          goal: PlayMoveGoal(['e2e4', 'd2d4']),
          text: LocalizedText(
            'ابدأ بنقلة مركزية قوية: حرّك بيدق e أو بيدق d خطوتين.',
            'Start with a strong central move: push the e- or d-pawn two squares.',
          ),
        ),
        LessonStep(
          fen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
          goal: PlayMoveGoal(['g1f3', 'b1c3', 'f1c4', 'f1b5']),
          text: LocalizedText(
            'الآن طوّر قطعة: أخرج حصاناً أو فيلاً نحو المركز.',
            'Now develop a piece: bring a knight or bishop towards the centre.',
          ),
        ),
      ],
    ),
  ];
}
