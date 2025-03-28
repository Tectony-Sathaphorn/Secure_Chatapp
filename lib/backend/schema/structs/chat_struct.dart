class ChatStruct {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isGroup;
  final String? groupName;
  final String? groupPhoto;

  ChatStruct({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    this.isGroup = false,
    this.groupName,
    this.groupPhoto,
  });

  factory ChatStruct.fromJson(Map<String, dynamic> json) {
    return ChatStruct(
      id: json['id'] as String,
      participants: List<String>.from(json['participants'] as List),
      lastMessage: json['lastMessage'] as String,
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      isGroup: json['isGroup'] as bool? ?? false,
      groupName: json['groupName'] as String?,
      groupPhoto: json['groupPhoto'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'isGroup': isGroup,
      'groupName': groupName,
      'groupPhoto': groupPhoto,
    };
  }
} 