import 'package:dio/dio.dart';
import 'package:gruve_app/features/message/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<List<UserEntity>> getUsers({CancelToken? cancelToken});
}
