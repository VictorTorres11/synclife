import 'package:equatable/equatable.dart';

/// Request model for creating a new inbox item
class CreateInboxItemRequest extends Equatable {
  const CreateInboxItemRequest({
    required this.content,
    required this.userId,
  });

  final String content;
  final String userId;

  @override
  List<Object?> get props => [content, userId];
}