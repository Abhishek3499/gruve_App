import 'package:gruve_app/core/assets.dart';

import '../models/search_history_model.dart';

class DummySearchHistory {
  static List<SearchHistoryModel> getDummyHistory() {
    return [
      SearchHistoryModel(
        id: "1",
        query: "Carla_choen",
        subtitle: "Fashion",
        type: SearchType.user,
        avatar: AppAssets.blocked9,
      ),
      SearchHistoryModel(
        id: "2",
        query: "Carla_choen",
        subtitle: "Fashion",
        type: SearchType.hashtag,
      ),
      SearchHistoryModel(
        id: "3",
        query: "Aria Nova",
        subtitle: "12M Post",
        type: SearchType.music,
      ),
    ];
  }
}
