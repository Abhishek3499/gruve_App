import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:gruve_app/features/message/models/message_model.dart';

class SharePostProvider extends ChangeNotifier {
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isVideoInitialized = false;
  bool _isSharing = false;
  bool _isSavingDraft = false;

  List<ChatUser> _taggedUsers = [];
  bool _isEveryone = true;
  bool _isCloseFriends = false;
  bool _scheduleReel = false;
  bool _uploadHighQuality = false;
  bool _hideLikeCount = false;
  bool _hideShareCount = false;
  String? _locationName;

  // Getters
  VideoPlayerController? get videoController => _videoController;
  bool get isVideo => _isVideo;
  bool get isVideoInitialized => _isVideoInitialized;
  bool get isSharing => _isSharing;
  bool get isSavingDraft => _isSavingDraft;
  List<ChatUser> get taggedUsers => _taggedUsers;
  bool get isEveryone => _isEveryone;
  bool get isCloseFriends => _isCloseFriends;
  bool get scheduleReel => _scheduleReel;
  bool get uploadHighQuality => _uploadHighQuality;
  bool get hideLikeCount => _hideLikeCount;
  bool get hideShareCount => _hideShareCount;
  String? get locationName => _locationName;

  // Setters with notifyListeners
  void setVideoController(VideoPlayerController? controller) {
    _videoController = controller;
    notifyListeners();
  }

  void setIsVideo(bool value) {
    _isVideo = value;
    notifyListeners();
  }

  void setIsVideoInitialized(bool value) {
    _isVideoInitialized = value;
    notifyListeners();
  }

  void setIsSharing(bool value) {
    _isSharing = value;
    notifyListeners();
  }

  void setIsSavingDraft(bool value) {
    _isSavingDraft = value;
    notifyListeners();
  }

  void setTaggedUsers(List<ChatUser> users) {
    _taggedUsers = users;
    notifyListeners();
  }

  void setIsEveryone(bool value) {
    _isEveryone = value;
    notifyListeners();
  }

  void setIsCloseFriends(bool value) {
    _isCloseFriends = value;
    notifyListeners();
  }

  void setScheduleReel(bool value) {
    _scheduleReel = value;
    notifyListeners();
  }

  void setUploadHighQuality(bool value) {
    _uploadHighQuality = value;
    notifyListeners();
  }

  void setHideLikeCount(bool value) {
    _hideLikeCount = value;
    notifyListeners();
  }

  void setHideShareCount(bool value) {
    _hideShareCount = value;
    notifyListeners();
  }

  void setLocationName(String? value) {
    _locationName = value;
    notifyListeners();
  }

  void updateAudience(bool isEveryone, bool isCloseFriends) {
    _isEveryone = isEveryone;
    _isCloseFriends = isCloseFriends;
    notifyListeners();
  }

  void updateMoreOptions({
    required bool scheduleReel,
    required bool uploadHighQuality,
    required bool hideLikeCount,
    required bool hideShareCount,
  }) {
    _scheduleReel = scheduleReel;
    _uploadHighQuality = uploadHighQuality;
    _hideLikeCount = hideLikeCount;
    _hideShareCount = hideShareCount;
    notifyListeners();
  }

  void toggleVideoPlayPause() {
    if (_videoController == null) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    notifyListeners();
  }

  void initializeFromWidget({
    required bool? initialIsEveryone,
    required bool? initialIsCloseFriends,
    required bool? initialScheduleReel,
    required bool? initialUploadHighQuality,
    required bool? initialHideLikeCount,
    required bool? initialHideShareCount,
    required String? initialLocation,
    required List<ChatUser>? initialTaggedUsers,
  }) {
    _isEveryone = initialIsEveryone ?? true;
    _isCloseFriends = initialIsCloseFriends ?? false;
    _scheduleReel = initialScheduleReel ?? false;
    _uploadHighQuality = initialUploadHighQuality ?? false;
    _hideLikeCount = initialHideLikeCount ?? false;
    _hideShareCount = initialHideShareCount ?? false;
    _locationName = initialLocation;
    if (initialTaggedUsers != null) {
      _taggedUsers = List.from(initialTaggedUsers);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
