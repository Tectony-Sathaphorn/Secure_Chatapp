import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/create_new_chat/create_new_chat_widget.dart';
import '/pages/create_group_chat/create_group_chat_widget.dart';
import '/app_state.dart';
import 'dart:math';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'home_page_model.dart';
export 'home_page_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget>
    with TickerProviderStateMixin {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentTabIndex = 0; // 0 = ส่วนตัว, 1 = กลุ่ม
  
  // Key for saving tab index in preferences
  static const String _tabIndexKey = 'current_tab_index';

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    
    // Get saved tab index if available
    _loadSavedTabIndex();

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        loop: true,
        reverse: true,
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(1.0, 1.0),
            end: Offset(1.3, 1.3),
          ),
        ],
      ),
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (_currentTabIndex == 0) {
              // ไปที่หน้าสร้างแชทใหม่
              context.pushNamed(
                'createNewChat',
              );
            } else {
              // ไปที่หน้าสร้างกลุ่มแชทใหม่
              context.pushNamed(
                'createGroupChat',
              );
            }
          },
          backgroundColor: FlutterFlowTheme.of(context).primary,
          elevation: 8.0,
          child: Icon(
            _currentTabIndex == 0 ? Icons.chat_outlined : Icons.group_add,
            color: Colors.white,
            size: 24.0,
          ),
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: double.infinity,
                height: 63.49,
                decoration: BoxDecoration(),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(15.0, 0.0, 0.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              'แชท',
                              style: FlutterFlowTheme.of(context)
                                  .headlineLarge
                                  .override(
                                    fontFamily: 'Inter Tight',
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 34.0,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        AuthUserStreamWidget(
                          builder: (context) => Container(
                            width: 45.0,
                            height: 45.0,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: currentUserPhoto != null &&
                                    currentUserPhoto != ''
                                ? Image.network(
                                    currentUserPhoto,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: FlutterFlowTheme.of(context).primary,
                                        child: Center(
                                          child: Text(
                                            currentUserDisplayName != null && currentUserDisplayName.isNotEmpty
                                                ? currentUserDisplayName.substring(0, 1).toUpperCase()
                                                : '?',
                                            style: FlutterFlowTheme.of(context).titleLarge.override(
                                              fontFamily: 'Inter',
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: FlutterFlowTheme.of(context).primary,
                                    child: Center(
                                      child: Text(
                                        currentUserDisplayName != null && currentUserDisplayName.isNotEmpty
                                            ? currentUserDisplayName
                                                .substring(0, 1)
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
                          ),
                        ),
                        SizedBox(width: 15),
                      ],
                    ),
                  ],
                ),
              ),
              
              // แท็บแสดงประเภทแชท
              Container(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTabButton(0, 'แชทส่วนตัว'),
                    _buildTabButton(1, 'แชทกลุ่ม'),
                  ],
                ),
              ),
              Divider(
                height: 1.0,
                thickness: 1.0,
                color: FlutterFlowTheme.of(context).alternate,
              ),
              
              // ช่องค้นหา
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(15.0, 5.0, 15.0, 5.0),
                child: Container(
                  width: double.infinity,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 8.0, 0.0),
                          child: Icon(
                            Icons.search_rounded,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 22.5,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                4.0, 0.0, 0.0, 0.0),
                            child: TextFormField(
                              controller: _model.textController,
                              focusNode: _model.textFieldFocusNode,
                              obscureText: false,
                              decoration: InputDecoration(
                                labelText: 'ค้นหา...',
                                labelStyle:
                                    FlutterFlowTheme.of(context).labelMedium,
                                hintStyle:
                                    FlutterFlowTheme.of(context).labelMedium,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                              ),
                              style: FlutterFlowTheme.of(context).bodyMedium,
                              validator: _model.textControllerValidator
                                  .asValidator(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // เนื้อหาตามแท็บที่เลือก
              Expanded(
                child: _currentTabIndex == 0
                    ? _buildPrivateChatList()
                    : _buildGroupChatList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // สร้างปุ่มแท็บ
  Widget _buildTabButton(int index, String title) {
    final isSelected = _currentTabIndex == index;
    return InkWell(
      onTap: () {
        _saveTabIndex(index);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? FlutterFlowTheme.of(context).primary
                  : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Text(
          title,
          style: FlutterFlowTheme.of(context).titleMedium.override(
                fontFamily: 'Inter',
                color: isSelected
                    ? FlutterFlowTheme.of(context).primary
                    : FlutterFlowTheme.of(context).secondaryText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }

  // Load saved tab index from preferences
  Future<void> _loadSavedTabIndex() async {
    try {
      final savedIndex = FFAppState().getValue(_tabIndexKey);
      if (savedIndex != null) {
        setState(() {
          _currentTabIndex = savedIndex as int;
        });
      }
    } catch (e) {
      print('Error loading saved tab index: $e');
    }
  }
  
  // Save current tab index to preferences
  Future<void> _saveTabIndex(int index) async {
    try {
      FFAppState().setValue(_tabIndexKey, index);
      setState(() {
        _currentTabIndex = index;
      });
    } catch (e) {
      print('Error saving tab index: $e');
      // Fallback - just update state
      setState(() {
        _currentTabIndex = index;
      });
    }
  }

  // แสดงรายการแชทส่วนตัว
  Widget _buildPrivateChatList() {
    return StreamBuilder<List<ChatsRecord>>(
      stream: queryChatsRecord(
        queryBuilder: (chatsRecord) => chatsRecord
            .where('userIds', arrayContains: currentUserReference)
            .orderBy('timeStamp', descending: true),
      ),
      builder: (context, snapshot) {
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
        
        List<ChatsRecord> listViewChatsRecordList = snapshot.data!;
        if (listViewChatsRecordList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  size: 60,
                ),
                SizedBox(height: 16),
                Text(
                  'ยังไม่มีแชทส่วนตัว',
                  style: FlutterFlowTheme.of(context).titleMedium,
                ),
                SizedBox(height: 8),
                Text(
                  'เริ่มแชทใหม่โดยกดปุ่ม + ด้านล่าง',
                  style: FlutterFlowTheme.of(context).bodyMedium,
                ),
              ],
            ),
          );
        }
        
        // แสดงรายการแชท
        return ListView.builder(
          padding: EdgeInsets.zero,
          scrollDirection: Axis.vertical,
          itemCount: listViewChatsRecordList.length,
          itemBuilder: (context, listViewIndex) {
            final listViewChatsRecord =
                listViewChatsRecordList[listViewIndex];
            return Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 1.0, 0.0, 0.0),
              child: InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  context.pushNamed(
                    'chatPage',
                    queryParameters: {
                      'recieveChat': serializeParam(
                        listViewChatsRecord.reference,
                        ParamType.DocumentReference,
                      ),
                    }.withoutNulls,
                  );
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(15.0, 8.0, 15.0, 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 12.0, 0.0),
                          child: Container(
                            width: 45.0,
                            height: 45.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).alternate,
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Text(
                                    functions
                                            .getOtherUserName(
                                                listViewChatsRecord.userNames != null 
                                                    ? listViewChatsRecord.userNames.toList() 
                                                    : [],
                                                currentUserDisplayName)
                                            .isNotEmpty
                                        ? functions
                                            .getOtherUserName(
                                                listViewChatsRecord.userNames != null 
                                                    ? listViewChatsRecord.userNames.toList() 
                                                    : [],
                                                currentUserDisplayName)
                                            .substring(0, 1)
                                            .toUpperCase()
                                        : '?',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Inter',
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ),
                                if (listViewChatsRecord.lastMessageSeenBy != null &&
                                    !listViewChatsRecord.lastMessageSeenBy
                                        .contains(currentUserReference))
                                  Align(
                                    alignment: AlignmentDirectional(1.0, -1.0),
                                    child: Container(
                                      width: 12.0,
                                      height: 12.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ).animateOnPageLoad(animationsMap[
                                        'containerOnPageLoadAnimation']!),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      functions.getOtherUserName(
                                          listViewChatsRecord.userNames != null 
                                              ? listViewChatsRecord.userNames.toList() 
                                              : [],
                                          currentUserDisplayName).isNotEmpty
                                          ? functions.getOtherUserName(
                                              listViewChatsRecord.userNames != null 
                                                  ? listViewChatsRecord.userNames.toList() 
                                                  : [],
                                              currentUserDisplayName)
                                          : 'Unknown User',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Inter',
                                            fontSize: 17.0,
                                            letterSpacing: 0.0,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    dateTimeFormat(
                                        'relative',
                                        listViewChatsRecord.timeStamp!),
                                    style: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .override(
                                          fontFamily: 'Inter',
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 5.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      flex: 1,
                                      fit: FlexFit.tight,
                                      child: Text(
                                        listViewChatsRecord.lastMessage,
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'Inter',
                                              color: FlutterFlowTheme.of(context)
                                                  .secondaryText,
                                              letterSpacing: 0.0,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  // แสดงรายการแชทกลุ่ม
  Widget _buildGroupChatList() {
    return StreamBuilder<List<GroupChatsRecord>>(
      stream: queryGroupChatsRecord(
        queryBuilder: (groupChatsRecord) => groupChatsRecord
            .where('userIds', arrayContains: currentUserReference)
            .orderBy('timeStamp', descending: true),
      ),
      builder: (context, snapshot) {
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
        
        List<GroupChatsRecord> listViewGroupChatsRecordList = snapshot.data!;
        if (listViewGroupChatsRecordList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.group,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  size: 60,
                ),
                SizedBox(height: 16),
                Text(
                  'ยังไม่มีแชทกลุ่ม',
                  style: FlutterFlowTheme.of(context).titleMedium,
                ),
                SizedBox(height: 8),
                Text(
                  'สร้างกลุ่มใหม่โดยกดปุ่ม + ด้านล่าง',
                  style: FlutterFlowTheme.of(context).bodyMedium,
                ),
              ],
            ),
          );
        }
        
        // แสดงรายการแชทกลุ่ม
        return ListView.builder(
          padding: EdgeInsets.zero,
          scrollDirection: Axis.vertical,
          itemCount: listViewGroupChatsRecordList.length,
          itemBuilder: (context, listViewIndex) {
            final groupChat = listViewGroupChatsRecordList[listViewIndex];
            return Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 1.0, 0.0, 0.0),
              child: InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  context.pushNamed(
                    'groupChatPage',
                    queryParameters: {
                      'groupChatRef': serializeParam(
                        groupChat.reference,
                        ParamType.DocumentReference,
                      ),
                    }.withoutNulls,
                  );
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(15.0, 8.0, 15.0, 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 12.0, 0.0),
                          child: Container(
                            width: 45.0,
                            height: 45.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primary,
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: groupChat.groupPhoto.isEmpty
                                      ? Icon(
                                          Icons.group,
                                          color: Colors.white,
                                          size: 24.0,
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(22.5),
                                          child: Image.network(
                                            groupChat.groupPhoto,
                                            width: 45.0,
                                            height: 45.0,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.group,
                                                color: Colors.white,
                                                size: 24.0,
                                              );
                                            },
                                          ),
                                        ),
                                ),
                                if (groupChat.lastMessageSeenBy != null &&
                                    !groupChat.lastMessageSeenBy.contains(currentUserReference))
                                  Align(
                                    alignment: AlignmentDirectional(1.0, -1.0),
                                    child: Container(
                                      width: 12.0,
                                      height: 12.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context).error,
                                        shape: BoxShape.circle,
                                      ),
                                    ).animateOnPageLoad(
                                        animationsMap['containerOnPageLoadAnimation']!),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      groupChat.groupName,
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                            fontFamily: 'Inter',
                                            fontSize: 17.0,
                                            letterSpacing: 0.0,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    dateTimeFormat('relative', groupChat.timeStamp!),
                                    style:
                                        FlutterFlowTheme.of(context).labelSmall.override(
                                              fontFamily: 'Inter',
                                              color: FlutterFlowTheme.of(context)
                                                  .secondaryText,
                                              letterSpacing: 0.0,
                                            ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(0.0, 5.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      flex: 1,
                                      fit: FlexFit.tight,
                                      child: Text(
                                        groupChat.lastMessage,
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'Inter',
                                              color: FlutterFlowTheme.of(context)
                                                  .secondaryText,
                                              letterSpacing: 0.0,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(0.0, 5.0, 0.0, 0.0),
                                child: Text(
                                  '${groupChat.userNames != null ? groupChat.userNames.length : 0} สมาชิก',
                                  style: FlutterFlowTheme.of(context).bodySmall.override(
                                        fontFamily: 'Inter',
                                        color: FlutterFlowTheme.of(context).primary,
                                        fontSize: 11.0,
                                      ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
