class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://free-chat-api.runasp.net';
  static const String register = '$baseUrl/api/Auth/register';
  static const String login = '$baseUrl/api/Auth/login';
  static const String profile = '$baseUrl/api/Auth/me';
  static const String allUsers = '$baseUrl/api/chat/users';
  static const String sendMessage = '$baseUrl/api/Chat/send';
  static  String markAsRead (int otherUserId) => '$baseUrl/api/Chat/mark-read/$otherUserId';
  static  String getMessage (int otherUserId) => '$baseUrl/api/Chat/conversation/$otherUserId';
  static const String upload = '$baseUrl/api/Chat/upload';
}