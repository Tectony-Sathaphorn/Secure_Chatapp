import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'create_new_chat_model.dart';
export 'create_new_chat_model.dart';

class CreateNewChatWidget extends StatefulWidget {
  const CreateNewChatWidget({super.key});

  @override
  State<CreateNewChatWidget> createState() => _CreateNewChatWidgetState();
}

class _CreateNewChatWidgetState extends State<CreateNewChatWidget> {
  late CreateNewChatModel _model;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CreateNewChatModel());
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 5.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0.0),
          bottomRight: Radius.circular(0.0),
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.85, // Set max height
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(0.0),
            bottomRight: Radius.circular(0.0),
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
              child: Container(
                width: 50.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'เลือกผู้ใช้',
                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                          fontFamily: 'Inter Tight',
                          letterSpacing: 0.0,
                        ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Search field
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
              child: Container(
                width: double.infinity,
                height: 50.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: FlutterFlowTheme.of(context).alternate,
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        size: 24.0,
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: TextFormField(
                          controller: _searchController,
                          obscureText: false,
                          decoration: InputDecoration(
                            hintText: 'ค้นหาตามชื่อผู้ใช้...',
                            hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'Inter',
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                ),
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                          ),
                          style: FlutterFlowTheme.of(context).bodyMedium,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                          child: Icon(
                            Icons.close_rounded,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 24.0,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            // User list - wrap in Expanded to take remaining space
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
                child: StreamBuilder<List<UsersRecord>>(
                  stream: queryUsersRecord(),
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
                    List<UsersRecord> allUsers = snapshot.data!
                        .where((u) => u.uid != currentUserUid)
                        .toList();
                        
                    // Filter users by search query
                    List<UsersRecord> listViewUsersRecordList = allUsers
                        .where((user) => _searchQuery.isEmpty || 
                            user.displayName.toLowerCase().contains(_searchQuery))
                        .toList();
                    
                    if (listViewUsersRecordList.isEmpty) {
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

                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      primary: false,
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      itemCount: listViewUsersRecordList.length,
                      itemBuilder: (context, listViewIndex) {
                        final listViewUsersRecord =
                            listViewUsersRecordList[listViewIndex];
                        return Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 12.0, 16.0, 0.0),
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              // ตรวจสอบว่ามีแชทระหว่างผู้ใช้นี้อยู่แล้วหรือไม่
                              final existingChats = await queryChatsRecordOnce(
                                queryBuilder: (chatsRecord) => chatsRecord
                                    .where('userIds', arrayContains: currentUserReference)
                                    .orderBy('timeStamp', descending: true),
                              );
                              
                              // ค้นหาแชทที่มีผู้ใช้ทั้งสองคนอยู่แล้ว
                              ChatsRecord? existingChat;
                              for (var chat in existingChats) {
                                if (chat.userIds.contains(listViewUsersRecord.reference)) {
                                  existingChat = chat;
                                  break;
                                }
                              }
                              
                              if (existingChat != null) {
                                // ถ้ามีแชทอยู่แล้ว ให้นำทางไปยังแชทเดิม
                                Navigator.pop(context);
                                
                                context.pushNamed(
                                  'chatPage',
                                  queryParameters: {
                                    'recieveChat': serializeParam(
                                      existingChat.reference,
                                      ParamType.DocumentReference,
                                    ),
                                  }.withoutNulls,
                                  extra: <String, dynamic>{
                                    'chatUser': listViewUsersRecord,
                                  },
                                );
                              } else {
                                // ถ้ายังไม่มีแชท ให้สร้างแชทใหม่
                                try {
                                  await ChatsRecord.collection.doc().set({
                                    ...createChatsRecordData(
                                      lastMessage: 'Say hello!',
                                      timeStamp: getCurrentTimestamp,
                                    ),
                                    ...mapToFirestore(
                                      {
                                        'userIds': functions.generateListOfUsers(
                                            currentUserReference!,
                                            listViewUsersRecord.reference),
                                        'userNames': functions.generateListOfName(
                                            currentUserDisplayName,
                                            listViewUsersRecord.displayName),
                                      },
                                    ),
                                  });
                                  Navigator.pop(context);
                                } catch (e) {
                                  print('Error creating chat: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้างแชท: $e')),
                                  );
                                }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).alternate,
                                  width: 2.0,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 12.0, 8.0, 12.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Container(
                                          width: 60.0, // Adjusted size
                                          height: 60.0, // Adjusted size
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                          ),
                                          child: listViewUsersRecord.photoUrl.isEmpty
                                              ? CircleAvatar(
                                                  backgroundColor: FlutterFlowTheme.of(context).primary,
                                                  child: Text(
                                                    listViewUsersRecord.displayName != null && 
                                                    listViewUsersRecord.displayName.isNotEmpty
                                                        ? listViewUsersRecord.displayName[0].toUpperCase()
                                                        : '?',
                                                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                          fontFamily: 'Inter',
                                                          color: Colors.white,
                                                          fontSize: 24,
                                                        ),
                                                  ),
                                                )
                                              : Image.network(
                                                  listViewUsersRecord.photoUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return CircleAvatar(
                                                      backgroundColor: FlutterFlowTheme.of(context).primary,
                                                      child: Text(
                                                        listViewUsersRecord.displayName != null && 
                                                        listViewUsersRecord.displayName.isNotEmpty
                                                            ? listViewUsersRecord.displayName[0].toUpperCase()
                                                            : '?',
                                                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                              fontFamily: 'Inter',
                                                              color: Colors.white,
                                                              fontSize: 24,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                        Padding(
                                          padding: EdgeInsetsDirectional.fromSTEB(
                                              20.0, 0.0, 0.0, 0.0),
                                          child: Text(
                                            listViewUsersRecord.displayName,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyLarge
                                                .override(
                                                  fontFamily: 'Inter',
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFF7C8791),
                                      size: 30.0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
