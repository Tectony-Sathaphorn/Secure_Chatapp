import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class GroupChatsRecord extends FirestoreRecord {
  GroupChatsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "groupName" field.
  String? _groupName;
  String get groupName => _groupName ?? '';
  bool hasGroupName() => _groupName != null;

  // "groupPhoto" field.
  String? _groupPhoto;
  String get groupPhoto => _groupPhoto ?? '';
  bool hasGroupPhoto() => _groupPhoto != null;

  // "userIds" field.
  List<DocumentReference>? _userIds;
  List<DocumentReference> get userIds => _userIds ?? const [];
  bool hasUserIds() => _userIds != null;

  // "userNames" field.
  List<String>? _userNames;
  List<String> get userNames => _userNames ?? const [];
  bool hasUserNames() => _userNames != null;

  // "ownerId" field.
  DocumentReference? _ownerId;
  DocumentReference? get ownerId => _ownerId;
  bool hasOwnerId() => _ownerId != null;

  // "lastMessage" field.
  String? _lastMessage;
  String get lastMessage => _lastMessage ?? '';
  bool hasLastMessage() => _lastMessage != null;

  // "timeStamp" field.
  DateTime? _timeStamp;
  DateTime? get timeStamp => _timeStamp;
  bool hasTimeStamp() => _timeStamp != null;

  // "lastMessageSeenBy" field.
  List<DocumentReference>? _lastMessageSeenBy;
  List<DocumentReference> get lastMessageSeenBy =>
      _lastMessageSeenBy ?? const [];
  bool hasLastMessageSeenBy() => _lastMessageSeenBy != null;

  // "createdAt" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _groupName = snapshotData['groupName'] as String?;
    _groupPhoto = snapshotData['groupPhoto'] as String?;
    _userIds = getDataList(snapshotData['userIds']);
    _userNames = getDataList(snapshotData['userNames']);
    _ownerId = snapshotData['ownerId'] as DocumentReference?;
    _lastMessage = snapshotData['lastMessage'] as String?;
    _timeStamp = snapshotData['timeStamp'] as DateTime?;
    _lastMessageSeenBy = getDataList(snapshotData['lastMessageSeenBy']);
    _createdAt = snapshotData['createdAt'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('groupChats');

  static Stream<GroupChatsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => GroupChatsRecord.fromSnapshot(s));

  static Future<GroupChatsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => GroupChatsRecord.fromSnapshot(s));

  static GroupChatsRecord fromSnapshot(DocumentSnapshot snapshot) => GroupChatsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static GroupChatsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      GroupChatsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'GroupChatsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is GroupChatsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createGroupChatsRecordData({
  String? groupName,
  String? groupPhoto,
  DocumentReference? ownerId,
  String? lastMessage,
  DateTime? timeStamp,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'groupName': groupName,
      'groupPhoto': groupPhoto,
      'ownerId': ownerId,
      'lastMessage': lastMessage,
      'timeStamp': timeStamp,
      'createdAt': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class GroupChatsRecordDocumentEquality implements Equality<GroupChatsRecord> {
  const GroupChatsRecordDocumentEquality();

  @override
  bool equals(GroupChatsRecord? e1, GroupChatsRecord? e2) {
    const listEquality = ListEquality();
    return e1?.groupName == e2?.groupName &&
        e1?.groupPhoto == e2?.groupPhoto &&
        listEquality.equals(e1?.userIds, e2?.userIds) &&
        listEquality.equals(e1?.userNames, e2?.userNames) &&
        e1?.ownerId == e2?.ownerId &&
        e1?.lastMessage == e2?.lastMessage &&
        e1?.timeStamp == e2?.timeStamp &&
        listEquality.equals(e1?.lastMessageSeenBy, e2?.lastMessageSeenBy) &&
        e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(GroupChatsRecord? e) => const ListEquality().hash([
        e?.groupName,
        e?.groupPhoto,
        e?.userIds,
        e?.userNames,
        e?.ownerId,
        e?.lastMessage,
        e?.timeStamp,
        e?.lastMessageSeenBy,
        e?.createdAt
      ]);

  @override
  bool isValidKey(Object? o) => o is GroupChatsRecord;
} 