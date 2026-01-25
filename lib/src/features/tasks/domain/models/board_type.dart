/// Enumeration of board types
enum BoardType {
  /// Private board visible only to owner
  private,
  
  /// Shared board for collaboration
  shared;

  /// Convert enum to string for storage
  String toJson() => name;

  /// Create enum from string
  static BoardType fromJson(String json) {
    return BoardType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => BoardType.private,
    );
  }
}