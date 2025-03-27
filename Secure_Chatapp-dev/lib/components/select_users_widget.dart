import 'package:flutter/material.dart';

class SelectUsersWidget extends StatefulWidget {
  final Function(List<String>) onUsersSelected;
  final List<String> initialSelectedUsers;

  const SelectUsersWidget({
    Key? key,
    required this.onUsersSelected,
    this.initialSelectedUsers = const [],
  }) : super(key: key);

  @override
  State<SelectUsersWidget> createState() => _SelectUsersWidgetState();
}

class _SelectUsersWidgetState extends State<SelectUsersWidget> {
  final List<String> selectedUsers = [];

  @override
  void initState() {
    super.initState();
    selectedUsers.addAll(widget.initialSelectedUsers);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Users',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Add user list here
          ElevatedButton(
            onPressed: () {
              widget.onUsersSelected(selectedUsers);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
} 