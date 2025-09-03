import 'package:chessgame/values/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String text;
  final void Function()? onTap;

  final String status;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      selectedColor: Colors.blueGrey,
      style: ListTileStyle.list,
      onTap: onTap,
      leading: CircleAvatar(child: Icon(Icons.person)),
      title: Text(text),
      subtitle: Row(
        children: [
          Icon(Icons.circle, size: 12, color: _getStatusColor(status)),
        ],
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
