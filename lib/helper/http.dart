import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'common.dart';
import 'log.dart';

class HttpHelper {
  static Future<http.Response?> get(url, {String token = ""}) async {
    try {
      return await http.get(
        Uri.parse(url),
        headers: {'Authorization': token},
      );
    } catch (e) {
      debug('http get error\n$url\n$e');
      return null;
    }
  }

  static Future<http.Response?> post(url, data, {String token = ""}) async {
    try {
      return await http.post(Uri.parse(url),
          headers: {'Authorization': token, 'Content-Type': 'application/json'},
          body: json.encode(data));
    } catch (e) {
      debug('http post error\n$url\n$data\n$e');
      return null;
    }
  }

  static Future<http.Response?> patch(url, data, {String token = ""}) async {
    // print(json.encode(data));
    try {
      return await http.patch(Uri.parse(url),
          headers: {'Authorization': token, 'Content-Type': 'application/json'},
          body: json.encode(data));
    } catch (e) {
      debug('http patch error\n$url\n$data\n$e');
      return null;
    }
  }

  static Future<http.Response?> put(url, String file,
      {String token = ""}) async {
    File f = await FileHelper.getFile(file);
    // var a = await _getToken();
    var x = await f.readAsBytes();
    try {
      return await http.put(Uri.parse(url),
          headers: {
            'Authorization': token,
            'Content-Length': '${f.lengthSync()}'
          },
          body: x);
    } catch (e) {
      debug('http put error\n$url\n$e');
      return null;
    }
  }

  static Future<http.Response?> putfile(url, File file,
      {String token = ""}) async {
    // File f = await FileHelper.getFile(file);
    // var a = await _getToken();
    var x = await file.readAsBytes();
    try {
      return await http.put(Uri.parse(url),
          headers: {
            'Authorization': token,
            'Content-Length': '${file.lengthSync()}'
          },
          body: x);
    } catch (e) {
      debug('http putfile error\n$url\n$e');
      return null;
    }
  }

  static Future<http.Response?> patchfile(url, File file,
      {String token = ""}) async {
    var x = await file.readAsBytes();
    try {
      return await http.patch(Uri.parse(url),
          headers: {
            'Authorization': token,
            'Content-Length': '${file.lengthSync()}'
          },
          body: x);
    } catch (e) {
      debug('http patchfile error\n$url\n$e');
      return null;
    }
  }
}
