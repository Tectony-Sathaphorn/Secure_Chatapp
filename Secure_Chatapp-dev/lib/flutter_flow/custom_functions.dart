import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';

List<DocumentReference> generateListOfUsers(
  DocumentReference authUser,
  DocumentReference otherUser,
) {
  return [authUser, otherUser];
}

List<String> generateListOfName(
  String authUserName,
  String otherUserName,
) {
  return [authUserName, otherUserName];
}

DocumentReference getOtherUserRef(
  List<DocumentReference> listOfUserRefs,
  DocumentReference authUserRefs,
) {
  return authUserRefs == listOfUserRefs.first
      ? listOfUserRefs.last
      : listOfUserRefs.first;
}

String getOtherUser(
  List<String> listOfNames,
  String authUserName,
) {
  return authUserName == listOfNames.first
      ? listOfNames.last
      : listOfNames.first;
}

String getOtherUserName(List<String> users, String currentUserName) {
  if (users.isEmpty) return '';
  final otherUser = users.firstWhere(
    (name) => name != currentUserName,
    orElse: () => '',
  );
  return otherUser;
}

String getInitials(String fullName) {
  if (fullName.isEmpty) return '';
  final names = fullName.split(' ');
  if (names.length > 1) {
    return '${names[0][0]}${names[1][0]}'.toUpperCase();
  }
  return names[0][0].toUpperCase();
}
