import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'chat_service.dart';
import 'theme_provider.dart';
import 'models.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final _roomNameController = TextEditingController();
  final _roomDescController = TextEditingController();
  
  String _activeRoomId = 'general';
  String _activeRoomName = 'general';
  String _activeRoomIcon = '💬';
  String _activeRoomDesc = 'The main chat for everyone';

  // State for replying
  ChatMessage? _replyingTo;

  // State for searching messages
  String _searchQuery = '';
  bool _isSearching = false;

  // Typing status management
  bool _isTyping = false;
  DateTime? _lastTypingTime;

  // Image upload loading state
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _roomNameController.dispose();
    _roomDescController.dispose();
    super.dispose();
  }

  void _onTypingChanged(String text) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    if (text.isEmpty) {
      if (_isTyping) {
        setState(() => _isTyping = false);
        chatService.setTypingStatus(_activeRoomId, false);
      }
    } else {
      if (!_isTyping) {
        setState(() => _isTyping = true);
        chatService.setTypingStatus(_activeRoomId, true);
      }
      _lastTypingTime = DateTime.now();
      Future.delayed(const Duration(seconds: 4), () {
        if (_lastTypingTime != null && 
            DateTime.now().difference(_lastTypingTime!) >= const Duration(seconds: 4) && 
            _isTyping) {
          setState(() => _isTyping = false);
          chatService.setTypingStatus(_activeRoomId, false);
        }
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.sendMessage(
      roomId: _activeRoomId,
      text: text,
      replyToId: _replyingTo?.id,
      replyToText: _replyingTo?.text,
      replyToName: _replyingTo?.senderName,
    );

    _messageController.clear();
    setState(() {
      _isTyping = false;
      _replyingTo = null;
    });
  }

  Future<void> _pickAndUploadImage() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    try {
      // Direct call to FilePicker.pickFiles static method in v11.x
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true, // Crucial for Flutter Web to get file bytes!
      );

      if (result != null && result.files.first.bytes != null) {
        final file = result.files.first;
        
        // Size warning for large files > 10MB
        if (file.size > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading large image. This might take a few moments...'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        setState(() => _isUploadingImage = true);

        // Upload to Firebase Storage with a 25-second timeout
        final imageUrl = await chatService.uploadChatImage(
          _activeRoomId,
          file.name,
          file.bytes!,
        ).timeout(const Duration(seconds: 25), onTimeout: () {
          throw TimeoutException(
            'Upload timed out. Please check your Firebase Storage Rules, CORS configurations, and internet connection.'
          );
        });

        // Send the image message
        await chatService.sendMessage(
          roomId: _activeRoomId,
          text: '[Sent an image]',
          imageUrl: imageUrl,
          replyToId: _replyingTo?.id,
          replyToText: _replyingTo?.text,
          replyToName: _replyingTo?.senderName,
        );

        setState(() {
          _isUploadingImage = false;
          _replyingTo = null;
        });
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _parseHexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final chatService = Provider.of<ChatService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Responsive split (Sidebar width is 300 on large screens, or switches to drawer on narrow ones)
    final isDesktop = size.width > 760;

    Widget sidebar = _buildSidebar(context, chatService, themeProvider, theme, isDesktop);
    Widget chatArea = _buildChatArea(context, chatService, theme);

    return Scaffold(
      drawer: isDesktop ? null : Drawer(child: sidebar),
      body: Row(
        children: [
          if (isDesktop) ...[
            SizedBox(
              width: 300,
              child: sidebar,
            ),
            VerticalDivider(width: 1, color: theme.dividerColor.withOpacity(0.5)),
          ],
          Expanded(child: chatArea),
        ],
      ),
    );
  }

  // --- Sidebar Widget ---
  Widget _buildSidebar(
    BuildContext context, 
    ChatService chatService, 
    ThemeProvider themeProvider, 
    ThemeData theme,
    bool isDesktop
  ) {
    final userProfile = chatService.userProfile;

    return Container(
      color: theme.scaffoldBackgroundColor.withBlue(15),
      child: Column(
        children: [
          // Sidebar Branding Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                const Text('💬', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat Memo',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Active Node',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 11,
                              color: Colors.greenAccent.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),

          // Rooms Title / Create Button
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 12, top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CHAT ROOMS',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, size: 20, color: theme.colorScheme.secondary),
                  tooltip: 'Create New Room',
                  onPressed: () => _showCreateRoomDialog(context, chatService),
                ),
              ],
            ),
          ),

          // Streams of Rooms
          Expanded(
            child: StreamBuilder<List<ChatRoom>>(
              stream: chatService.getChatRooms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No rooms available'));
                }

                final rooms = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final isSelected = room.id == _activeRoomId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: InkWell(
                        onTap: () {
                          // Clear typing status on room change
                          chatService.setTypingStatus(_activeRoomId, false);
                          setState(() {
                            _activeRoomId = room.id;
                            _activeRoomName = room.name;
                            _activeRoomIcon = room.icon;
                            _activeRoomDesc = room.description;
                            _replyingTo = null;
                            _searchQuery = '';
                            _isSearching = false;
                            _searchController.clear();
                          });
                          if (!isDesktop) Navigator.pop(context); // close drawer on mobile
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? theme.colorScheme.primary.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? theme.colorScheme.primary.withOpacity(0.3)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(room.icon, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '# ${room.name}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    if (room.description.isNotEmpty) ...[
                                      Text(
                                        room.description,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface.withOpacity(isSelected ? 0.5 : 0.4),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),

          // User Profile Card / Theme settings
          if (userProfile != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.2),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () => _showProfileCustomizer(context, chatService, themeProvider, theme),
                    child: Tooltip(
                      message: 'Customize Profile',
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _parseHexColor(userProfile.avatarColorHex),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            userProfile.name.isNotEmpty ? userProfile.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userProfile.themeName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.secondary.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions (Settings & Logout)
                  IconButton(
                    icon: Icon(Icons.settings_outlined, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    onPressed: () => _showProfileCustomizer(context, chatService, themeProvider, theme),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
                    onPressed: () => chatService.signOut(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Main Chat Area ---
  Widget _buildChatArea(BuildContext context, ChatService chatService, ThemeData theme) {
    final size = MediaQuery.of(context).size;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withBlue(8),
              border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                if (size.width <= 760) ...[
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(_activeRoomIcon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '# $_activeRoomName',
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        _activeRoomDesc,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Search Trigger Icon
                if (!_isSearching) ...[
                  IconButton(
                    icon: Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    onPressed: () => setState(() => _isSearching = true),
                  ),
                ] else ...[
                  Container(
                    width: 200,
                    height: 38,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search messages...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _isSearching = false;
                              _searchController.clear();
                            });
                          },
                        ),
                      ),
                      onChanged: (text) {
                        setState(() {
                          _searchQuery = text.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Messages View
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: chatService.getMessages(_activeRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _activeRoomIcon,
                          style: const TextStyle(fontSize: 50),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome to #$_activeRoomName!',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This is the very beginning of the channel history.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter messages based on search query
                var messages = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  messages = messages
                      .where((m) => m.text.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == chatService.currentUser?.uid;
                    
                    return _buildMessageBubble(context, message, isMe, chatService, theme);
                  },
                );
              },
            ),
          ),

          // Typing Indicator Display
          StreamBuilder<List<String>>(
            stream: chatService.getTypingUsers(_activeRoomId),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              final typingList = snapshot.data!;
              String typingText = typingList.length == 1 
                  ? '${typingList[0]} is typing...' 
                  : '${typingList.join(', ')} are typing...';

              return Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(Colors.white54)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      typingText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Replying Reference Bar
          if (_replyingTo != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.12),
                border: Border(top: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.3))),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to ${_replyingTo!.senderName}: "${_replyingTo!.text}"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),
          ],

          // Message Input Composer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withBlue(5),
              border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.3))),
            ),
            child: Row(
              children: [
                // Image Picking Button
                IconButton(
                  icon: _isUploadingImage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white70)),
                        )
                      : Icon(Icons.image_outlined, color: theme.colorScheme.secondary),
                  tooltip: 'Attach Image',
                  onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _onTypingChanged,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Message #$_activeRoomName...',
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.3)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Send Button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Message Bubble Builder ---
  Widget _buildMessageBubble(
    BuildContext context, 
    ChatMessage message, 
    bool isMe, 
    ChatService chatService, 
    ThemeData theme
  ) {
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name & Time
            Padding(
              padding: const EdgeInsets.only(left: 6, right: 6, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe) ...[
                    Text(
                      message.senderName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    timeStr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),

            // Reference Reply header if message is a reply
            if (message.replyToId != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.reply, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Text(
                      '${message.replyToName}: "${message.replyToText}"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],

            // Message content card + Actions trigger on long-press or hover
            GestureDetector(
              onLongPress: () => _showMessageActionsMenu(context, message, chatService, theme),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMe 
                        ? [theme.colorScheme.primary, theme.colorScheme.primary.withRed(220)]
                        : [theme.cardColor, theme.cardColor.withBlue(10)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(2),
                    bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Render Image if present
                    if (message.imageUrl != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            message.imageUrl!,
                            width: 320,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 320,
                                height: 180,
                                color: Colors.black.withOpacity(0.15),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.black12,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                                    SizedBox(width: 6),
                                    Text('Error loading image', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    // Render Text if it's not the default image fallback, or has user text
                    if (message.imageUrl == null || message.text != '[Sent an image]') ...[
                      Text(
                        message.text,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isMe ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Emoji Reactions capsules
            if (message.reactions.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildReactionsRow(context, message, chatService, theme),
            ],
            
            // Hover trigger indicator for quick action
            const SizedBox(height: 2),
            GestureDetector(
              onTap: () => _showMessageActionsMenu(context, message, chatService, theme),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'React / Reply',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.secondary.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reactions Row Capsule ---
  Widget _buildReactionsRow(
    BuildContext context, 
    ChatMessage message, 
    ChatService chatService, 
    ThemeData theme
  ) {
    // Group identical emojis
    final grouped = <String, List<String>>{}; // emoji -> list of userIds
    message.reactions.forEach((uid, emoji) {
      grouped.putIfAbsent(emoji, () => []).add(uid);
    });

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: grouped.entries.map((entry) {
        final emoji = entry.key;
        final userList = entry.value;
        final hasReacted = userList.contains(chatService.currentUser?.uid);

        return GestureDetector(
          onTap: () => chatService.toggleReaction(_activeRoomId, message.id, emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasReacted 
                  ? theme.colorScheme.secondary.withOpacity(0.2)
                  : theme.dividerColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasReacted 
                    ? theme.colorScheme.secondary.withOpacity(0.6) 
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '${userList.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: hasReacted ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Message Action sheet (Reply, React) ---
  void _showMessageActionsMenu(
    BuildContext context, 
    ChatMessage message, 
    ChatService chatService, 
    ThemeData theme
  ) {
    final emojis = ['👍', '❤️', '😂', '🔥', '😮', '👏', '🎉', '😢'];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick emoji reaction bar
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: emojis.map((emoji) {
                      final hasReacted = message.reactions[chatService.currentUser?.uid] == emoji;

                      return GestureDetector(
                        onTap: () {
                          chatService.toggleReaction(_activeRoomId, message.id, emoji);
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasReacted ? theme.colorScheme.primary.withOpacity(0.2) : Colors.transparent,
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const Divider(),

                // Reply trigger
                ListTile(
                  leading: const Icon(Icons.reply),
                  title: const Text('Reply to message'),
                  subtitle: Text(message.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    setState(() {
                      _replyingTo = message;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Room Creator Dialog ---
  void _showCreateRoomDialog(BuildContext context, ChatService chatService) {
    _roomNameController.clear();
    _roomDescController.clear();
    final _dialogFormKey = GlobalKey<FormState>();
    String selectedIcon = '💬';
    final iconsList = ['💬', '💻', '😂', '🎵', '🎮', '🚀', '🎨', '🔥', '📚'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);

            return AlertDialog(
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Create New Channel', style: TextStyle(color: Colors.white)),
              content: Form(
                key: _dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: iconsList.map((icon) {
                        final isSelected = icon == selectedIcon;

                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Text(icon, style: const TextStyle(fontSize: 20)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Room name
                    TextFormField(
                      controller: _roomNameController,
                      decoration: const InputDecoration(
                        labelText: 'Channel Name',
                        hintText: 'e.g. general, gaming-hub',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter a channel name';
                        if (val.trim().contains(' ')) return 'No spaces allowed. Use hyphens.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Room desc
                    TextFormField(
                      controller: _roomDescController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What is this channel about?',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!_dialogFormKey.currentState!.validate()) return;
                    await chatService.createRoom(
                      _roomNameController.text.trim().toLowerCase(),
                      selectedIcon,
                      _roomDescController.text.trim(),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Profile Customizer Settings Sheet ---
  void _showProfileCustomizer(
    BuildContext context, 
    ChatService chatService, 
    ThemeProvider themeProvider, 
    ThemeData theme
  ) {
    final user = chatService.userProfile;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.name);
    String activeColorHex = user.avatarColorHex;
    String activeTheme = themeProvider.activeThemeName;

    final avatarColors = ['#FF5722', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#00BCD4', '#4CAF50', '#FFC107'];
    final themesList = ['Cyberpunk Dusk', 'Emerald Forest', 'Sunset Ember', 'Midnight Stealth'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dialogTheme = Theme.of(context);

            return AlertDialog(
              backgroundColor: dialogTheme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Customize Profile & Workspace', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display Name Field
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Avatar Color Pick
                    const Text('Choose Avatar Glow Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: avatarColors.map((colorHex) {
                        final color = _parseHexColor(colorHex);
                        final isSelected = colorHex == activeColorHex;

                        return GestureDetector(
                          onTap: () => setDialogState(() => activeColorHex = colorHex),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Active UI theme selector
                    const Text('Choose Workspace Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                    const SizedBox(height: 10),
                    Column(
                      children: themesList.map((themeName) {
                        return RadioListTile<String>(
                          title: Text(themeName, style: const TextStyle(fontSize: 14)),
                          value: themeName,
                          groupValue: activeTheme,
                          activeColor: dialogTheme.colorScheme.secondary,
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => activeTheme = val);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final trimmedName = nameCtrl.text.trim();
                    if (trimmedName.isNotEmpty) {
                      await chatService.updateUserProfile(
                        name: trimmedName,
                        avatarColorHex: activeColorHex,
                        themeName: activeTheme,
                      );
                      themeProvider.setTheme(activeTheme);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
