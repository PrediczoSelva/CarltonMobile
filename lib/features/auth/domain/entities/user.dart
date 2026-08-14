import '../../data/models/user_model.dart';

class UserEntity {
  final int id;
  final String username;
  final String name;
  final String role;
  final DateTime? createdAt;

  UserEntity({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.createdAt,
  });

  factory UserEntity.fromModel(UserModel model) {
    return UserEntity(
      id: model.id,
      username: model.username,
      name: model.name,
      role: model.role,
      createdAt: model.createdAt,
    );
  }

  UserModel toModel() {
    return UserModel(
      id: id,
      username: username,
      name: name,
      role: role,
      createdAt: createdAt,
    );
  }
}