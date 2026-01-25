import 'package:equatable/equatable.dart';
import 'board_type.dart';
import 'board_settings.dart';

/// Request model for creating a new board
class CreateBoardRequest extends Equatable {
  const CreateBoardRequest({
    required this.name,
    this.description,
    required this.type,
    required this.ownerId,
    this.settings,
  });

  final String name;
  final String? description;
  final BoardType type;
  final String ownerId;
  final BoardSettings? settings;

  @override
  List<Object?> get props => [name, description, type, ownerId, settings];
}