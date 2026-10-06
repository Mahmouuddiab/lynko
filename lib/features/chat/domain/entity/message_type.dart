enum MessageType {
  text(0), image(1), video(2), voice(3), location(4), file(5);

  const MessageType(this.value);
  final int value;

  static MessageType fromValue(int v) =>
      MessageType.values.firstWhere((e) => e.value == v, orElse: () => MessageType.text);
}