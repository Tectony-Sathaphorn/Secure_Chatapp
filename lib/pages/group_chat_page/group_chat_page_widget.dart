import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
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

class GroupChatPageWidget extends StatefulWidget {
  const GroupChatPageWidget({
    Key? key,
    required this.groupChatRef,
  }) : super(key: key);

  final DocumentReference? groupChatRef;

  static String routeName = 'groupChatPage';
  static String routePath = '/groupChatPage';

  @override
  _GroupChatPageWidgetState createState() => _GroupChatPageWidgetState();
}

class _GroupChatPageWidgetState extends State<GroupChatPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController _textController = TextEditingController();
  FocusNode _textFocusNode = FocusNode();
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
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: widget.groupChatRef!
                  .collection('groupMessages')
                  .where('message', isGreaterThanOrEqualTo: prefix)
                  .where('message', isLessThan: prefix + 'zzzzzzzzz')
                  .orderBy('message')
                  .orderBy('timeStamp', descending: true)
                  .snapshots()
                  .map((snapshot) => snapshot.docs),
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
                    final message = mediaMessages[index]['message'] as String;
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
                      final timestamp =
                          mediaMessages[index]['timeStamp'] as Timestamp?;
                      return ListTile(
                        leading: Icon(Icons.videocam,
                            color: FlutterFlowTheme.of(context).primary),
                        title: Text('วิดีโอ ${index + 1}'),
                        subtitle: Text(timestamp != null
                            ? dateTimeFormat(
                                'dd/MM/yy HH:mm', timestamp.toDate())
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
                      final timestamp =
                          mediaMessages[index]['timeStamp'] as Timestamp?;

                      return ListTile(
                        leading: Icon(Icons.insert_drive_file,
                            color: FlutterFlowTheme.of(context).primary),
                        title: Text(fileName),
                        subtitle: Text(timestamp != null
                            ? dateTimeFormat(
                                'dd/MM/yy HH:mm', timestamp.toDate())
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
              'groupChats/${widget.groupChatRef!.id}/images/$timestamp-$fileName';

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
              'groupChats/${widget.groupChatRef!.id}/images/$timestamp-$fileName';

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
            'groupChats/${widget.groupChatRef!.id}/files/$timestamp-$fileName';

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
              'groupChats/${widget.groupChatRef!.id}/videos/$timestamp-$fileName';

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
              'groupChats/${widget.groupChatRef!.id}/videos/$timestamp-$fileName';

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

  // ฟังก์ชันสำหรับแสดงหน้าต่างจัดการสมาชิกในกลุ่ม
  void _showMembersManagement() async {
    try {
      final groupChatDoc = await widget.groupChatRef!.get();
      final groupChat = GroupChatsRecord.fromSnapshot(groupChatDoc);
      final isGroupOwner = currentUserReference == groupChat.ownerId;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.7,
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'สมาชิกในกลุ่ม (${groupChat.userNames?.length ?? 0})',
                          style: FlutterFlowTheme.of(context).titleMedium,
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: groupChat.userIds?.length ?? 0,
                        itemBuilder: (context, index) {
                          // Make sure we don't go out of bounds
                          if (groupChat.userIds == null ||
                              groupChat.userNames == null ||
                              index >= groupChat.userIds.length ||
                              index >= groupChat.userNames.length) {
                            return SizedBox(); // Return empty widget for out of bounds indices
                          }

                          final userId = groupChat.userIds[index];
                          final userName = groupChat.userNames[index];
                          final isOwner = userId == groupChat.ownerId;
                          final isCurrentUser = userId == currentUserReference;

                          // Make sure userName is not null or empty
                          final displayName = (userName?.isNotEmpty == true)
                              ? userName
                              : "User";
                          final firstLetter = (displayName.isNotEmpty)
                              ? displayName[0].toUpperCase()
                              : "?";

                          return ListTile(
                            title: Row(
                              children: [
                                Text(
                                  displayName,
                                  style:
                                      FlutterFlowTheme.of(context).bodyMedium,
                                ),
                                SizedBox(width: 8),
                                if (isOwner)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'เจ้าของกลุ่ม',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  firstLetter,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .override(
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                      ),
                                ),
                              ),
                            ),
                            trailing: isGroupOwner && !isOwner && !isCurrentUser
                                ? IconButton(
                                    icon: Icon(
                                      Icons.remove_circle_outline,
                                      color: FlutterFlowTheme.of(context).error,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                              'ยืนยันการนำสมาชิกออกจากกลุ่ม'),
                                          content: Text(
                                              'คุณต้องการนำ $displayName ออกจากกลุ่มใช่หรือไม่?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text('ยกเลิก'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text(
                                                'ยืนยัน',
                                                style: TextStyle(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        try {
                                          // คัดลอกรายชื่อสมาชิกและนำสมาชิกที่จะลบออก
                                          final List<DocumentReference>
                                              updatedUserIds =
                                              List.from(groupChat.userIds);
                                          final List<String> updatedUserNames =
                                              List.from(groupChat.userNames);
                                          final memberIndex =
                                              updatedUserIds.indexOf(userId);

                                          if (memberIndex != -1) {
                                            updatedUserIds
                                                .removeAt(memberIndex);
                                            updatedUserNames
                                                .removeAt(memberIndex);

                                            // อัปเดตรายชื่อสมาชิกในกลุ่ม
                                            await widget.groupChatRef!.update({
                                              'userIds': updatedUserIds,
                                              'userNames': updatedUserNames,
                                            });

                                            // เพิ่มข้อความแจ้งเตือนในกลุ่ม
                                            final messageRef = widget
                                                .groupChatRef!
                                                .collection('groupMessages')
                                                .doc();
                                            await messageRef.set({
                                              'message':
                                                  '$displayName ได้ถูกนำออกจากกลุ่มโดย ${currentUserDisplayName}',
                                              'timeStamp': getCurrentTimestamp,
                                              'uidOfSender':
                                                  currentUserReference,
                                              'nameOfSender':
                                                  currentUserDisplayName,
                                              'isSystemMessage': true,
                                            });

                                            // อัปเดตข้อความล่าสุดในกลุ่ม
                                            await widget.groupChatRef!.update({
                                              'lastMessage':
                                                  '$displayName ได้ถูกนำออกจากกลุ่ม',
                                              'timeStamp': getCurrentTimestamp,
                                            });

                                            // ปิดหน้าต่างสมาชิก
                                            Navigator.pop(context);

                                            // แสดงข้อความแจ้งเตือน
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'นำ $displayName ออกจากกลุ่มแล้ว')),
                                            );
                                          }
                                        } catch (e) {
                                          print('Error removing member: $e');
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text('เกิดข้อผิดพลาด: $e')),
                                          );
                                        }
                                      }
                                    },
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      print('Error showing members management: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการแสดงรายชื่อสมาชิก: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Mark chat as read when entering
    _markAsRead();
  }

  // Mark chat as read
  Future<void> _markAsRead() async {
    try {
      if (widget.groupChatRef != null && currentUserReference != null) {
        // Get current group chat data
        final groupChatDoc = await widget.groupChatRef!.get();
        final groupChat = GroupChatsRecord.fromSnapshot(groupChatDoc);

        // Check if user has already seen the latest message
        if (groupChat.lastMessageSeenBy != null &&
            !groupChat.lastMessageSeenBy.contains(currentUserReference)) {
          // Add current user to the list of users who have seen the message
          final List<DocumentReference> updatedSeenBy =
              List.from(groupChat.lastMessageSeenBy ?? []);
          updatedSeenBy.add(currentUserReference!);

          // Update the document
          await widget.groupChatRef!.update({
            'lastMessageSeenBy': updatedSeenBy,
          });
        }
      }
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  // ส่งข้อความในกลุ่มแชท
  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    try {
      final messageRef = widget.groupChatRef!.collection('groupMessages').doc();
      await messageRef.set({
        'message': _textController.text.trim(),
        'timeStamp': getCurrentTimestamp,
        'uidOfSender': currentUserReference,
        'nameOfSender': currentUserDisplayName,
        'isSystemMessage': false,
      });

      // อัปเดตข้อความล่าสุดในกลุ่ม
      await widget.groupChatRef!.update({
        'lastMessage': _textController.text.trim(),
        'timeStamp': getCurrentTimestamp,
        'lastMessageSeenBy': [currentUserReference],
      });

      // เคลียร์ข้อความในช่องพิมพ์
      _textController.clear();
      setState(() {
        _showEmojiPicker = false;
      });
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GroupChatsRecord>(
      stream: GroupChatsRecord.getDocument(widget.groupChatRef!),
      builder: (context, snapshot) {
        // หน้าจอโหลดข้อมูล
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

        final groupChatRecord = snapshot.data!;
        final isGroupOwner = currentUserReference == groupChatRecord.ownerId;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).alternate,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).primary,
              automaticallyImplyLeading: false,
              leading: FlutterFlowIconButton(
                borderColor: Colors.transparent,
                borderRadius: 30.0,
                buttonSize: 46.0,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 24.0,
                ),
                onPressed: () {
                  // Navigate directly to home page instead of popping
                  context.pushNamed('HomePage');
                },
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: groupChatRecord.groupPhoto.isEmpty
                        ? Center(
                            child: Icon(
                              Icons.group,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 24.0,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              groupChatRecord.groupPhoto,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          groupChatRecord.groupName,
                          style:
                              FlutterFlowTheme.of(context).titleMedium.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                  ),
                        ),
                        Text(
                          '${groupChatRecord.userNames.length} สมาชิก',
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                FlutterFlowIconButton(
                  borderColor: Colors.transparent,
                  borderRadius: 20,
                  buttonSize: 40,
                  icon: Icon(
                    Icons.call,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () async {
                    // Voice call feature not implemented
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('ฟีเจอร์การโทรกลุ่มกำลังอยู่ระหว่างการพัฒนา'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 24.0,
                  ),
                  onSelected: (String value) {
                    if (value == 'members') {
                      _showMembersManagement();
                    } else if (value == 'media') {
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
                                  style: FlutterFlowTheme.of(context)
                                      .headlineSmall,
                                ),
                                SizedBox(height: 16),
                                ListTile(
                                  leading: Icon(Icons.photo,
                                      color:
                                          FlutterFlowTheme.of(context).primary),
                                  title: Text('รูปภาพทั้งหมด'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showMediaGallery('image');
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.videocam,
                                      color:
                                          FlutterFlowTheme.of(context).primary),
                                  title: Text('วิดีโอทั้งหมด'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showMediaGallery('video');
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.insert_drive_file,
                                      color:
                                          FlutterFlowTheme.of(context).primary),
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
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'members',
                      child: Row(
                        children: [
                          Icon(Icons.group,
                              color: FlutterFlowTheme.of(context).primary),
                          SizedBox(width: 10),
                          Text('จัดการสมาชิก'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'media',
                      child: Row(
                        children: [
                          Icon(Icons.perm_media,
                              color: FlutterFlowTheme.of(context).primary),
                          SizedBox(width: 10),
                          Text('ดูสื่อทั้งหมด'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              centerTitle: false,
              elevation: 2.0,
            ),
            body: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // พื้นที่แสดงข้อความแชท
                Expanded(
                  child: StreamBuilder<List<DocumentSnapshot>>(
                    stream: widget.groupChatRef!
                        .collection('groupMessages')
                        .orderBy('timeStamp', descending: true)
                        .snapshots()
                        .map((snapshot) => snapshot.docs),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final messages = snapshot.data!;
                      if (messages.isEmpty) {
                        return Center(
                          child: Text('ยังไม่มีข้อความในกลุ่มนี้'),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(10),
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              messages[index].data() as Map<String, dynamic>;
                          final isSystemMessage =
                              message['isSystemMessage'] ?? false;

                          if (isSystemMessage) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground
                                        .withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    message['message'] as String,
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          fontFamily: 'Inter',
                                          fontStyle: FontStyle.italic,
                                        ),
                                  ),
                                ),
                              ),
                            );
                          }

                          // Fix the isMyMessage check to handle both reference and path string cases
                          bool isMyMessage = false;
                          final senderReference = message['uidOfSender'];
                          if (senderReference is String &&
                              currentUserReference != null) {
                            isMyMessage =
                                senderReference == currentUserReference?.path;
                          } else if (senderReference is DocumentReference &&
                              currentUserReference != null) {
                            isMyMessage = senderReference.path ==
                                currentUserReference?.path;
                          }

                          final messageContent = _parseMessageWithLinks(
                              message['message'] as String);
                          final timestamp = message['timeStamp'] as Timestamp;
                          final senderName = message['nameOfSender'] as String;

                          return Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: isMyMessage
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMyMessage)
                                  Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Container(
                                      width: 35,
                                      height: 35,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          senderName.isNotEmpty
                                              ? senderName[0].toUpperCase()
                                              : '?',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Inter',
                                                color: Colors.white,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Column(
                                  crossAxisAlignment: isMyMessage
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    if (!isMyMessage)
                                      Padding(
                                        padding:
                                            EdgeInsets.only(left: 4, bottom: 2),
                                        child: Text(
                                          senderName.isNotEmpty
                                              ? senderName
                                              : 'User',
                                          style: FlutterFlowTheme.of(context)
                                              .bodySmall
                                              .override(
                                                fontFamily: 'Inter',
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.7,
                                        minWidth: 50,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isMyMessage
                                            ? FlutterFlowTheme.of(context)
                                                .primary
                                            : FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IntrinsicWidth(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!isMyMessage)
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(bottom: 4),
                                                child: Text(
                                                  senderName.isNotEmpty
                                                      ? senderName
                                                      : 'User',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodySmall
                                                      .override(
                                                        fontFamily: 'Inter',
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            _buildMessageContent(context,
                                                messageContent, isMyMessage),
                                            Align(
                                              alignment: Alignment.bottomRight,
                                              child: Padding(
                                                padding:
                                                    EdgeInsets.only(top: 4),
                                                child: Text(
                                                  dateTimeFormat('HH:mm',
                                                      timestamp.toDate()),
                                                  style:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .override(
                                                            fontFamily: 'Inter',
                                                            fontSize: 10,
                                                            color: isMyMessage
                                                                ? Colors.white
                                                                    .withOpacity(
                                                                        0.7)
                                                                : FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryText,
                                                          ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // ช่องพิมพ์ข้อความ
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 24,
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return Container(
                                height: 120,
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.photo,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            size: 30,
                                          ),
                                          onPressed: () async {
                                            Navigator.pop(context);

                                            final imageUrl =
                                                await _uploadImage();
                                            if (imageUrl != null) {
                                              final messageRef = widget
                                                  .groupChatRef!
                                                  .collection('groupMessages')
                                                  .doc();
                                              await messageRef.set({
                                                'message': 'รูปภาพ:$imageUrl',
                                                'timeStamp':
                                                    getCurrentTimestamp,
                                                'uidOfSender':
                                                    currentUserReference,
                                                'nameOfSender':
                                                    currentUserDisplayName,
                                                'isSystemMessage': false,
                                              });

                                              await widget.groupChatRef!
                                                  .update({
                                                'lastMessage': 'ส่งรูปภาพ',
                                                'timeStamp':
                                                    getCurrentTimestamp,
                                                'lastMessageSeenBy': [
                                                  currentUserReference
                                                ],
                                              });
                                            }
                                          },
                                        ),
                                        Text('รูปภาพ'),
                                      ],
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.videocam,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            size: 30,
                                          ),
                                          onPressed: () async {
                                            Navigator.pop(context);

                                            final videoUrl =
                                                await _uploadVideo();
                                            if (videoUrl != null) {
                                              final messageRef = widget
                                                  .groupChatRef!
                                                  .collection('groupMessages')
                                                  .doc();
                                              await messageRef.set({
                                                'message': 'วิดีโอ:$videoUrl',
                                                'timeStamp':
                                                    getCurrentTimestamp,
                                                'uidOfSender':
                                                    currentUserReference,
                                                'nameOfSender':
                                                    currentUserDisplayName,
                                                'isSystemMessage': false,
                                              });

                                              await widget.groupChatRef!
                                                  .update({
                                                'lastMessage': 'ส่งวิดีโอ',
                                                'timeStamp':
                                                    getCurrentTimestamp,
                                                'lastMessageSeenBy': [
                                                  currentUserReference
                                                ],
                                              });
                                            }
                                          },
                                        ),
                                        Text('วิดีโอ'),
                                      ],
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.insert_drive_file,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            size: 30,
                                          ),
                                          onPressed: () async {
                                            Navigator.pop(context);

                                            final fileInfo =
                                                await _uploadFile();
                                            if (fileInfo != null) {
                                              final parts = fileInfo.split('|');
                                              final fileName = parts[0];
                                              final fileUrl = parts[1];

                                              final messageRef = widget
                                                  .groupChatRef!
                                                  .collection('groupMessages')
                                                  .doc();
                                              await messageRef.set({
                                                'message':
                                                    'ไฟล์:$fileName\n$fileUrl',
                                                'timeStamp':
                                                    getCurrentTimestamp,
                                                'uidOfSender':
                                                    currentUserReference,
                                                'nameOfSender':
                                                    currentUserDisplayName,
                                                'isSystemMessage': false,
                                              });

                                              await widget.groupChatRef!
                                                  .update({
                                                'lastMessage':
                                                    'ส่งไฟล์: $fileName',
                                                'timeStamp':
                                                    getCurrentTimestamp,
                                                'lastMessageSeenBy': [
                                                  currentUserReference
                                                ],
                                              });
                                            }
                                          },
                                        ),
                                        Text('ไฟล์'),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _textFocusNode,
                          decoration: InputDecoration(
                            hintText: 'พิมพ์ข้อความ...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: FlutterFlowTheme.of(context).alternate,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.insert_emoticon,
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                size: 20.0,
                              ),
                              onPressed: () {
                                // Show emoji picker in bottom sheet with horizontal layout
                                showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Container(
                                      height: 300,
                                      child: Column(
                                        children: [
                                          // Category tabs
                                          Container(
                                            height: 50,
                                            child: ListView(
                                              scrollDirection: Axis.horizontal,
                                              children: [
                                                _buildEmojiCategoryTab('อารมณ์',
                                                    Icons.emoji_emotions),
                                                _buildEmojiCategoryTab(
                                                    'สัญลักษณ์',
                                                    Icons.favorite),
                                                _buildEmojiCategoryTab(
                                                    'กิจกรรม',
                                                    Icons.celebration),
                                              ],
                                            ),
                                          ),
                                          Divider(),
                                          // Emoji grid
                                          Expanded(
                                            child: SingleChildScrollView(
                                              child: Column(
                                                children: [
                                                  // Emotions Section
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Wrap(
                                                      spacing: 10,
                                                      runSpacing: 10,
                                                      children: [
                                                        _buildEmojiButton('😊'),
                                                        _buildEmojiButton('😄'),
                                                        _buildEmojiButton('😂'),
                                                        _buildEmojiButton('🥰'),
                                                        _buildEmojiButton('😍'),
                                                        _buildEmojiButton('😘'),
                                                        _buildEmojiButton('😭'),
                                                        _buildEmojiButton('😢'),
                                                        _buildEmojiButton('😡'),
                                                      ],
                                                    ),
                                                  ),
                                                  Divider(),
                                                  // Symbols Section
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Wrap(
                                                      spacing: 10,
                                                      runSpacing: 10,
                                                      children: [
                                                        _buildEmojiButton('❤️'),
                                                        _buildEmojiButton('💕'),
                                                        _buildEmojiButton('🎉'),
                                                        _buildEmojiButton('👍'),
                                                        _buildEmojiButton('👎'),
                                                        _buildEmojiButton('👏'),
                                                        _buildEmojiButton('🙏'),
                                                        _buildEmojiButton('✅'),
                                                        _buildEmojiButton('❌'),
                                                      ],
                                                    ),
                                                  ),
                                                  Divider(),
                                                  // Activities Section
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Wrap(
                                                      spacing: 10,
                                                      runSpacing: 10,
                                                      children: [
                                                        _buildEmojiButton('🥂'),
                                                        _buildEmojiButton('🎁'),
                                                        _buildEmojiButton('🏆'),
                                                        _buildEmojiButton('💼'),
                                                        _buildEmojiButton('📱'),
                                                        _buildEmojiButton(
                                                            '🍽️'),
                                                        _buildEmojiButton('🚗'),
                                                        _buildEmojiButton('✈️'),
                                                        _buildEmojiButton('⏰'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
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
                          minLines: 1,
                          maxLines: 5,
                        ),
                      ),
                      SizedBox(width: 5),
                      IconButton(
                        icon: Icon(
                          Icons.send,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 24,
                        ),
                        onPressed: _textController.text.trim().isEmpty
                            ? null
                            : _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper to build the content of messages
  Widget _buildMessageContent(
      BuildContext context, String messageContent, bool isMyMessage) {
    try {
      // Check for image content
      if (messageContent.startsWith('รูปภาพ:')) {
        final imageUrl = messageContent.substring('รูปภาพ:'.length).trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'รูปภาพ',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    color: isMyMessage
                        ? Colors.white
                        : FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
            SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[300],
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
          ],
        );
      }
      // Check for video content
      else if (messageContent.startsWith('วิดีโอ:')) {
        final videoUrl = messageContent.substring('วิดีโอ:'.length).trim();
        return Container(
          constraints: BoxConstraints(
            minWidth: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'วิดีโอ',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Inter',
                      color: isMyMessage
                          ? Colors.white
                          : FlutterFlowTheme.of(context).primaryText,
                    ),
              ),
              SizedBox(height: 4),
              GestureDetector(
                onTap: () async {
                  if (await canLaunch(videoUrl)) {
                    await launch(videoUrl);
                  }
                },
                child: Container(
                  width: 200,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      // Check for file content
      else if (messageContent.startsWith('ไฟล์:')) {
        final parts =
            messageContent.substring('ไฟล์:'.length).trim().split('\n');

        if (parts.length >= 2) {
          final fileName = parts[0];
          final fileUrl = parts[1];

          return Container(
            constraints: BoxConstraints(
              minWidth: 20,
            ),
            child: GestureDetector(
              onTap: () async {
                if (await canLaunch(fileUrl)) {
                  await launch(fileUrl);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insert_drive_file,
                    color: isMyMessage
                        ? Colors.white
                        : FlutterFlowTheme.of(context).primary,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      fileName,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Inter',
                            color: isMyMessage
                                ? Colors.white
                                : FlutterFlowTheme.of(context).primaryText,
                            decoration: TextDecoration.underline,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }

      // Regular text message
      return RichText(
        text: TextSpan(
          text: messageContent,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Inter',
                color: isMyMessage
                    ? Colors.white
                    : FlutterFlowTheme.of(context).primaryText,
                fontSize: 14,
              ),
        ),
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.left,
        textWidthBasis: TextWidthBasis.parent,
      );
    } catch (e) {
      print('Error rendering message content: $e');
      // Fallback rendering for any errors
      return Text(
        'พบข้อผิดพลาดในการแสดงข้อความ',
        style: FlutterFlowTheme.of(context).bodySmall.override(
              fontFamily: 'Inter',
              color: isMyMessage
                  ? Colors.white70
                  : FlutterFlowTheme.of(context).error,
              fontStyle: FontStyle.italic,
            ),
      );
    }
  }

  // Helper method to build emoji category tabs
  Widget _buildEmojiCategoryTab(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: FlutterFlowTheme.of(context).primary),
          SizedBox(height: 4),
          Text(title, style: FlutterFlowTheme.of(context).bodySmall),
        ],
      ),
    );
  }

  // Helper method to build emoji buttons
  Widget _buildEmojiButton(String emoji) {
    return InkWell(
      onTap: () {
        setState(() {
          _textController.text = _textController.text + emoji;
        });
        Navigator.pop(context);
      },
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Text(
          emoji,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
