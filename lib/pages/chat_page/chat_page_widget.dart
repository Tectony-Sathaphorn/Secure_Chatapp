import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart' show lookupMimeType;
import 'package:flutter/services.dart';
import 'chat_page_model.dart';
import '/backend/schema/structs/index.dart';
import '/components/message_options_widget.dart';
import '/components/select_users_widget.dart';
import '../../services/call_manager.dart';
import '/app_state.dart';
export 'chat_page_model.dart';

class ChatPageWidget extends StatefulWidget {
  const ChatPageWidget({
    super.key,
    required this.recieveChat,
  });

  final DocumentReference? recieveChat;

  static String routeName = 'chatPage';
  static String routePath = '/chatPage';

  @override
  State<ChatPageWidget> createState() => _ChatPageWidgetState();
}

class _ChatPageWidgetState extends State<ChatPageWidget> {
  late ChatPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showEmojiPicker = false;

  // เพิ่มฟังก์ชันสำหรับการตรวจสอบและปรับแต่งข้อความที่มีลิงก์
  String _parseMessageWithLinks(String message) {
    // แทนที่เครื่องหมาย \n ด้วยการขึ้นบรรทัดใหม่จริงๆ
    String formattedMessage = message.replaceAll('\\n', '\n');

    // ตรวจสอบว่าเป็นข้อความรูปภาพ วิดีโอ หรือไฟล์หรือไม่
    if (message.startsWith('รูปภาพ:') ||
        message.startsWith('วิดีโอ:') ||
        message.startsWith('ไฟล์:')) {
      return formattedMessage;
    }

    return formattedMessage;
  }

  // แสดงแกลเลอรี่สื่อในการสนทนา
  void _showMediaGallery(String mediaType) {
    String prefix;
    IconData iconData;
    String title;

    switch (mediaType) {
      case 'image':
        prefix = 'รูปภาพ:';
        iconData = Icons.photo;
        title = 'รูปภาพทั้งหมด';
        break;
      case 'video':
        prefix = 'วิดีโอ:';
        iconData = Icons.videocam;
        title = 'วิดีโอทั้งหมด';
        break;
      case 'file':
        prefix = 'ไฟล์:';
        iconData = Icons.insert_drive_file;
        title = 'ไฟล์ทั้งหมด';
        break;
      default:
        prefix = '';
        iconData = Icons.error;
        title = 'สื่อทั้งหมด';
    }

    // แสดงหน้าต่างแกลเลอรี่
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(iconData, color: FlutterFlowTheme.of(context).primary),
              SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: StreamBuilder<List<ChatMessagesRecord>>(
              stream: queryChatMessagesRecord(
                parent: widget!.recieveChat,
                queryBuilder: (query) => query
                    .where('message', isGreaterThanOrEqualTo: prefix)
                    .where('message', isLessThan: prefix + 'zzzzzzzzz')
                    .orderBy('message')
                    .orderBy('timeStamp', descending: true),
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text('ไม่พบสื่อในการสนทนา'),
                  );
                }

                final mediaMessages = snapshot.data!;

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: mediaType == 'image' ? 2 : 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: mediaType == 'image' ? 1.0 : 2.5,
                  ),
                  itemCount: mediaMessages.length,
                  itemBuilder: (context, index) {
                    final message = mediaMessages[index].message;
                    final url = message.replaceFirst(prefix, '').trim();

                    if (mediaType == 'image') {
                      return InkWell(
                        onTap: () async {
                          if (await canLaunch(url)) {
                            await launch(url);
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: FlutterFlowTheme.of(context).alternate,
                                child: Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: FlutterFlowTheme.of(context).error,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    } else if (mediaType == 'video') {
                      final videoUrl = url.split('|').last;
                      return ListTile(
                        leading: Icon(Icons.videocam,
                            color: FlutterFlowTheme.of(context).primary),
                        title: Text('วิดีโอ ${index + 1}'),
                        subtitle: Text(mediaMessages[index].timeStamp != null
                            ? dateTimeFormat('dd/MM/yy HH:mm',
                                mediaMessages[index].timeStamp!)
                            : ''),
                        onTap: () async {
                          if (await canLaunch(videoUrl)) {
                            await launch(videoUrl);
                          }
                        },
                      );
                    } else {
                      // ไฟล์
                      final parts = message.split('\n');
                      final fileName = parts[0].replaceFirst(prefix, '').trim();
                      final fileUrl = parts.length > 1 ? parts[1] : '';

                      return ListTile(
                        leading: Icon(Icons.insert_drive_file,
                            color: FlutterFlowTheme.of(context).primary),
                        title: Text(fileName),
                        subtitle: Text(mediaMessages[index].timeStamp != null
                            ? dateTimeFormat('dd/MM/yy HH:mm',
                                mediaMessages[index].timeStamp!)
                            : ''),
                        onTap: () async {
                          if (fileUrl.isNotEmpty && await canLaunch(fileUrl)) {
                            await launch(fileUrl);
                          }
                        },
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('ปิด'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันสำหรับอัปโหลดรูปภาพ
  Future<String?> _uploadImage() async {
    try {
      // ตรวจสอบว่าอยู่บนเว็บหรือไม่
      if (kIsWeb) {
        // วิธีการอัปโหลดสำหรับเว็บ
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final fileName = result.files.first.name;
          final mimeType = result.files.first.bytes != null
              ? lookupMimeType('.$fileName',
                      headerBytes:
                          result.files.first.bytes!.take(50).toList()) ??
                  'image/jpeg'
              : 'image/jpeg';

          final bytes = result.files.first.bytes;
          if (bytes == null) return null;

          final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final path =
              'chats/${widget.recieveChat!.id}/images/$timestamp-$fileName';

          final ref = FirebaseStorage.instance.ref().child(path);
          final metadata = SettableMetadata(contentType: mimeType);

          // Upload image with explicit metadata to ensure it's recognized as an image
          final uploadTask = ref.putData(bytes, metadata);
          await uploadTask.whenComplete(() => null);

          // Get download URL and verify it's accessible
          final url = await ref.getDownloadURL();

          return url;
        }
      } else {
        // วิธีการอัปโหลดสำหรับโมบายล์
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          final File file = File(pickedFile.path);
          final String fileName = p.basename(file.path);
          final String timestamp =
              DateTime.now().millisecondsSinceEpoch.toString();
          final String path =
              'chats/${widget.recieveChat!.id}/images/$timestamp-$fileName';

          final ref = FirebaseStorage.instance.ref().child(path);
          // Specify metadata to ensure image is recognized correctly
          final metadata = SettableMetadata(contentType: 'image/jpeg');
          await ref.putFile(file, metadata);
          final url = await ref.getDownloadURL();
          return url;
        }
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // ฟังก์ชันสำหรับอัปโหลดไฟล์
  Future<String?> _uploadFile() async {
    try {
      // สำหรับทุกแพลตฟอร์ม
      final result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        final fileName = result.files.first.name;
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final path =
            'chats/${widget.recieveChat!.id}/files/$timestamp-$fileName';

        if (kIsWeb) {
          // สำหรับเว็บ
          final bytes = result.files.first.bytes;
          if (bytes == null) return null;

          final mimeType = result.files.first.bytes != null
              ? lookupMimeType(fileName,
                  headerBytes: result.files.first.bytes!.take(50).toList())
              : 'application/octet-stream';

          final ref = FirebaseStorage.instance.ref().child(path);
          final metadata = SettableMetadata(contentType: mimeType);

          await ref.putData(bytes, metadata);
          final url = await ref.getDownloadURL();
          return '$fileName|$url';
        } else {
          // สำหรับโมบายล์
          final File file = File(result.files.single.path!);
          final ref = FirebaseStorage.instance.ref().child(path);
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          return '$fileName|$url';
        }
      }
      return null;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // ฟังก์ชันสำหรับอัปโหลดวิดีโอ
  Future<String?> _uploadVideo() async {
    try {
      if (kIsWeb) {
        // สำหรับเว็บ
        final result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final fileName = result.files.first.name;
          final bytes = result.files.first.bytes;
          if (bytes == null) return null;

          final mimeType = result.files.first.bytes != null
              ? lookupMimeType(fileName,
                  headerBytes: result.files.first.bytes!.take(50).toList())
              : 'video/mp4';

          final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final path =
              'chats/${widget.recieveChat!.id}/videos/$timestamp-$fileName';

          final ref = FirebaseStorage.instance.ref().child(path);
          final metadata = SettableMetadata(contentType: mimeType);

          await ref.putData(bytes, metadata);
          final url = await ref.getDownloadURL();
          return 'video|$url';
        }
      } else {
        // สำหรับโมบายล์
        final picker = ImagePicker();
        final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

        if (pickedFile != null) {
          final File file = File(pickedFile.path);
          final String fileName = p.basename(file.path);
          final String timestamp =
              DateTime.now().millisecondsSinceEpoch.toString();
          final String path =
              'chats/${widget.recieveChat!.id}/videos/$timestamp-$fileName';

          final ref = FirebaseStorage.instance.ref().child(path);
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          return 'video|$url';
        }
      }
      return null;
    } catch (e) {
      print('Error uploading video: $e');
      return null;
    }
  }

  // เพิ่มฟังก์ชัน getOtherUserId
  Future<String?> getOtherUserId() async {
    try {
      // ดึงข้อมูลแชท
      final chatSnapshot = await widget.recieveChat!.get();
      if (!chatSnapshot.exists) {
        return null;
      }

      // ดึงข้อมูล users จากแชท
      final chatData = chatSnapshot.data() as Map<String, dynamic>;
      final List<dynamic> users = chatData['users'] ?? [];

      // หาผู้ใช้อื่นในแชท
      for (final userRef in users) {
        final userId = (userRef as DocumentReference).id;
        if (userId != currentUserUid) {
          return userId;
        }
      }

      return null;
    } catch (e) {
      print('Error getting other user ID: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChatPageModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatsRecord>(
      stream: ChatsRecord.getDocument(widget!.recieveChat!),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).alternate,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            ),
          );
        }

        final chatPageChatsRecord = snapshot.data!;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).alternate,
            body: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Container(
                    width: double.infinity,
                    height: 100.0,
                    decoration: BoxDecoration(),
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 50.0, 0.0, 0.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              await widget!.recieveChat!.update({
                                ...mapToFirestore(
                                  {
                                    'lastMessageSeenBy': FieldValue.arrayUnion(
                                        [currentUserReference]),
                                  },
                                ),
                              });
                              context.pop();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                FlutterFlowIconButton(
                                  borderColor: Colors.transparent,
                                  borderRadius: 30.0,
                                  borderWidth: 1.0,
                                  buttonSize: 60.0,
                                  icon: Icon(
                                    Icons.arrow_back_ios,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    size: 30.0,
                                  ),
                                  onPressed: () async {
                                    await widget!.recieveChat!.update({
                                      ...mapToFirestore(
                                        {
                                          'lastMessageSeenBy':
                                              FieldValue.arrayUnion(
                                                  [currentUserReference]),
                                        },
                                      ),
                                    });
                                    context.pop();
                                  },
                                ),
                                Row(
                                  children: [
                                    // แสดงรูปโปรไฟล์ของผู้รับแชท
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                      ),
                                      child: Center(
                                        child: Text(
                                          functions
                                                  .getOtherUser(
                                                    chatPageChatsRecord
                                                            .userNames
                                                            ?.toList() ??
                                                        [],
                                                    currentUserDisplayName ??
                                                        '',
                                                  )
                                                  .isNotEmpty
                                              ? functions
                                                  .getOtherUser(
                                                    chatPageChatsRecord
                                                            .userNames
                                                            ?.toList() ??
                                                        [],
                                                    currentUserDisplayName ??
                                                        '',
                                                  )[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: FlutterFlowTheme.of(context)
                                              .titleLarge
                                              .override(
                                                fontFamily: 'Inter',
                                                color: Colors.white,
                                              ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      functions
                                              .getOtherUser(
                                                chatPageChatsRecord.userNames
                                                        ?.toList() ??
                                                    [],
                                                currentUserDisplayName ?? '',
                                              )
                                              .isNotEmpty
                                          ? functions.getOtherUser(
                                              chatPageChatsRecord.userNames
                                                      ?.toList() ??
                                                  [],
                                              currentUserDisplayName ?? '',
                                            )
                                          : 'Unknown User',
                                      style: FlutterFlowTheme.of(context)
                                          .headlineMedium
                                          .override(
                                            fontFamily: 'Inter Tight',
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            fontSize: 22.0,
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 5.0, 0.0),
                                child: FlutterFlowIconButton(
                                  borderRadius: 8.0,
                                  buttonSize: 40.0,
                                  icon: Icon(
                                    Icons.call,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    size: 24.0,
                                  ),
                                  onPressed: () async {
                                    // เริ่มการโทรเสียง
                                    // ดึงข้อมูล ID ของอีกฝ่าย
                                    final currentChatDoc = await FirebaseFirestore.instance
                                        .collection('chats')
                                        .doc(widget.recieveChat!.id)
                                        .get();
                                    
                                    if (currentChatDoc.exists) {
                                      final chatData = currentChatDoc.data() as Map<String, dynamic>;
                                      final usersList = chatData['users'] as List<dynamic>?;
                                      
                                      if (usersList != null && usersList.isNotEmpty) {
                                        String? otherUserId;
                                        
                                        // หา userId ของอีกฝ่าย
                                        for (final userRef in usersList) {
                                          final userId = (userRef as DocumentReference).id;
                                          if (userId != currentUserUid) {
                                            otherUserId = userId;
                                            break;
                                          }
                                        }
                                        
                                        if (otherUserId != null) {
                                          // ดึงชื่อผู้ใช้จาก functions
                                          String displayName = functions.getOtherUser(
                                            chatPageChatsRecord.userNames?.toList() ?? [],
                                            currentUserDisplayName ?? '',
                                          );
                                          
                                          // ใช้ CallManager เพื่อเริ่มการโทร
                                          try {
                                            // เริ่มต้นการโทรด้วย CallManager จาก AppState
                                            final callManager = FFAppState().callManager;
                                            if (callManager != null) {
                                              await callManager.startCall(
                                                receiverId: otherUserId,
                                                receiverName: displayName,
                                                isVideo: false,
                                                context: context,
                                              );
                                            } else {
                                              throw Exception("Call manager not initialized");
                                            }
                                            return;
                                          } catch (e) {
                                            print('เกิดข้อผิดพลาดในการเริ่มการโทร: $e');
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('เกิดข้อผิดพลาดในการเริ่มการโทร: $e'),
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    }
                                    
                                    // แสดงข้อความถ้าไม่สามารถโทรได้
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('ไม่สามารถเริ่มการโทรได้'),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 5.0, 0.0),
                                child: FlutterFlowIconButton(
                                  borderRadius: 8.0,
                                  buttonSize: 40.0,
                                  icon: Icon(
                                    Icons.videocam,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    size: 24.0,
                                  ),
                                  onPressed: () async {
                                    // เริ่มการโทรวิดีโอ
                                    // ดึงข้อมูล ID ของอีกฝ่าย
                                    final currentChatDoc = await FirebaseFirestore.instance
                                        .collection('chats')
                                        .doc(widget.recieveChat!.id)
                                        .get();
                                    
                                    if (currentChatDoc.exists) {
                                      final chatData = currentChatDoc.data() as Map<String, dynamic>;
                                      final usersList = chatData['users'] as List<dynamic>?;
                                      
                                      if (usersList != null && usersList.isNotEmpty) {
                                        String? otherUserId;
                                        
                                        // หา userId ของอีกฝ่าย
                                        for (final userRef in usersList) {
                                          final userId = (userRef as DocumentReference).id;
                                          if (userId != currentUserUid) {
                                            otherUserId = userId;
                                            break;
                                          }
                                        }
                                        
                                        if (otherUserId != null) {
                                          // ดึงชื่อผู้ใช้จาก functions
                                          String displayName = functions.getOtherUser(
                                            chatPageChatsRecord.userNames?.toList() ?? [],
                                            currentUserDisplayName ?? '',
                                          );
                                          
                                          // ไปยังหน้าเริ่มการโทรวิดีโอ
                                          context.pushNamed(
                                            'joinVideoCall',
                                            queryParameters: {
                                              'otherUserId': otherUserId,
                                              'otherUserName': displayName,
                                            },
                                          );
                                          return;
                                        }
                                      }
                                    }
                                    
                                    // แสดงข้อความถ้าไม่สามารถโทรได้
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('ไม่สามารถเริ่มการโทรวิดีโอได้'),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 15.0, 0.0),
                                child: FlutterFlowIconButton(
                                  borderRadius: 8.0,
                                  buttonSize: 40.0,
                                  icon: Icon(
                                    Icons.menu_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    size: 24.0,
                                  ),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Container(
                                          padding: EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'สื่อในการสนทนา',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .headlineSmall,
                                              ),
                                              SizedBox(height: 16),
                                              ListTile(
                                                leading: Icon(
                                                  Icons.photo_library,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                ),
                                                title: Text('รูปภาพทั้งหมด'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _showMediaGallery('image');
                                                },
                                              ),
                                              ListTile(
                                                leading: Icon(
                                                  Icons.video_library,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                ),
                                                title: Text('วิดีโอทั้งหมด'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _showMediaGallery('video');
                                                },
                                              ),
                                              ListTile(
                                                leading: Icon(
                                                  Icons.insert_drive_file,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                ),
                                                title: Text('ไฟล์ทั้งหมด'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _showMediaGallery('file');
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<ChatMessagesRecord>>(
                    stream: queryChatMessagesRecord(
                      parent: widget!.recieveChat,
                      queryBuilder: (chatMessagesRecord) => chatMessagesRecord
                          .orderBy('timeStamp', descending: true),
                    ),
                    builder: (context, snapshot) {
                      // Customize what your widget looks like when it's loading.
                      if (!snapshot.hasData) {
                        return Center(
                          child: SizedBox(
                            width: 50.0,
                            height: 50.0,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                FlutterFlowTheme.of(context).primary,
                              ),
                            ),
                          ),
                        );
                      }
                      List<ChatMessagesRecord> listViewChatMessagesRecordList =
                          snapshot.data!;

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        reverse: true,
                        scrollDirection: Axis.vertical,
                        itemCount: listViewChatMessagesRecordList.length,
                        itemBuilder: (context, listViewIndex) {
                          final listViewChatMessagesRecord =
                              listViewChatMessagesRecordList[listViewIndex];
                          return SingleChildScrollView(
                            child: Stack(
                              children: [
                                if (listViewChatMessagesRecord.uidOfSender ==
                                    currentUserReference)
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        5.0, 0.0, 10.0, 10.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 18.0, 5.0, 0.0),
                                          child: Text(
                                            dateTimeFormat(
                                                "dd/MM HH:mm",
                                                listViewChatMessagesRecord
                                                    .timeStamp!),
                                            style: FlutterFlowTheme.of(context)
                                                .labelMedium
                                                .override(
                                                  fontFamily: 'Inter',
                                                  fontSize: 8.0,
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ),
                                        Flexible(
                                          child: Padding(
                                            padding: EdgeInsets.all(5.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondary,
                                                borderRadius: BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(10.0),
                                                  bottomRight:
                                                      Radius.circular(10.0),
                                                  topLeft:
                                                      Radius.circular(10.0),
                                                  topRight:
                                                      Radius.circular(0.0),
                                                ),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Builder(
                                                      builder: (context) {
                                                        final message =
                                                            listViewChatMessagesRecord
                                                                .message;

                                                        // รูปภาพ
                                                        if (message.startsWith(
                                                            'รูปภาพ:')) {
                                                          final imageUrl =
                                                              message
                                                                  .replaceFirst(
                                                                      'รูปภาพ:',
                                                                      '')
                                                                  .trim();
                                                          return Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'รูปภาพ:',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'Inter',
                                                                      fontSize:
                                                                          16.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                              ),
                                                              SizedBox(
                                                                  height: 8),
                                                              ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                child: Image
                                                                    .network(
                                                                  imageUrl,
                                                                  width: 200,
                                                                  height: 200,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorBuilder:
                                                                      (context,
                                                                          error,
                                                                          stackTrace) {
                                                                    print(
                                                                        'Error loading image: $error');
                                                                    return Container(
                                                                      width:
                                                                          200,
                                                                      height:
                                                                          150,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .alternate,
                                                                      child:
                                                                          Column(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          Icon(
                                                                            Icons.error_outline,
                                                                            color:
                                                                                FlutterFlowTheme.of(context).error,
                                                                            size:
                                                                                40,
                                                                          ),
                                                                          SizedBox(
                                                                              height: 10),
                                                                          Text(
                                                                            'ไม่สามารถโหลดรูปภาพได้',
                                                                            style:
                                                                                FlutterFlowTheme.of(context).bodyMedium,
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                          ),
                                                                          SizedBox(
                                                                              height: 5),
                                                                          InkWell(
                                                                            onTap:
                                                                                () async {
                                                                              if (await canLaunch(imageUrl)) {
                                                                                await launch(imageUrl);
                                                                              }
                                                                            },
                                                                            child:
                                                                                Text(
                                                                              'แตะเพื่อเปิดลิงก์',
                                                                              style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                                                                                    color: FlutterFlowTheme.of(context).primary,
                                                                                    decoration: TextDecoration.underline,
                                                                                  ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  },
                                                                  cacheWidth:
                                                                      400,
                                                                  cacheHeight:
                                                                      400,
                                                                  loadingBuilder:
                                                                      (context,
                                                                          child,
                                                                          loadingProgress) {
                                                                    if (loadingProgress ==
                                                                        null)
                                                                      return child;
                                                                    return Container(
                                                                      width:
                                                                          200,
                                                                      height:
                                                                          200,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .alternate,
                                                                      child:
                                                                          Center(
                                                                        child:
                                                                            CircularProgressIndicator(
                                                                          value: loadingProgress.expectedTotalBytes != null
                                                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                                              : null,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        }

                                                        // วิดีโอ
                                                        else if (message
                                                            .startsWith(
                                                                'วิดีโอ:')) {
                                                          final videoUrl =
                                                              message
                                                                  .replaceFirst(
                                                                      'วิดีโอ:',
                                                                      '')
                                                                  .trim();
                                                          return Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'วิดีโอ:',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'Inter',
                                                                      fontSize:
                                                                          16.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                              ),
                                                              SizedBox(
                                                                  height: 4),
                                                              GestureDetector(
                                                                onTap:
                                                                    () async {
                                                                  if (await canLaunch(
                                                                      videoUrl)) {
                                                                    await launch(
                                                                        videoUrl);
                                                                  }
                                                                },
                                                                child:
                                                                    Container(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              12),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .alternate,
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .videocam,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                      ),
                                                                      SizedBox(
                                                                          width:
                                                                              8),
                                                                      Text(
                                                                        'เปิดดูวิดีโอ',
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        }

                                                        // ไฟล์
                                                        else if (message
                                                            .startsWith(
                                                                'ไฟล์:')) {
                                                          final messageParts =
                                                              message
                                                                  .replaceFirst(
                                                                      'ไฟล์:',
                                                                      '')
                                                                  .trim()
                                                                  .split('\n');
                                                          final fileName =
                                                              messageParts[0];
                                                          final fileUrl =
                                                              messageParts.length >
                                                                      1
                                                                  ? messageParts[
                                                                      1]
                                                                  : '';

                                                          return Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'ไฟล์:',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'Inter',
                                                                      fontSize:
                                                                          16.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                              ),
                                                              SizedBox(
                                                                  height: 4),
                                                              GestureDetector(
                                                                onTap:
                                                                    () async {
                                                                  if (fileUrl
                                                                          .isNotEmpty &&
                                                                      await canLaunch(
                                                                          fileUrl)) {
                                                                    await launch(
                                                                        fileUrl);
                                                                  }
                                                                },
                                                                child:
                                                                    Container(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              12),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .alternate,
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .file_present,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                      ),
                                                                      SizedBox(
                                                                          width:
                                                                              8),
                                                                      Text(
                                                                        'เปิดไฟล์',
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        }

                                                        // ข้อความทั่วไป
                                                        else {
                                                          return SelectableText(
                                                            _parseMessageWithLinks(
                                                                message),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'Inter',
                                                                  fontSize:
                                                                      16.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                            maxLines: null,
                                                            textAlign:
                                                                TextAlign.left,
                                                            onTap: () async {
                                                              final urlRegex =
                                                                  RegExp(
                                                                      r'(https?:\/\/[^\s]+)');
                                                              final match = urlRegex
                                                                  .firstMatch(
                                                                      message);
                                                              if (match !=
                                                                  null) {
                                                                final url =
                                                                    match.group(
                                                                        0)!;
                                                                if (await canLaunch(
                                                                    url)) {
                                                                  await launch(
                                                                      url);
                                                                }
                                                              }
                                                            },
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ].divide(
                                                      SizedBox(height: 3.0)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (listViewChatMessagesRecord.uidOfSender !=
                                    currentUserReference)
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        10.0, 0.0, 5.0, 10.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Align(
                                          alignment:
                                              AlignmentDirectional(0.0, 1.0),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 5.0, 16.0),
                                            child: Container(
                                              width: 35.0,
                                              height: 35.0,
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  functions
                                                          .getOtherUser(
                                                            chatPageChatsRecord
                                                                    .userNames
                                                                    ?.toList() ??
                                                                [],
                                                            currentUserDisplayName ??
                                                                '',
                                                          )
                                                          .isNotEmpty
                                                      ? functions
                                                          .getOtherUser(
                                                            chatPageChatsRecord
                                                                    .userNames
                                                                    ?.toList() ??
                                                                [],
                                                            currentUserDisplayName ??
                                                                '',
                                                          )[0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyLarge
                                                      .override(
                                                        fontFamily: 'Inter',
                                                        color: Colors.white,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: Padding(
                                            padding: EdgeInsets.all(5.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryBackground,
                                                borderRadius: BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(10.0),
                                                  bottomRight:
                                                      Radius.circular(10.0),
                                                  topLeft: Radius.circular(0.0),
                                                  topRight:
                                                      Radius.circular(10.0),
                                                ),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Builder(
                                                      builder: (context) {
                                                        final message =
                                                            listViewChatMessagesRecord
                                                                .message;

                                                        // รูปภาพ
                                                        if (message.startsWith(
                                                            'รูปภาพ:')) {
                                                          final imageUrl =
                                                              message
                                                                  .replaceFirst(
                                                                      'รูปภาพ:',
                                                                      '')
                                                                  .trim();
                                                          return Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'รูปภาพ:',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'Inter',
                                                                      fontSize:
                                                                          16.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                              ),
                                                              SizedBox(
                                                                  height: 8),
                                                              ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                child: Image
                                                                    .network(
                                                                  imageUrl,
                                                                  width: 200,
                                                                  height: 200,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorBuilder:
                                                                      (context,
                                                                          error,
                                                                          stackTrace) {
                                                                    print(
                                                                        'Error loading image: $error');
                                                                    return Container(
                                                                      width:
                                                                          200,
                                                                      height:
                                                                          150,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .alternate,
                                                                      child:
                                                                          Column(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          Icon(
                                                                            Icons.error_outline,
                                                                            color:
                                                                                FlutterFlowTheme.of(context).error,
                                                                            size:
                                                                                40,
                                                                          ),
                                                                          SizedBox(
                                                                              height: 10),
                                                                          Text(
                                                                            'ไม่สามารถโหลดรูปภาพได้',
                                                                            style:
                                                                                FlutterFlowTheme.of(context).bodyMedium,
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                          ),
                                                                          SizedBox(
                                                                              height: 5),
                                                                          InkWell(
                                                                            onTap:
                                                                                () async {
                                                                              if (await canLaunch(imageUrl)) {
                                                                                await launch(imageUrl);
                                                                              }
                                                                            },
                                                                            child:
                                                                                Text(
                                                                              'แตะเพื่อเปิดลิงก์',
                                                                              style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                                                                                    color: FlutterFlowTheme.of(context).primary,
                                                                                    decoration: TextDecoration.underline,
                                                                                  ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  },
                                                                  cacheWidth:
                                                                      400,
                                                                  cacheHeight:
                                                                      400,
                                                                  loadingBuilder:
                                                                      (context,
                                                                          child,
                                                                          loadingProgress) {
                                                                    if (loadingProgress ==
                                                                        null)
                                                                      return child;
                                                                    return Container(
                                                                      width:
                                                                          200,
                                                                      height:
                                                                          200,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .alternate,
                                                                      child:
                                                                          Center(
                                                                        child:
                                                                            CircularProgressIndicator(
                                                                          value: loadingProgress.expectedTotalBytes != null
                                                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                                              : null,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        }

                                                        // วิดีโอ
                                                        else if (message
                                                            .startsWith(
                                                                'วิดีโอ:')) {
                                                          final videoUrl =
                                                              message
                                                                  .replaceFirst(
                                                                      'วิดีโอ:',
                                                                      '')
                                                                  .trim();
                                                          return Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'วิดีโอ:',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'Inter',
                                                                      fontSize:
                                                                          16.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                              ),
                                                              SizedBox(
                                                                  height: 4),
                                                              GestureDetector(
                                                                onTap:
                                                                    () async {
                                                                  if (await canLaunch(
                                                                      videoUrl)) {
                                                                    await launch(
                                                                        videoUrl);
                                                                  }
                                                                },
                                                                child:
                                                                    Container(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              12),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .alternate,
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .videocam,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                      ),
                                                                      SizedBox(
                                                                          width:
                                                                              8),
                                                                      Text(
                                                                        'เปิดดูวิดีโอ',
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        }

                                                        // ไฟล์
                                                        else if (message
                                                            .startsWith(
                                                                'ไฟล์:')) {
                                                          final messageParts =
                                                              message
                                                                  .replaceFirst(
                                                                      'ไฟล์:',
                                                                      '')
                                                                  .trim()
                                                                  .split('\n');
                                                          final fileName =
                                                              messageParts[0];
                                                          final fileUrl =
                                                              messageParts.length >
                                                                      1
                                                                  ? messageParts[
                                                                      1]
                                                                  : '';

                                                          return Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'ไฟล์:',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'Inter',
                                                                      fontSize:
                                                                          16.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                              ),
                                                              SizedBox(
                                                                  height: 4),
                                                              GestureDetector(
                                                                onTap:
                                                                    () async {
                                                                  if (fileUrl
                                                                          .isNotEmpty &&
                                                                      await canLaunch(
                                                                          fileUrl)) {
                                                                    await launch(
                                                                        fileUrl);
                                                                  }
                                                                },
                                                                child:
                                                                    Container(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              12),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .alternate,
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .file_present,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                      ),
                                                                      SizedBox(
                                                                          width:
                                                                              8),
                                                                      Text(
                                                                        'เปิดไฟล์',
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        }

                                                        // ข้อความทั่วไป
                                                        else {
                                                          return SelectableText(
                                                            _parseMessageWithLinks(
                                                                message),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'Inter',
                                                                  fontSize:
                                                                      16.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                            maxLines: null,
                                                            textAlign:
                                                                TextAlign.left,
                                                            onTap: () async {
                                                              final urlRegex =
                                                                  RegExp(
                                                                      r'(https?:\/\/[^\s]+)');
                                                              final match = urlRegex
                                                                  .firstMatch(
                                                                      message);
                                                              if (match !=
                                                                  null) {
                                                                final url =
                                                                    match.group(
                                                                        0)!;
                                                                if (await canLaunch(
                                                                    url)) {
                                                                  await launch(
                                                                      url);
                                                                }
                                                              }
                                                            },
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ].divide(
                                                      SizedBox(height: 3.0)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  5.0, 18.0, 0.0, 0.0),
                                          child: Text(
                                            dateTimeFormat(
                                                "dd/MM HH:mm",
                                                listViewChatMessagesRecord
                                                    .timeStamp!),
                                            style: FlutterFlowTheme.of(context)
                                                .labelMedium
                                                .override(
                                                  fontFamily: 'Inter',
                                                  fontSize: 8.0,
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Container(
                    width: double.infinity,
                    height: 70.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional(0.0, 1.0),
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(5.0, 0.0, 5.0, 15.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    10.0, 0.0, 5.0, 0.0),
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: TextField(
                                    controller: _model.textController,
                                    focusNode: _model.textFieldFocusNode,
                                    onChanged: (_) => EasyDebounce.debounce(
                                      '_model.textController',
                                      Duration(milliseconds: 0),
                                      () => safeSetState(() {}),
                                    ),
                                    maxLines: 3,
                                    minLines: 1,
                                    keyboardType: TextInputType.multiline,
                                    textInputAction: TextInputAction.newline,
                                    autofocus: false,
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      isDense: false,
                                      labelStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            fontFamily: 'Inter',
                                            letterSpacing: 0.0,
                                          ),
                                      hintText: 'Aa',
                                      hintStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            fontFamily: 'Inter',
                                            letterSpacing: 0.0,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                      filled: true,
                                      fillColor: FlutterFlowTheme.of(context)
                                          .alternate,
                                      contentPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              10.0, 0.0, 0.0, 0.0),
                                      prefixIcon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.attach_file,
                                                size: 20,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText),
                                            padding: EdgeInsets.all(4),
                                            constraints: BoxConstraints(),
                                            onPressed: () async {
                                              String? fileInfo =
                                                  await _uploadFile();
                                              if (fileInfo != null) {
                                                final parts =
                                                    fileInfo.split('|');
                                                final fileName = parts[0];
                                                final fileUrl = parts[1];

                                                await ChatMessagesRecord
                                                        .createDoc(widget!
                                                            .recieveChat!)
                                                    .set(
                                                        createChatMessagesRecordData(
                                                  message:
                                                      'ไฟล์: $fileName\n$fileUrl',
                                                  timeStamp:
                                                      getCurrentTimestamp,
                                                  uidOfSender:
                                                      currentUserReference,
                                                  nameOfSender:
                                                      currentUserDisplayName,
                                                ));

                                                await widget!.recieveChat!
                                                    .update({
                                                  ...createChatsRecordData(
                                                    lastMessage: 'ส่งไฟล์',
                                                    timeStamp:
                                                        getCurrentTimestamp,
                                                  ),
                                                  ...mapToFirestore(
                                                    {
                                                      'lastMessageSeenBy':
                                                          FieldValue.delete(),
                                                    },
                                                  ),
                                                });

                                                await widget!.recieveChat!
                                                    .update({
                                                  ...mapToFirestore(
                                                    {
                                                      'lastMessageSeenBy':
                                                          FieldValue
                                                              .arrayUnion([
                                                        currentUserReference
                                                      ]),
                                                    },
                                                  ),
                                                });
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.photo,
                                                size: 20,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText),
                                            padding: EdgeInsets.all(4),
                                            constraints: BoxConstraints(),
                                            onPressed: () async {
                                              String? imageUrl =
                                                  await _uploadImage();
                                              if (imageUrl != null) {
                                                await ChatMessagesRecord
                                                        .createDoc(widget!
                                                            .recieveChat!)
                                                    .set(
                                                        createChatMessagesRecordData(
                                                  message: 'รูปภาพ:\n$imageUrl',
                                                  timeStamp:
                                                      getCurrentTimestamp,
                                                  uidOfSender:
                                                      currentUserReference,
                                                  nameOfSender:
                                                      currentUserDisplayName,
                                                ));

                                                await widget!.recieveChat!
                                                    .update({
                                                  ...createChatsRecordData(
                                                    lastMessage: 'ส่งรูปภาพ',
                                                    timeStamp:
                                                        getCurrentTimestamp,
                                                  ),
                                                  ...mapToFirestore(
                                                    {
                                                      'lastMessageSeenBy':
                                                          FieldValue.delete(),
                                                    },
                                                  ),
                                                });

                                                await widget!.recieveChat!
                                                    .update({
                                                  ...mapToFirestore(
                                                    {
                                                      'lastMessageSeenBy':
                                                          FieldValue
                                                              .arrayUnion([
                                                        currentUserReference
                                                      ]),
                                                    },
                                                  ),
                                                });
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.videocam,
                                                size: 20,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText),
                                            padding: EdgeInsets.all(4),
                                            constraints: BoxConstraints(),
                                            onPressed: () async {
                                              String? videoInfo =
                                                  await _uploadVideo();
                                              if (videoInfo != null) {
                                                final videoUrl =
                                                    videoInfo.split('|')[1];
                                                await ChatMessagesRecord
                                                        .createDoc(widget!
                                                            .recieveChat!)
                                                    .set(
                                                        createChatMessagesRecordData(
                                                  message: 'วิดีโอ:\n$videoUrl',
                                                  timeStamp:
                                                      getCurrentTimestamp,
                                                  uidOfSender:
                                                      currentUserReference,
                                                  nameOfSender:
                                                      currentUserDisplayName,
                                                ));

                                                await widget!.recieveChat!
                                                    .update({
                                                  ...createChatsRecordData(
                                                    lastMessage: 'ส่งวิดีโอ',
                                                    timeStamp:
                                                        getCurrentTimestamp,
                                                  ),
                                                  ...mapToFirestore(
                                                    {
                                                      'lastMessageSeenBy':
                                                          FieldValue.delete(),
                                                    },
                                                  ),
                                                });

                                                await widget!.recieveChat!
                                                    .update({
                                                  ...mapToFirestore(
                                                    {
                                                      'lastMessageSeenBy':
                                                          FieldValue
                                                              .arrayUnion([
                                                        currentUserReference
                                                      ]),
                                                    },
                                                  ),
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      suffixIcon: PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.insert_emoticon,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          size: 20.0,
                                        ),
                                        padding: EdgeInsets.zero,
                                        onSelected: (String emoji) {
                                          safeSetState(() {
                                            _model.textController.text =
                                                _model.textController.text +
                                                    emoji;
                                          });
                                        },
                                        itemBuilder: (BuildContext context) =>
                                            <PopupMenuEntry<String>>[
                                          // หมวดอารมณ์
                                          PopupMenuItem<String>(
                                            enabled: false,
                                            child: Text('อารมณ์',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          PopupMenuItem<String>(
                                              value: '😊',
                                              child: Text('😊 ยิ้ม')),
                                          PopupMenuItem<String>(
                                              value: '😄',
                                              child: Text('😄 หัวเราะ')),
                                          PopupMenuItem<String>(
                                              value: '😂',
                                              child: Text('😂 ขำ')),
                                          PopupMenuItem<String>(
                                              value: '🥰',
                                              child: Text('🥰 รักมาก')),
                                          PopupMenuItem<String>(
                                              value: '😍',
                                              child: Text('😍 รัก')),
                                          PopupMenuItem<String>(
                                              value: '😘',
                                              child: Text('😘 จูบ')),
                                          PopupMenuItem<String>(
                                              value: '😭',
                                              child: Text('😭 ร้องไห้')),
                                          PopupMenuItem<String>(
                                              value: '😢',
                                              child: Text('😢 เศร้า')),
                                          PopupMenuItem<String>(
                                              value: '😡',
                                              child: Text('😡 โกรธ')),

                                          // หมวดสัญลักษณ์
                                          PopupMenuItem<String>(
                                            enabled: false,
                                            child: Text('สัญลักษณ์',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          PopupMenuItem<String>(
                                              value: '❤️',
                                              child: Text('❤️ หัวใจ')),
                                          PopupMenuItem<String>(
                                              value: '💕',
                                              child: Text('💕 หัวใจคู่')),
                                          PopupMenuItem<String>(
                                              value: '🎉',
                                              child: Text('🎉 ฉลอง')),
                                          PopupMenuItem<String>(
                                              value: '👍',
                                              child: Text('👍 เยี่ยม')),
                                          PopupMenuItem<String>(
                                              value: '👎',
                                              child: Text('👎 แย่')),
                                          PopupMenuItem<String>(
                                              value: '👏',
                                              child: Text('👏 ปรบมือ')),
                                          PopupMenuItem<String>(
                                              value: '🙏',
                                              child: Text('🙏 ขอบคุณ')),
                                          PopupMenuItem<String>(
                                              value: '✅', child: Text('✅ ถูก')),
                                          PopupMenuItem<String>(
                                              value: '❌', child: Text('❌ ผิด')),

                                          // หมวดกิจกรรม
                                          PopupMenuItem<String>(
                                            enabled: false,
                                            child: Text('กิจกรรม',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          PopupMenuItem<String>(
                                              value: '🥂',
                                              child: Text('🥂 ฉลอง')),
                                          PopupMenuItem<String>(
                                              value: '🎁',
                                              child: Text('🎁 ของขวัญ')),
                                          PopupMenuItem<String>(
                                              value: '🏆',
                                              child: Text('🏆 ชนะ')),
                                          PopupMenuItem<String>(
                                              value: '💼',
                                              child: Text('💼 งาน')),
                                          PopupMenuItem<String>(
                                              value: '📱',
                                              child: Text('📱 โทรศัพท์')),
                                          PopupMenuItem<String>(
                                              value: '🍽️',
                                              child: Text('🍽️ อาหาร')),
                                          PopupMenuItem<String>(
                                              value: '🚗',
                                              child: Text('🚗 รถยนต์')),
                                          PopupMenuItem<String>(
                                              value: '✈️',
                                              child: Text('✈️ เดินทาง')),
                                          PopupMenuItem<String>(
                                              value: '⏰',
                                              child: Text('⏰ เวลา')),
                                        ],
                                      ),
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Inter',
                                          letterSpacing: 0.0,
                                        ),
                                    cursorColor: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 0.0),
                              child: FlutterFlowIconButton(
                                borderRadius: 8.0,
                                buttonSize: 38.0,
                                disabledIconColor:
                                    FlutterFlowTheme.of(context).secondaryText,
                                icon: Icon(
                                  Icons.send,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  size: 20.0,
                                ),
                                onPressed: (_model.textController.text ==
                                            null ||
                                        _model.textController.text == '')
                                    ? null
                                    : () async {
                                        await ChatMessagesRecord.createDoc(
                                                widget!.recieveChat!)
                                            .set(createChatMessagesRecordData(
                                          message: _model.textController.text,
                                          timeStamp: getCurrentTimestamp,
                                          uidOfSender: currentUserReference,
                                          nameOfSender: currentUserDisplayName,
                                        ));

                                        await widget!.recieveChat!.update({
                                          ...createChatsRecordData(
                                            lastMessage:
                                                _model.textController.text,
                                            timeStamp: getCurrentTimestamp,
                                          ),
                                          ...mapToFirestore(
                                            {
                                              'lastMessageSeenBy':
                                                  FieldValue.delete(),
                                            },
                                          ),
                                        });

                                        await widget!.recieveChat!.update({
                                          ...mapToFirestore(
                                            {
                                              'lastMessageSeenBy':
                                                  FieldValue.arrayUnion(
                                                      [currentUserReference]),
                                            },
                                          ),
                                        });
                                        safeSetState(() {
                                          _model.textController?.clear();
                                        });
                                      },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
