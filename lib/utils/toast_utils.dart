import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
class ToastUtils {
  static void show(String message) async {
    await Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.CENTER,
      // timeInSecForIosWeb: _toastDuration.inSeconds,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showFromBottom(String message) async {
    await Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.BOTTOM,
      // timeInSecForIosWeb: _toastDuration.inSeconds,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showDialog(
      BuildContext context, String title, String message) async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(
          message,
          textAlign: TextAlign.left,
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
