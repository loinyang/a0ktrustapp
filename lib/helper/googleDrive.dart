// import 'driver/src/client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'common.dart';
import 'http.dart';
// import 'log.dart';

class GoogleDrive {
  String appIdentify = 'a0ktrust';
  final int pagesize = 1000;

  Future<List> listGDriveFilesInFolder(String token, String path) async {
    return await _get(token, '', parentid: await getFolderId(token, path));
  }

  Future getFolderId(String token, String path) async {
    var _folders = path.split('/').where((e) => e != "").toList();
    var folders = await _get(token, '', folders: _folders, onlyFolder: true);
    var pid = "";
    for (var i = 0; i < _folders.length; i++) {
      var y = folders.where((e) => e['name'] == _folders[i]).toList();
      if (y.isEmpty == true) {
        pid = await _createFolder(token, _folders[i], parentid: pid);
      } else {
        pid = y[0]['id'];
      }
    }
    return pid;
  }

  Future<List<dynamic>> _get(String token, String q,
      {List<String>? folders,
      bool onlyFolder = false,
      String parentid = ''}) async {
    var q =
        "trashed = false and properties has {key='$appIdentify' and value=''} ";
    if (onlyFolder == true) {
      q += " and mimeType = 'application/vnd.google-apps.folder'";
    }
    if (parentid != '') {
      q += " and parents in '$parentid'";
    }
    String x = "";
    if (folders != null && folders.isEmpty == false) {
      for (var item in folders) {
        if (x == '') {
          x = " name = '$item'";
        } else {
          x += " or name = '$item'";
        }
      }
    }
    if (x != "") q += " and ($x)";
    // debug('list file or folder -> $token $q');
    q = Uri.encodeQueryComponent(q);

    List<dynamic> r = [];
    String nextPageToken = "";
    var fields =
        "id,name,description,parents,size,createdTime,modifiedTime,properties";
    do {
      var response = await HttpHelper.get(
          'https://www.googleapis.com/drive/v3/files?q=${q}&orderBy=modifiedTime&fields=nextPageToken,files($fields)&spaces=drive&pageToken=$nextPageToken&pageSize=$pagesize',
          token: token);
      if (response == null || response.statusCode != 200) {
        // debug(
        //     'Driver File API ERROR ${response.statusCode} response: ${response.body}');
        return [];
      }
      var result = json.decode(response.body);
      if (result == null) return [];

      nextPageToken = result['nextPageToken'] ?? "";

      if (result['files'] != null) {
        r.addAll(result['files']);
      }
      if (nextPageToken == null ||
          nextPageToken == '' ||
          result['files'].length == 0) break;
    } while (true);

    return r;
  }

  Future getGDriveFile(String token, fileid) async {
    var response = await HttpHelper.get(
        'https://www.googleapis.com/drive/v3/files/' + fileid + '?alt=media',
        token: token);

    if (response == null || response.statusCode != 200) return null;
    return json.decode(utf8.decode(response.bodyBytes));
  }

  Future _createFolder(String token, String folderName,
      {String parentid = ''}) async {
    var response = await HttpHelper.post(
        'https://www.googleapis.com/drive/v3/files?q=mimeType%3D%27application%2Fvnd.google-apps.folder%27&spaces=drive',
        {
          'name': folderName,
          'mimeType': 'application/vnd.google-apps.folder',
          'parents': parentid != '' ? [parentid] : [],
          'properties': {appIdentify: ''},
        },
        token: token);
    if (response == null || response.statusCode != 200) return null;
    var base = json.decode(response.body);
    return base['id'];
  }

  uploadFile(context, token, folderid, fileid, File file) async {
    var data = {
      'name': basename(file.path),
      'properties': {appIdentify: '', 'sha1': await FileHelper.Sha1(file)},
      'parents': [folderid]
    };
    if (fileid != '') {
      data = {
        'id': fileid,
        'name': basename(file.path),
        'properties': {appIdentify: '', 'sha1': await FileHelper.Sha1(file)},
        'parents': [folderid]
      };
    }
    var response = await HttpHelper.post(
        'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable',
        data,
        token: token);
    if (response == null || response.statusCode != 200) {
      // debug(
      //     'Driver File API ERROR ${response.statusCode} response: ${response.body}');
      return;
    }
    var uploadUrl = response.headers['location'];
    if (fileid != '') {
      await HttpHelper.patchfile(uploadUrl, file, token: token);
    } else {
      await HttpHelper.putfile(uploadUrl, file, token: token);
    }
  }
}
