import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as pimage;
// import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart'; // for date format
import 'package:crypto/crypto.dart';

import 'log.dart';

String logfilename = "";

class ImageHelper {
  static String imageToBase64(String file, {int quality = 100}) {
    if (quality == 100) {
      var imageBytes = File(file).readAsBytesSync();
      print('图片大小:${imageBytes.length}');
      return base64Encode(imageBytes);
    } else {
      var x = pimage.decodeImage(File(file).readAsBytesSync());
      if (x == null) return "";
      var thumbnail = pimage.copyResize(x, width: 800);
      var zx = pimage.encodeJpg(thumbnail, quality: 90);
      return base64Encode(zx);
    }
  }

  static imagelistToBase64(Uint8List? file, {int quality = 100}) {
    if (file == null || file.length == 0) return null;
    if (quality == 100) {
      print('图片大小:${file.length}');
      return base64Encode(file);
    } else {
      var x = pimage.decodeImage(file);
      if (x == null) return "";
      
      var zx = pimage.encodeJpg(x, quality: quality);
      return base64Encode(zx);
    }
  }

  static Image listToImage(Uint8List file) {
    return Image.memory(file);
  }
  
  static Uint8List base64ToImage(String base64Str) {
    return const Base64Decoder().convert(base64Str);
  }
}

class MessageBoxHelper {
  static alert(contextx, String title, String content, String colsetext,
      [onOK]) async {
    showCupertinoDialog(
        context: contextx,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text(colsetext),
                onPressed: () {
                  Navigator.pop(context, true);
                  if (onOK != null) {
                    onOK();
                  }
                },
              ),
            ],
          );
        });
  }

  static confirm(contextx, String title, String content, String confirmtext,
      String canceltext,
      {Function? onOK, Function? onCancel}) async {
    confirmWidget(contextx, title, Text(content), confirmtext, canceltext, onOK,
        onCancel);
  }

  static confirmWidget(contextx, title, Widget content, confirmtext, canceltext,
      [Function? onOK, Function? onCancel]) async {
    showCupertinoDialog(
        context: contextx,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text('$title'),
            content: content,
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text(canceltext),
                onPressed: () {
                  Navigator.pop(context, true);
                  if (onCancel != null) {
                    onCancel();
                  }
                },
              ),
              CupertinoDialogAction(
                child: Text(confirmtext),
                onPressed: () {
                  Navigator.pop(context, true);
                  if (onOK != null) {
                    onOK();
                  }
                },
              ),
            ],
          );
        });
    return;
  }

  static showToast(String msg) {
    EasyLoading.showToast(msg);
  }

  static hideToast() {
    EasyLoading.dismiss();
  }
}

class DateTimeHelper {
  static formatdatetime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  static formatdate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

class FileHelper {
  static documentPath() async {
    return (await getApplicationDocumentsDirectory()).path;
  }

  static writeTextFile(String path, String content) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/$path');
    await file.writeAsString(content);
  }

  static Future<String> readTextFile(String path) async {
    late String text;
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/$path');
      text = await file.readAsString();
    } catch (e) {
      debug("Couldn't read file $path");
    }
    return text;
  }

  static Future<File> getFile(String path) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$path');
  }

  static delFile(String path) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/$path');
    await file.delete();
  }

  static Future Sha1(File file) async {
    // Hash hasher;
    return (await sha1.bind(file.openRead()).first).toString();
  }
}