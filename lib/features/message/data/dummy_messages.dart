import '../models/message_model.dart';

class DummyMessages {
  static List<ChatUser> getChatUsers() {
    return [
      ChatUser(
        id: '1',
        name: 'Emma Watson',
        avatar: 'assets/images/profile.png',
        lastMessage:
            'Did you check the design updates?iadhusagefdsuhsadgfhadgfhadgfhadgfhagdafhadfahadffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
        lastMessageTime: '5 min ago',
        unreadCount: 2,
      ),
      ChatUser(
        id: '2',
        name: 'Michael Carter',
        avatar: 'assets/images/profile.png',
        lastMessage: 'Let\'s catch up in the evening.',
        lastMessageTime: '12 min ago',
        unreadCount: 1,
      ),
      ChatUser(
        id: '3',
        name: 'Sophia Williams',
        avatar: 'assets/images/profile.png',
        lastMessage: 'I have shared the documents.',
        lastMessageTime: '25 min ago',
        unreadCount: 4,
      ),
      ChatUser(
        id: '4',
        name: 'Daniel Brown',
        avatar: 'assets/images/profile.png',
        lastMessage: 'Call me when you\'re free.',
        lastMessageTime: '40 min ago',
        unreadCount: 0,
      ),
      ChatUser(
        id: '5',
        name: 'Olivia Johnson',
        avatar: 'assets/images/profile.png',
        lastMessage: 'Meeting is confirmed for tomorrow.',
        lastMessageTime: '1 hr ago',
        unreadCount: 3,
      ),
    ];
  }

  static List<MessageModel> getChatMessages(String userId) {
    // Return different messages based on user ID
    switch (userId) {
      case '1':
        return [
          MessageModel(
            id: '1',
            text: 'Hey! How are you doing?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
            isSent: false,
            senderId: '1',
            replyTo: null,
            isPinned: false,
          ),
          MessageModel(
            id: '2',
            text: 'I\'m good! Just working on the design updates.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
            isSent: true,
            senderId: 'me',
            replyTo: null,
            isPinned: false,
          ),
          MessageModel(
            id: '3',
            text: 'Did you check the design updates?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            isSent: false,
            senderId: '1',
            replyTo: null,
            isPinned: false,
          ),
        ];
      case '2':
        return [
          MessageModel(
            id: '1',
            text: 'Let\'s catch up in the evening.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
            isSent: false,
            senderId: '2',
            replyTo: null,
            isPinned: false,
          ),
        ];
      case '3':
        return [
          MessageModel(
            id: '1',
            text: 'I have shared the documents.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
            isSent: false,
            senderId: '3',
            replyTo: null,
            isPinned: false,
          ),
        ];
      default:
        return [
          MessageModel(
            id: '1',
            text: 'Hello! How can I help you today?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
            isSent: false,
            senderId: userId,
            replyTo: null,
            isPinned: false,
          ),
        ];
    }
  }
}
