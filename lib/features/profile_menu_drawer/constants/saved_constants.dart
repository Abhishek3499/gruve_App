import '../models/saved_model.dart';
import '../../../core/assets.dart';

class SavedConstants {
  static const List<SavedModel> categories = [
    SavedModel(
      title: "All posts",
      images: [
        AppAssets.saved1,
        AppAssets.saved2,
        AppAssets.saved5,
        AppAssets.saved3,
        AppAssets.saved4,
      ],
    ),
    // SavedModel(
    //   title: "Audio",
    //   images: [
    //     AppAssets.saved1,
    //     AppAssets.saved2,
    //     AppAssets.saved5,
    //     AppAssets.saved3,
    //   ],
    // ),
  ];
}
