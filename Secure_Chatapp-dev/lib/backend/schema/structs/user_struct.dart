class UserStruct {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  UserStruct({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  factory UserStruct.fromJson(Map<String, dynamic> json) {
    return UserStruct(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }
} 