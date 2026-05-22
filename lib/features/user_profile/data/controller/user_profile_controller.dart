import 'package:gruve_app/features/profile/data/api_calls/controller/profile_controller.dart';
import 'package:gruve_app/features/user_profile/data/repository/user_profile_repository.dart';

class UserProfileController extends ProfileController {
  UserProfileController({
    required String userId,
    UserProfileRepository? repository,
    super.postService,
  }) : super(repository: repository ?? UserProfileRepository(userId: userId));
}
