import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final Map<String, String> reactions; // userId -> emoji
  final String? replyToId;
  final String? replyToText;
  final String? replyToName;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.reactions,
    this.replyToId,
    this.replyToText,
    this.replyToName,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse timestamp safely
    DateTime parsedTime = DateTime.now();
    if (data['timestamp'] != null) {
      if (data['timestamp'] is Timestamp) {
        parsedTime = (data['timestamp'] as Timestamp).toDate();
      } else if (data['timestamp'] is int) {
        parsedTime = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
      }
    }

    // Parse reactions safely
    Map<String, String> parsedReactions = {};
    if (data['reactions'] != null && data['reactions'] is Map) {
      (data['reactions'] as Map).forEach((key, value) {
        parsedReactions[key.toString()] = value.toString();
      });
    }

    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Anonymous',
      text: data['text'] ?? '',
      timestamp: parsedTime,
      reactions: parsedReactions,
      replyToId: data['replyToId'],
      replyToText: data['replyToText'],
      replyToName: data['replyToName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'reactions': reactions,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToName != null) 'replyToName': replyToName,
    };
  }
}

class ChatRoom {
  final String id;
  final String name;
  final String icon;
  final String description;

  ChatRoom({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '💬',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'description': description,
    };
  }
}

class UserProfile {
  final String id;
  final String name;
  final String avatarColorHex;
  final String themeName;

  UserProfile({
    required this.id,
    required this.name,
    required this.avatarColorHex,
    required this.themeName,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      name: data['name'] ?? 'User',
      avatarColorHex: data['avatarColorHex'] ?? '#FF5252',
      themeName: data['themeName'] ?? 'Cyberpunk Dusk',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'avatarColorHex': avatarColorHex,
      'themeName': themeName,
    };
  }
}
