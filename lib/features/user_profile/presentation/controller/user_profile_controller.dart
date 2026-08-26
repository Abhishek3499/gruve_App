import 'package:gruve_app/features/profile/presentation/controller/profile_controller.dart';
import 'package:gruve_app/features/user_profile/data/repo/user_profile_repository.dart';

class UserProfileController extends ProfileController {
  UserProfileController({
    required String userId,
    UserProfileRepository? repository,
    super.postService,
  }) : super(repository: repository ?? UserProfileRepository(userId: userId));
}
