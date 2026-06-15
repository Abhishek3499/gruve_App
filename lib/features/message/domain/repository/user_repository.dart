import 'package:dio/dio.dart';
import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<List<UserEntity>> getUsers({CancelToken? cancelToken});
}
