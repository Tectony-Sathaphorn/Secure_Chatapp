import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class CreateGroupChatWidget extends StatefulWidget {
  const CreateGroupChatWidget({Key? key}) : super(key: key);

  static String routeName = 'createGroupChat';
  static String routePath = '/createGroupChat';

  @override
  _CreateGroupChatWidgetState createState() => _CreateGroupChatWidgetState();
}

class _CreateGroupChatWidgetState extends State<CreateGroupChatWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  
  TextEditingController _groupNameController = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  String? uploadedFileUrl;
  List<DocumentReference> selectedUsers = [];
  List<String> selectedUserNames = [];
  bool isLoading = false;
  final int maxMembers = 10;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // อัพโหลดรูปภาพกลุ่ม
  Future<void> _uploadGroupPhoto() async {
    try {
      setState(() {
        isLoading = true;
      });

      if (kIsWeb) {
        // วิธีการอัพโหลดสำหรับเว็บ
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true, // Ensure we get the bytes
        );
        
        if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
          final fileName = result.files.first.name;
          final bytes = result.files.first.bytes!;
          
          final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final path = 'groupProfilePhotos/$timestamp-$fileName';
          
          try {
            final reference = FirebaseStorage.instance.ref().child(path);
            
            final metadata = SettableMetadata(
              contentType: 'image/${fileName.split('.').last}',
              customMetadata: {'picked-file-path': fileName},
            );
            
            final uploadTask = reference.putData(bytes, metadata);
            final taskSnapshot = await uploadTask;
            
            final url = await taskSnapshot.ref.getDownloadURL();
            setState(() {
              uploadedFileUrl = url;
              isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('อัพโหลดรูปภาพกลุ่มสำเร็จ')),
            );
          } catch (e) {
            setState(() {
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('เกิดข้อผิดพลาดในการอัพโหลด: $e')),
            );
            print('Error in web upload: $e');
          }
        } else {
          setState(() {
            isLoading = false;
          });
          if (result == null) {
            // User cancelled the picker
            print('User cancelled file picker');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ไม่สามารถอ่านไฟล์ที่เลือกได้')),
            );
          }
        }
      } else {
        // วิธีการอัพโหลดสำหรับโมบายล์
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        
        if (pickedFile != null) {
          final File file = File(pickedFile.path);
          if (!await file.exists()) {
            setState(() {
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ไม่พบไฟล์รูปภาพ')),
            );
            return;
          }
          
          final String fileName = pickedFile.name;
          final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final String path = 'groupProfilePhotos/$timestamp-$fileName';
          
          try {
            final reference = FirebaseStorage.instance.ref().child(path);
            final uploadTask = reference.putFile(file);
            final taskSnapshot = await uploadTask;
            
            final url = await taskSnapshot.ref.getDownloadURL();
            setState(() {
              uploadedFileUrl = url;
              isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('อัพโหลดรูปภาพกลุ่มสำเร็จ')),
            );
          } catch (e) {
            setState(() {
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('เกิดข้อผิดพลาดในการอัพโหลด: $e')),
            );
            print('Error in mobile upload: $e');
          }
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error uploading group photo: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการอัพโหลด: $e')),
      );
    }
  }

  // สร้างกลุ่มแชท
  Future<void> _createGroupChat() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาเลือกสมาชิกอย่างน้อย 1 คน')),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      // เพิ่มตัวเองเข้าไปในรายชื่อสมาชิก
      final allUserIds = [currentUserReference!, ...selectedUsers];
      final allUserNames = [currentUserDisplayName!, ...selectedUserNames];

      // สร้างกลุ่มแชทในฐานข้อมูล
      final docRef = GroupChatsRecord.collection.doc();
      await docRef.set(createGroupChatsRecordData(
        groupName: _groupNameController.text,
        groupPhoto: uploadedFileUrl,
        ownerId: currentUserReference,
        lastMessage: 'สร้างกลุ่มแชท',
        timeStamp: getCurrentTimestamp,
        createdAt: getCurrentTimestamp,
      ));

      // เพิ่มรายชื่อสมาชิก
      await docRef.update({
        'userIds': allUserIds,
        'userNames': allUserNames,
        'lastMessageSeenBy': [currentUserReference],
      });

      // สร้างข้อความแรกแจ้งการสร้างกลุ่ม
      final chatMessagesRef = docRef.collection('groupMessages').doc();
      await chatMessagesRef.set({
        'message': '${currentUserDisplayName} ได้สร้างกลุ่ม',
        'timeStamp': getCurrentTimestamp,
        'uidOfSender': currentUserReference,
        'nameOfSender': currentUserDisplayName,
        'isSystemMessage': true,
      });

      setState(() {
        isLoading = false;
      });

      // ไปที่หน้ากลุ่มแชท
      context.pushNamed(
        'groupChatPage',
        queryParameters: {
          'groupChatRef': serializeParam(
            docRef,
            ParamType.DocumentReference,
          ),
        }.withoutNulls,
      );
    } catch (e) {
      print('Error creating group chat: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
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
          onPressed: () async {
            context.pop();
          },
        ),
        title: Text(
          'สร้างกลุ่มแชท',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Inter',
                color: Colors.white,
                fontSize: 20.0,
              ),
        ),
        actions: [],
        centerTitle: false,
        elevation: 0.0,
      ),
      body: SafeArea(
        top: true,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // รูปโปรไฟล์กลุ่ม
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100.0,
                          height: 100.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primaryBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).primary,
                              width: 2.0,
                            ),
                          ),
                          child: uploadedFileUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50.0),
                                  child: Image.network(
                                    uploadedFileUrl!,
                                    width: 100.0,
                                    height: 100.0,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.group,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 40.0,
                                ),
                        ),
                        FlutterFlowIconButton(
                          borderColor: FlutterFlowTheme.of(context).primary,
                          borderRadius: 20.0,
                          buttonSize: 40.0,
                          fillColor: FlutterFlowTheme.of(context).primary,
                          icon: Icon(
                            Icons.add_a_photo,
                            color: Colors.white,
                            size: 20.0,
                          ),
                          onPressed: _uploadGroupPhoto,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.0),
                  
                  // ชื่อกลุ่ม
                  TextFormField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      labelText: 'ชื่อกลุ่ม',
                      labelStyle: FlutterFlowTheme.of(context).labelMedium,
                      hintText: 'กรุณาใส่ชื่อกลุ่ม',
                      hintStyle: FlutterFlowTheme.of(context).labelMedium,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).alternate,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).primary,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).error,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).error,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณาใส่ชื่อกลุ่ม';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24.0),
                  
                  // เลือกผู้ใช้
                  Text(
                    'เลือกสมาชิก (สูงสุด ${maxMembers - 1} คน)',
                    style: FlutterFlowTheme.of(context).titleMedium,
                  ),
                  Text(
                    'สมาชิกที่เลือก: ${selectedUsers.length}/${maxMembers - 1}',
                    style: FlutterFlowTheme.of(context).bodySmall,
                  ),
                  SizedBox(height: 8.0),
                  
                  // ช่องค้นหาผู้ใช้
                  Container(
                    width: double.infinity,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 0.0),
                            child: Icon(
                              Icons.search_rounded,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 22.5,
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'ค้นหาตามชื่อผู้ใช้...',
                                hintStyle: FlutterFlowTheme.of(context).labelMedium,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                              ),
                              style: FlutterFlowTheme.of(context).bodyMedium,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                              child: Icon(
                                Icons.clear,
                                color: FlutterFlowTheme.of(context).secondaryText,
                                size: 20.0,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  
                  // รายชื่อผู้ใช้
                  Container(
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 2.0,
                      ),
                    ),
                    child: StreamBuilder<List<UsersRecord>>(
                      stream: queryUsersRecord(
                        queryBuilder: (usersRecord) => usersRecord.where(
                          'uid', 
                          isNotEqualTo: currentUserUid
                        ),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        
                        // กรองผู้ใช้ตามการค้นหา
                        final users = snapshot.data!.where((user) {
                          if (_searchQuery.isEmpty) {
                            return true;
                          }
                          return user.displayName.toLowerCase().contains(_searchQuery);
                        }).toList();
                        
                        if (users.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'ไม่พบผู้ใช้ตามที่ค้นหา',
                                style: FlutterFlowTheme.of(context).bodyMedium,
                              ),
                            ),
                          );
                        }
                        
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: users.length,
                          separatorBuilder: (context, index) => Divider(
                            color: FlutterFlowTheme.of(context).alternate,
                            height: 1.0,
                            thickness: 1.0,
                          ),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final isSelected = selectedUsers.contains(user.reference);
                            return CheckboxListTile(
                              title: Text(
                                user.displayName,
                                style: FlutterFlowTheme.of(context).bodyMedium,
                              ),
                              subtitle: Text(
                                user.email,
                                style: FlutterFlowTheme.of(context).bodySmall,
                              ),
                              secondary: Container(
                                width: 40.0,
                                height: 40.0,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: user.photoUrl.isEmpty
                                    ? Container(
                                        color: FlutterFlowTheme.of(context).primary,
                                        child: Center(
                                          child: Text(
                                            user.displayName != null && user.displayName.isNotEmpty
                                                ? user.displayName[0].toUpperCase()
                                                : '?',
                                            style: FlutterFlowTheme.of(context).titleLarge.override(
                                                  fontFamily: 'Inter',
                                                  color: Colors.white,
                                                ),
                                          ),
                                        ),
                                      )
                                    : Image.network(
                                        user.photoUrl,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              value: isSelected,
                              activeColor: FlutterFlowTheme.of(context).primary,
                              checkColor: Colors.white,
                              onChanged: selectedUsers.length >= maxMembers - 1 && !isSelected
                                  ? null
                                  : (value) {
                                      setState(() {
                                        if (value!) {
                                          selectedUsers.add(user.reference);
                                          selectedUserNames.add(user.displayName);
                                        } else {
                                          selectedUsers.remove(user.reference);
                                          selectedUserNames.remove(user.displayName);
                                        }
                                      });
                                    },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 24.0),
                  
                  // ปุ่มสร้างกลุ่ม
                  Center(
                    child: isLoading
                        ? CircularProgressIndicator()
                        : FFButtonWidget(
                            onPressed: _createGroupChat,
                            text: 'สร้างกลุ่มแชท',
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 50.0,
                              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                              iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                              color: FlutterFlowTheme.of(context).primary,
                              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                  ),
                              elevation: 3.0,
                              borderSide: BorderSide(
                                color: Colors.transparent,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 