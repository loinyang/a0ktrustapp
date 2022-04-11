import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http_proxy/http_proxy.dart';
import 'package:permission_handler/permission_handler.dart';
import 'helper/albumManager.dart';
import 'helper/common.dart';
import 'helper/googleApi.dart';
import 'helper/localContact.dart';
import 'helper/log.dart';
import 'helper/myPermission.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpProxy httpProxy = await HttpProxy.createHttpProxy();
  HttpOverrides.global = httpProxy;
  // print('${httpProxy.host}:${httpProxy.port}');

  logfilename = (await FileHelper.documentPath()) + DateTimeHelper.formatdate(DateTime.now())+".log";
  FlutterError.onError = (FlutterErrorDetails details) async {
    Zone.current.handleUncaughtError(
        details.exception, details.stack ?? StackTrace.empty);
  };

  runZonedGuarded(
      () => {
            runApp(MaterialApp(
              title: 'a0ktrust',
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
              home: A0ktrustPage(),
              builder: EasyLoading.init(),
            ))
          }, (error, stackTrace) async {
    await debug('unhandel error\n$error $stackTrace');
  });
}

class A0ktrustPage extends StatefulWidget {
  @override
  State createState() => A0ktrustPageState();
}

class A0ktrustPageState extends State<A0ktrustPage> {
  // final _scallfoldKey = GlobalKey<ScaffoldState>();
  var quality = 80;
  late GoogleContact gcc;
  late MyPermission myp;

  @override
  void initState() {
    super.initState();
    myp = MyPermission();
    myp.hasContactPermission.listen((event) async {
      // print('bbb->$event');
      _contactPermission = event == true;
      if (_contactPermission == true) {
        getLocalContactCount();
      }
      setState(() {});
    });
    gcc = GoogleContact();
    gcc.fetchDone.listen((event) {
      // print('aaa->$event');
      allcontact = event;
      setState(() {});
    });
    myp.askContactPermissions(context);
    askImagePermissions();
  }

  askImagePermissions() {
    myp.askImagePermissions(context, callback: () async {
      _imagePermission = true;
      _localimagecount = (await AlbumManager().listCameraImages()).length;
      setState(() {});
    });
  }

  late List<dynamic> allcontact = [];
  var _localcontactcount = 0;
  var _localimagecount = 0;
  Widget _buildBody() {
    // var x = [];
    // print(x[1]);
    // debug('$this');
    return ListView.separated(
        separatorBuilder: (a, b) {
          return const Divider();
        },
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: 4, // allcontact.length,
        itemBuilder: (context, index) {
          if (index == 0 && _contactPermission == false) {
            return InkWell(
                onTap: () {
                  // print('a');
                  myp.askContactPermissions(context);
                },
                child: const ListTile(
                  title: Text(
                      'Can not access address book,press me request the Permission.'),
                  leading: CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Text('L'),
                  ),
                  trailing: Icon(Icons.arrow_right),
                ));
          }
          if (index == 0 && _contactPermission == true) {
            return ListTile(
              title: Text('Local contacts: $_localcontactcount'),
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.contact_mail),
              ),
              trailing: const Icon(Icons.arrow_right),
            );
          }
          if (index == 1 && _imagePermission == false) {
            return InkWell(
                onTap: () {
                  askImagePermissions();
                },
                child: const ListTile(
                  title: Text(
                      'Can not access photo library,press me request the Permission.'),
                  leading: CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.image),
                  ),
                  trailing: Icon(Icons.arrow_right),
                ));
          }
          if (index == 1 && _imagePermission == true) {
            return ListTile(
              title: Text('Local images: $_localimagecount'),
              leading: const CircleAvatar(
                backgroundColor: Colors.greenAccent,
                child: Icon(Icons.image),
              ),
              trailing: const Icon(Icons.arrow_right),
            );
          }
          if (index == 2) {
            if (gcc.currentUser != null) {
              return InkWell(
                  onTap: () {
                    MessageBoxHelper.confirm(context, 'Alert',
                        'Are you sure logout?', 'Logout', 'Cancel', onOK: () {
                      gcc.signOut();
                      allcontact = [];
                      setState(() {});
                    });
                  },
                  child: ListTile(
                    title: Text(
                        '${gcc.currentUser?.email}  Contacts:${allcontact.length}'),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.mail_rounded),
                    ),
                    trailing: const Icon(Icons.arrow_right),
                  ));
            } else {
              return InkWell(
                  onTap: () {
                    gcc.signIn();
                  },
                  child: const ListTile(
                    title: Text('Not signin ,press me sign in the Gmail'),
                    leading: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.mail_rounded),
                    ),
                    trailing: Icon(Icons.arrow_right),
                  ));
            }
          }
          if (index == 3) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      ElevatedButton(
                          onPressed: (_contactPermission == true &&
                                  gcc.currentUser != null)
                              ? () {
                                  _downloadAddressBookFromGmail();
                                }
                              : null,
                          child: const Text('Gmail --> Local')),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(50, 0, 0, 0),
                          child: ElevatedButton(
                              onPressed: (_contactPermission == true &&
                                      gcc.currentUser != null)
                                  ? () {
                                      _uploadAddressBookToGmail();
                                    }
                                  : null,
                              child: const Text('Local --> Gmail'))),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                          style: ButtonStyle(
                              backgroundColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.red)),
                          onPressed: (_contactPermission == true &&
                                  gcc.currentUser != null)
                              ? () {
                                  _downloadAddressbookFromDrive();
                                }
                              : null,
                          child: const Text('GDrive --> Local')),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(50, 0, 0, 0),
                          child: ElevatedButton(
                              style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateColor.resolveWith(
                                          (states) => Colors.red)),
                              onPressed: (_contactPermission == true &&
                                      gcc.currentUser != null)
                                  ? () {
                                      _uploadAddressbookToGDrive();
                                    }
                                  : null,
                              child: const Text('Local --> GDrive'))),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                          onPressed: 
                              _imagePermission == true &&
                                      gcc.currentUser != null
                              ? () {
                                  _uploadAlbumToGdrive(context);
                                }
                              : null,
                          child: const Text('Image Backup --> Gdrive')),
                    ],
                  )
                ],
              ),
            );
          }
          return const SizedBox(
            width: 0,
            height: 0,
          );
        });
  }

  var _contactPermission = false;
  var _imagePermission = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('A0ktrust'),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }

  _uploadAddressBookToGmail() async {
    MessageBoxHelper.confirm(
        context,
        'Alert',
        'All contacts on the Gmail will be deleted！',
        'Upload',
        'Cancel', onOK: () async {
      EasyLoading.show(status: 'cleaning...');
      await gcc.cleanGmailContact();

      EasyLoading.show(status: 'reading...');
      var allContacts = await LocalContact.getContacts();
      // print(json.encode(contacts));

      EasyLoading.show(status: 'uploading...');
      await gcc.uploadContact(allContacts);

      await gcc.getAllContact();
      EasyLoading.dismiss();
      EasyLoading.showSuccess('All Done! ');
    });
  }

  _downloadAddressBookFromGmail() async {
    MessageBoxHelper.confirm(
        context,
        'Alert',
        'All contacts on the phone will be deleted！',
        'Download',
        'Cancel', onOK: () async {
      EasyLoading.show(status: 'downloading...');
      await gcc.getAllContact();
      EasyLoading.show(status: 'cleaning...');
      await LocalContact.cleanContacts();
      EasyLoading.show(status: 'writing...');
      int i = await LocalContact.writeContacts(allcontact);
      EasyLoading.dismiss();
      EasyLoading.showSuccess('Done! Totle:$i');
      getLocalContactCount();
    });
  }

  _downloadAddressbookFromDrive() async {
    EasyLoading.show(status: 'loading...');
    var x = await gcc.listGDriveFilesInFolder(gcc.gDriverContactFolder);
    if (x == null || x.isEmpty) {
      EasyLoading.dismiss();
      MessageBoxHelper.alert(
        context,
        'Alert',
        'No Backup can be restore！',
        'OK',
      );
      return;
    }
    // print(x);
    List<Widget> result = [
      ListTile(
        // leading: new Icon(Icons.photo),
        title: new Text("Select a backup to restore"),
        onTap: () {
          Navigator.pop(context);
        },
      )
    ];
    // x=x.reversed.toList();
    x.sort((a, b) => b?['modifiedTime'].compareTo(a?['modifiedTime']));
    // var z = json.decode(x)['files'].take(3).toList();
    for (var a in x.take(3)) {
      result.add(ListTile(
        // leading: new Icon(Icons.photo),
        title: new Text("${a['name']}"),
        onTap: () {
          Navigator.pop(context);
          _downloadGdriverByFile(a['id']);
        },
      ));
    }

    EasyLoading.dismiss();

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: result,
          );
        });
  }

  _downloadGdriverByFile(fileid) async {
    // EasyLoading.show(status: 'downloading...');

    // EasyLoading.dismiss();

    MessageBoxHelper.confirm(
        context,
        'Alert',
        'All contacts on the phone will be deleted！',
        'Confirm',
        'Cancel', onOK: () async {
      EasyLoading.show(status: 'loading...');
      var x = (await gcc.getGdriveFile(fileid));
      if (x == null) {
        EasyLoading.dismiss();
        MessageBoxHelper.alert(
          context,
          'Alert',
          'Download failed！',
          'OK',
        );
        return;
      }
      
      EasyLoading.show(status: 'cleaning');
      await LocalContact.cleanContacts();
      EasyLoading.show(status: 'writing');
      var i = await LocalContact.writeContactsFromFile(x);
      // EasyLoading.dismiss();
      EasyLoading.showSuccess('Done! Totle:$i');
      getLocalContactCount();
    });
    return;
  }

  getLocalContactCount() async {
    _localcontactcount = await LocalContact.getContactsCount();
    setState(() {});
  }

  _uploadAddressbookToGDrive() async {   
    EasyLoading.show(status: 'uploading...');
    
    var contentTextx = await ContactsService.getContacts();
    var contentText = contentTextx
        .map((a) => {
              "avatar": ImageHelper.imagelistToBase64(a.avatar ?? Uint8List(0),
                  quality: quality),
              'birthday': a.birthday,
              'company': a.company ?? "",
              'displayName': a.displayName ?? "",
              'emails': a.emails == null
                  ? []
                  : a.emails
                      ?.map((b) => {'label': b.label, 'value': b.value})
                      .toList(),
              // 'familyName': a.familyName,
              // 'givenName': a.givenName,
              'identifier': a.identifier,
              'jobTitle': a.jobTitle ?? "",
              'middleName': a.middleName ?? "",
              'phones': a.phones
                  ?.map((b) => {'label': b.label, 'value': b.value})
                  .toList(),
              'postalAddresses': a.postalAddresses == null
                  ? []
                  : a.postalAddresses
                      ?.map((b) => {
                            'label': b.label,
                            'city': b.city,
                            'country': b.country,
                            'postcode': b.postcode,
                            'region': b.region,
                            'street': b.street
                          })
                      .toList(),
              'prefix': a.prefix ?? "",
              'suffix': a.suffix ?? "",
            })
        .toList();
        
    var filename = '${DateTimeHelper.formatdatetime(DateTime.now())}.json';
    await FileHelper.writeTextFile(
        filename, '${json.encode(await contentText)}');
    // var y = await readTextFile('path.text');
    // print('local text= $y');
    await gcc.uploadSingleFiles(await FileHelper.getFile(filename));
    await FileHelper.delFile(filename);
    EasyLoading.dismiss();
    EasyLoading.showSuccess('done');
  }

  _uploadAlbumToGdrive(context) async {
    
    if (_imagePermission == false) {
      MessageBoxHelper.alert(
          context, 'Warning', 'Unable to access album, please authorize', 'OK',
          () {
        openAppSettings();
      });
      return;
    }

    MessageBoxHelper.confirm(
        context,
        'Info',
        'This operation may take a lot of time, be patient.',
        'Confirm',
        'Cancel', onOK: () async {
      EasyLoading.show(status: 'reading...');
      await gcc.uploadFiles(context, await AlbumManager().listCameraImages());
      EasyLoading.dismiss();
      // print('done');
      setState(() {});
    });
  }
}
