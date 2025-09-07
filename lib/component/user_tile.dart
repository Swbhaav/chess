import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String text;
  final void Function()? onTap;

  final String status;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blueAccent.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          selectedColor: Colors.blueAccent,
          style: ListTileStyle.list,
          onTap: onTap,
          leading: CircleAvatar(child: Icon(Icons.person)),
          title: Text(text),
          subtitle: Row(
            children: [
              Icon(Icons.circle, size: 12, color: _getStatusColor(status)),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase() == 'online') {
      return Colors.green;
    } else {
      return Colors.redAccent;
    }
  }

  UserTile({
    super.key,
    required this.text,
    required this.onTap,
    required this.status,
  });
}
