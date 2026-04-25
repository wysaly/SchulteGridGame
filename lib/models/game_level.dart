enum GameType {
  number, // 数字（2×2 ~ 6×6）
  poem, // 古诗词（五言律诗 3×4 或 七言律诗 4×4）
  sentence, // 25字句子（5×5）
  numberFlipped, // 翻转数字（5×5、6×6）
}

class GameLevel {
  final int id; // 1-10
  final String name; // 关卡名称
  final GameType type; // 游戏类型
  final int gridSize; // 网格大小（2-6）
  final bool isFlipped; // 是否翻转
  final String? description; // 描述
  final int standardTime; // 标准时间（秒）

  GameLevel({
    required this.id,
    required this.name,
    required this.type,
    required this.gridSize,
    this.isFlipped = false,
    this.description,
    required this.standardTime,
  });
}

// 定义10个关卡（按难度递增排序，id越大难度越大）
final List<GameLevel> allLevels = [
  GameLevel(
    id: 1,
    name: '关卡1：2×2数字',
    type: GameType.number,
    gridSize: 2,
    standardTime: 1,
    description: '4个数字',
  ),
  GameLevel(
    id: 2,
    name: '关卡2：3×3数字',
    type: GameType.number,
    gridSize: 3,
    standardTime: 4,
    description: '9个数字',
  ),
  GameLevel(
    id: 3,
    name: '关卡3：4×4数字',
    type: GameType.number,
    gridSize: 4,
    standardTime: 7,
    description: '16个数字',
  ),
  GameLevel(
    id: 4,
    name: '关卡4：3×4古诗',
    type: GameType.poem,
    gridSize: 3,
    standardTime: 11,
    description: '五言律诗',
  ),
  GameLevel(
    id: 5,
    name: '关卡5：4×4古诗',
    type: GameType.poem,
    gridSize: 4,
    standardTime: 13,
    description: '七言律诗',
  ),
  GameLevel(
    id: 6,
    name: '关卡6：5×5数字',
    type: GameType.number,
    gridSize: 5,
    standardTime: 16,
    description: '25个数字',
  ),
  GameLevel(
    id: 7,
    name: '关卡7：5×5翻转数字',
    type: GameType.numberFlipped,
    gridSize: 5,
    isFlipped: true,
    standardTime: 26,
    description: '翻转的数字',
  ),
  GameLevel(
    id: 8,
    name: '关卡8：5×5句子',
    type: GameType.sentence,
    gridSize: 5,
    standardTime: 33,
    description: '25字句子',
  ),
  GameLevel(
    id: 9,
    name: '关卡9：6×6数字',
    type: GameType.number,
    gridSize: 6,
    standardTime: 41,
    description: '36个数字',
  ),
  GameLevel(
    id: 10,
    name: '关卡10：6×6翻转数字',
    type: GameType.numberFlipped,
    gridSize: 6,
    isFlipped: true,
    standardTime: 55,
    description: '翻转的数字',
  ),
];
