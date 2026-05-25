import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'models.dart';

class ChatService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _currentUser;
  UserProfile? _userProfile;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;
  
  // Keep track of active room's typing users
  final Map<String, List<String>> _typingUsers = {};

  User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isAuthenticated => _currentUser != null;

  ChatService() {
    _auth.authStateChanges().listen((user) {
      _currentUser = user;
      if (user != null) {
        _listenToUserProfile(user.uid);
      } else {
        _userProfile = null;
        _profileSubscription?.cancel();
      }
      notifyListeners();
    });
  }

  // --- Auth Operations ---

  Future<void> signInAnonymously(String displayName) async {
    try {
      final credential = await _auth.signInAnonymously();
      final user = credential.user;
      if (user != null) {
        // Create initial user profile
        final colors = ['#FF5722', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#00BCD4', '#4CAF50', '#FFC107'];
        final randomColor = colors[displayName.hashCode % colors.length];
        
        await _db.collection('users').doc(user.uid).set({
          'name': displayName,
          'avatarColorHex': randomColor,
          'themeName': 'Cyberpunk Dusk',
        });
      }
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Error signing in with email: $e');
      rethrow;
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user != null) {
        final colors = ['#FF5722', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#00BCD4', '#4CAF50', '#FFC107'];
        final randomColor = colors[displayName.hashCode % colors.length];

        await _db.collection('users').doc(user.uid).set({
          'name': displayName,
          'avatarColorHex': randomColor,
          'themeName': 'Cyberpunk Dusk',
        });
      }
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (_currentUser != null) {
        // Clear typing status before logging out
        await _clearAllTypingStatus(_currentUser!.uid);
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  void _listenToUserProfile(String uid) {
    _profileSubscription?.cancel();
    _profileSubscription = _db.collection('users').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _userProfile = UserProfile.fromFirestore(snapshot);
      } else {
        // Fallback profile
        _userProfile = UserProfile(id: uid, name: 'Anonymous', avatarColorHex: '#FF5252', themeName: 'Cyberpunk Dusk');
      }
      notifyListeners();
    });
  }

  Future<void> updateUserProfile({String? name, String? avatarColorHex, String? themeName}) async {
    if (_currentUser == null) return;
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (avatarColorHex != null) updates['avatarColorHex'] = avatarColorHex;
      if (themeName != null) updates['themeName'] = themeName;

      await _db.collection('users').doc(_currentUser!.uid).update(updates);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    }
  }

  // --- Rooms Operations ---

  Stream<List<ChatRoom>> getChatRooms() {
    return _db.collection('rooms').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Seed default rooms asynchronously if collection is empty
        _seedDefaultRooms();
      }
      return snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList();
    });
  }

  Future<void> _seedDefaultRooms() async {
    final defaultRooms = [
      ChatRoom(id: 'general', name: 'general', icon: '💬', description: 'The main chat for everyone'),
      ChatRoom(id: 'tech', name: 'tech-talk', icon: '💻', description: 'Discuss code, gadgets, and tech'),
      ChatRoom(id: 'memes', name: 'funny-memes', icon: '😂', description: 'Share laughs and jokes'),
      ChatRoom(id: 'music', name: 'music-lounge', icon: '🎵', description: 'Share your favorite tunes'),
    ];

    for (var room in defaultRooms) {
      await _db.collection('rooms').doc(room.id).set(room.toFirestore());
    }
  }

  Future<void> createRoom(String name, String icon, String description) async {
    final roomId = name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    await _db.collection('rooms').doc(roomId).set({
      'name': name,
      'icon': icon,
      'description': description,
    });
  }

  // --- Messages Operations ---

  Stream<List<ChatMessage>> getMessages(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }

  Future<void> sendMessage({
    required String roomId,
    required String text,
    String? replyToId,
    String? replyToText,
    String? replyToName,
  }) async {
    if (_currentUser == null || _userProfile == null) return;
    
    final message = ChatMessage(
      id: '',
      senderId: _currentUser!.uid,
      senderName: _userProfile!.name,
      text: text,
      timestamp: DateTime.now(),
      reactions: {},
      replyToId: replyToId,
      replyToText: replyToText,
      replyToName: replyToName,
    );

    // Stop typing when message is sent
    setTypingStatus(roomId, false);

    await _db
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .add(message.toFirestore());
  }

  Future<void> toggleReaction(String roomId, String messageId, String emoji) async {
    if (_currentUser == null) return;
    final uid = _currentUser!.uid;

    final docRef = _db
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});

      if (reactions[uid] == emoji) {
        // Remove reaction if user clicked the same emoji again
        reactions.remove(uid);
      } else {
        // Add or change reaction
        reactions[uid] = emoji;
      }

      transaction.update(docRef, {'reactions': reactions});
    });
  }

  // --- Typing Indicator & Online Presence ---

  Future<void> setTypingStatus(String roomId, bool isTyping) async {
    if (_currentUser == null || _userProfile == null) return;
    final uid = _currentUser!.uid;

    final typingDoc = _db
        .collection('rooms')
        .doc(roomId)
        .collection('typing')
        .doc(uid);

    if (isTyping) {
      await typingDoc.set({
        'name': _userProfile!.name,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await typingDoc.delete();
    }
  }

  Stream<List<String>> getTypingUsers(String roomId) {
    if (_currentUser == null) return Stream.value([]);
    final currentUid = _currentUser!.uid;

    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
      final list = <String>[];
      for (var doc in snapshot.docs) {
        if (doc.id != currentUid) {
          final data = doc.data();
          list.add(data['name'] ?? 'Someone');
        }
      }
      return list;
    });
  }

  Future<void> _clearAllTypingStatus(String uid) async {
    try {
      final roomsSnap = await _db.collection('rooms').get();
      for (var roomDoc in roomsSnap.docs) {
        await _db
            .collection('rooms')
            .doc(roomDoc.id)
            .collection('typing')
            .doc(uid)
            .delete();
      }
    } catch (e) {
      debugPrint('Error clearing typing status: $e');
    }
  }
}
