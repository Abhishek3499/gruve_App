class UserModel {
  final String id;
  final String username;
  final String handle;
  final String bio;
  final String profileImage;
  final int followers;
  final int likes;
  final int videos;
  final List<String> stories;
  final List<String> gridPhotos;
  final bool isCurrentUser;
  final bool isSubscribed;

  const UserModel({
    required this.id,
    required this.username,
    required this.handle,
    required this.bio,
    required this.profileImage,
    required this.followers,
    required this.likes,
    required this.videos,
    required this.stories,
    required this.gridPhotos,
    this.isCurrentUser = false,
    this.isSubscribed = false,
  });

  // Factory constructor for current user
  factory UserModel.currentUser() {
    return const UserModel(
      id: 'current_user',
      username: 'Anastasia Adams',
      handle: '@nastasia__',
      bio: 'Content Creator | Digital Artist',
      profileImage: 'assets/images/profile.png',
      followers: 1615,
      likes: 12412,
      videos: 300,
      stories: ['assets/images/frame1.png', 'assets/images/frame2.png', 'assets/images/frame3.png'],
      gridPhotos: [
        'assets/images/frame1.png',
        'assets/images/frame2.png',
        'assets/images/frame3.png',
        'assets/images/frame1.png',
        'assets/images/frame2.png',
        'assets/images/frame3.png',
      ],
      isCurrentUser: true,
      isSubscribed: false, // Can't subscribe to yourself
    );
  }

  // Factory constructor for other users
  factory UserModel.otherUser(String userId) {
    final users = {
      'user_001': const UserModel(
        id: 'user_001',
        username: 'John Doe',
        handle: '@johndoe',
        bio: 'Photographer | Travel Enthusiast',
        profileImage: 'assets/users/user_001/profile.png',
        followers: 2500,
        likes: 45000,
        videos: 120,
        stories: [
          'assets/users/user_001/story1.png',
          'assets/users/user_001/story2.png',
        ],
        gridPhotos: [
          'assets/users/user_001/photo1.png',
          'assets/users/user_001/photo2.png',
          'assets/users/user_001/photo3.png',
          'assets/users/user_001/photo4.png',
          'assets/users/user_001/photo5.png',
          'assets/users/user_001/photo6.png',
        ],
        isCurrentUser: false,
        isSubscribed: false,
      ),
      'user_002': const UserModel(
        id: 'user_002',
        username: 'Jane Smith',
        handle: '@janesmith',
        bio: 'Fitness Coach | Nutrition Expert',
        profileImage: 'assets/users/user_002/profile.png',
        followers: 5200,
        likes: 89000,
        videos: 250,
        stories: [
          'assets/users/user_002/story1.png',
          'assets/users/user_002/story2.png',
        ],
        gridPhotos: [
          'assets/users/user_002/photo1.png',
          'assets/users/user_002/photo2.png',
          'assets/users/user_002/photo3.png',
          'assets/users/user_002/photo4.png',
          'assets/users/user_002/photo5.png',
          'assets/users/user_002/photo6.png',
        ],
        isCurrentUser: false,
        isSubscribed: true, // Already subscribed to this user
      ),
      'user_003': const UserModel(
        id: 'user_003',
        username: 'Mike Wilson',
        handle: '@mikewilson',
        bio: 'Music Producer | DJ',
        profileImage: 'assets/users/user_003/profile.png',
        followers: 8900,
        likes: 156000,
        videos: 180,
        stories: [
          'assets/users/user_003/story1.png',
          'assets/users/user_003/story2.png',
          'assets/users/user_003/story3.png',
        ],
        gridPhotos: [
          'assets/users/user_003/music1.png',
          'assets/users/user_003/music2.png',
          'assets/users/user_003/music3.png',
          'assets/users/user_003/music4.png',
          'assets/users/user_003/music5.png',
          'assets/users/user_003/music6.png',
        ],
        isCurrentUser: false,
        isSubscribed: false,
      ),
    };

    return users[userId] ?? UserModel.currentUser();
  }

  // Copy with method for updates
  UserModel copyWith({
    String? id,
    String? username,
    String? handle,
    String? bio,
    String? profileImage,
    int? followers,
    int? likes,
    int? videos,
    List<String>? stories,
    List<String>? gridPhotos,
    bool? isCurrentUser,
    bool? isSubscribed,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      handle: handle ?? this.handle,
      bio: bio ?? this.bio,
      profileImage: profileImage ?? this.profileImage,
      followers: followers ?? this.followers,
      likes: likes ?? this.likes,
      videos: videos ?? this.videos,
      stories: stories ?? this.stories,
      gridPhotos: gridPhotos ?? this.gridPhotos,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, handle: $handle, isCurrentUser: $isCurrentUser)';
  }
}
