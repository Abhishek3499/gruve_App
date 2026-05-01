import 'package:gruve_app/api_calls/profile/controller/profile_controller.dart';
import 'package:gruve_app/api_calls/user_profile/repository/user_profile_repository.dart';

class UserProfileController extends ProfileController {
  UserProfileController({
    required String userId,
    UserProfileRepository? repository,
    super.postService,
  }) : super(repository: repository ?? UserProfileRepository(userId: userId));
}
