class Chat {
  final String image;
  final String name;
  final String? lastMessage;
  final int lastMessageType;
  final String time;
  final bool hasNewMessage;
  final int newMessageSize;
  final int timestamp;
  final String chatUserId;
  final bool byCurrentUser;

  Chat(
      this.image,
      this.name,
      this.lastMessage,
      this.time,
      this.hasNewMessage,
      this.newMessageSize,
      this.lastMessageType,
      this.timestamp,
      this.chatUserId,
      this.byCurrentUser);
}
