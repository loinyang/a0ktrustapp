import 'dart:async';
import 'dart:io';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path/path.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:a0ktrust/helper/googleDrive.dart';
import 'common.dart';
import 'dart:convert';
import 'http.dart';
import 'package:http/http.dart' as http;
import 'log.dart';

class GoogleContact {
  String gDriverContactFolder = "/a0ktrust/Contact";
  String gDriverImageFolder = "/a0ktrust/Image";
  final int maxContactCount = 200;

  final Duration toastDelay = const Duration(minutes: 10);

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/contacts',
      'https://www.googleapis.com/auth/drive',
    ],
  );

  StreamController _fetchDoneController = new StreamController.broadcast();
  Stream get fetchDone => _fetchDoneController.stream;

  GoogleContact() {
    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      currentUser = account;
      getAllContact();
    });
    _googleSignIn.signInSilently();
  }

  void signIn() async {
    try {
      debug('currentUser1 $currentUser ');
      await _googleSignIn.signIn();
      // _fetchDoneController.add('event');
    } catch (error) {
      debug('signIn error->$error');
    }
  }

  void signOut() async {
    _googleSignIn.disconnect();
    currentUser = null;
  }

  GoogleSignInAccount? currentUser;

  getAllContact() async {
    List r = [];
    String nextPageToken = "";
    do {
      var response = await HttpHelper.get(
          'https://people.googleapis.com/v1/people/me/connections?pageToken=$nextPageToken&pageSize=100&personFields=names,userDefined,emailAddresses,phoneNumbers,photos',
          token: await _getToken());
      if (response == null || response.statusCode != 200) {
        // print('People API ${response.statusCode} response: ${response.body}');
        return null;
      }
      var result = json.decode(response.body);
      if (result == null) {
        return null;
        // break;
      }
      nextPageToken = result['nextPageToken'] ?? "";
      // print('People API $nextPageToken $result $r');
      if (result['connections'] != null) {
        r.addAll(result['connections']);
      }
      if (nextPageToken == null || nextPageToken == '') break;
    } while (true);

    _fetchDoneController.add(r);
    return r;
  }

  Future<http.Response?> uploadToGamil(List a) async {
    await cleanGmailContact();
    return await HttpHelper.post(
        'https://people.googleapis.com/v1/people:batchCreateContacts',
        {'readMask': 'userDefined', 'contacts': a},
        token: await _getToken());
  }

  uploadContact(List contacts) async {
    await cleanGmailContact();
    int start = 0;
    String token = await _getToken();
    do {
      var upc =
          contacts.skip(start * maxContactCount).take(maxContactCount).toList();
      if (upc.isEmpty) break;
      debug(start);

      var y = await HttpHelper.post(
          'https://people.googleapis.com/v1/people:batchCreateContacts',
          {'readMask': 'userDefined', 'contacts': upc},
          token: token);
      debug(y?.body);
      if (y == null) {
        MessageBoxHelper.alert(context, 'Error', 'Upload contacts error', 'OK');
        return;
      }
      var uploadinfos = json
          .decode(y.body)['createdPeople']
          .map((a) => {
                'resourceName': a['person']['resourceName'],
                // 'userDefined1':a['person']['userDefined']?[0]['key'],
                'identifier': a['person']['userDefined']?[0]['value']
              })
          .toList();
      start++;
    } while (true);
  }

  updateContactPhoto(String resourceName, String base64) async {
    return await HttpHelper.patch(
        'https://people.googleapis.com/v1/${resourceName}:updateContactPhoto',
        {'photoBytes': base64},
        token: await _getToken());
  }

  cleanGmailContact() async {
    int delprecount = 500;
    var yyy = (await getAllContact()).map((a) => a['resourceName']).toList();
    
    if (yyy == null) return;
    do {
      var zzz = yyy.take(delprecount).toList();
      if (zzz.isEmpty) break;
      yyy = yyy.skip(delprecount).toList();
      var z = await HttpHelper.post(
          'https://people.googleapis.com/v1/people:batchDeleteContacts',
          {"resourceNames": zzz},
          token: await _getToken());
    } while (true);
  }

  Future<String> _getToken() async {
    var x = await currentUser?.authHeaders;
    if (x == null) return '';
    return x['Authorization'].toString();
  }

  Future<List> listGDriveFilesInFolder(String path) async {
    var files =
        await GoogleDrive().listGDriveFilesInFolder(await _getToken(), path);
    return files;
  }

  Future getGdriveFile(fileid) async {
    var response = await HttpHelper.get(
        'https://www.googleapis.com/drive/v3/files/' + fileid + '?alt=media',
        token: await _getToken());

    if (response == null || response.statusCode != 200) return null;
    return json.decode(utf8.decode(response.bodyBytes));
  }

  uploadSingleFiles(File file) async {
    var token = await _getToken();
    var folderid = await GoogleDrive().getFolderId(token, gDriverContactFolder);

    await GoogleDrive().uploadFile(context, token, folderid, '', file);
  }

  uploadFiles(context, List<File> files) async {
    var token = await _getToken();
    var nowimges =
        await GoogleDrive().listGDriveFilesInFolder(token, gDriverImageFolder);

    var folderid = await GoogleDrive().getFolderId(token, gDriverImageFolder);

    int i = 0;
    for (var item in files) {
      EasyLoading.showToast('uploading ${i + 1}/${files.length}... ',
          duration: toastDelay, maskType: EasyLoadingMaskType.black);

      var filename = basename(item.path);
      var fileinfo =
          nowimges.firstWhere((e) => e['name'] == filename, orElse: () {
        return null;
      });
      var fileid = '';
      if (fileinfo != null) {
        var sha1 = "";
        if (fileinfo['properties'] != null)
          sha1 = fileinfo['properties']['sha1'];
        var filesha1 = await FileHelper.Sha1(item);
        // debug('sha1-> $filesha1 server sha1->$sha1');
        if (filesha1 != sha1) {
          //debug('$filename $filesha1 $sha1 need update');
          fileid = fileinfo['id'];
        } else {
         // debug('$filename $filesha1 dont need update');
          continue;
        }
      } else {
        // debug('$filename need create');
        fileid = '';
      }
      // debug(await FileHelper.Sha1(item));
      await GoogleDrive().uploadFile(context, token, folderid, fileid, item);
      i++;
    }

    EasyLoading.showSuccess('done!');
  }
}
