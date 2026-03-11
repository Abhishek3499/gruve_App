import '../models/message_model.dart';

class DummySearchUsers {
  static List<ChatUser> getSearchUsers() {
    return [
      ChatUser(
        id: '1',
        name: 'Skyler Johnson',
        avatar: 'assets/search_screen_images/profile.png',
        lastMessage: 'Hey! How are you doing?',
        lastMessageTime: '2 min ago',
        unreadCount: 0,
      ),
      ChatUser(
        id: '2',
        name: 'Emma Watson',
        avatar: 'assets/notification_images/Profiles (1).png',
        lastMessage: 'Did you see the latest updates?',
        lastMessageTime: '5 min ago',
        unreadCount: 2,
      ),
      ChatUser(
        id: '3',
        name: 'Michael Carter',
        avatar: 'assets/notification_images/Oval.png',
        lastMessage: 'Let\'s catch up tomorrow',
        lastMessageTime: '10 min ago',
        unreadCount: 1,
      ),
      ChatUser(
        id: '4',
        name: 'Sophia Williams',
        avatar: 'assets/notification_images/ovalk.png',
        lastMessage: 'Thanks for the help!',
        lastMessageTime: '15 min ago',
        unreadCount: 0,
      ),
      ChatUser(
        id: '5',
        name: 'Daniel Brown',
        avatar: 'assets/notification_images/Rectangle.png',
        lastMessage: 'Meeting at 3pm today',
        lastMessageTime: '30 min ago',
        unreadCount: 3,
      ),
      ChatUser(
        id: '6',
        name: 'Olivia Davis',
        avatar: 'assets/search_screen_images/profile.png',
        lastMessage: 'Great work on the project!',
        lastMessageTime: '1 hr ago',
        unreadCount: 1,
      ),
      ChatUser(
        id: '7',
        name: 'James Miller',
        avatar: 'assets/notification_images/Profiles (1).png',
        lastMessage: 'Can you review this?',
        lastMessageTime: '2 hr ago',
        unreadCount: 0,
      ),
      ChatUser(
        id: '8',
        name: 'Lisa Anderson',
        avatar: 'assets/notification_images/Oval.png',
        lastMessage: 'See you at the conference',
        lastMessageTime: '3 hr ago',
        unreadCount: 2,
      ),
    ];
  }
}
