import 'package:flutter/material.dart';

class MessageOptionsWidget extends StatelessWidget {
  final String messageId;
  final Function() onDelete;
  final Function() onEdit;

  const MessageOptionsWidget({
    Key? key,
    required this.messageId,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Message'),
            onTap: onEdit,
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Message'),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
} 