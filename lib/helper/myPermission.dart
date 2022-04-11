import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:photo_manager/photo_manager.dart';

class MyPermission {
  final StreamController _hasContactPermissionController =
      StreamController.broadcast();
  Stream get hasContactPermission => _hasContactPermissionController.stream;
  final StreamController _hasImagePermissionController =
      StreamController.broadcast();
  Stream get hasImagePermission => _hasImagePermissionController.stream;

  // var hasPermission = false;
  Future<void> askContactPermissions(context) async {
    PermissionStatus? permissionStatus;
    while (permissionStatus != PermissionStatus.granted) {
      try {
        permissionStatus = await _getContactPermission();
        // print(permissionStatus);
        if (permissionStatus != PermissionStatus.granted) {
          _hasContactPermissionController.add(false);
          _handleInvalidPermissions(permissionStatus);
        } else {
          _hasContactPermissionController.add(true);
        }
      } catch (e) {
        if (await showPlatformDialog(
                context: context,
                builder: (context) {
                  return PlatformAlertDialog(
                    title: const Text('Contact Permissions'),
                    content: const Text(
                        'We are having problems retrieving permissions.  Would you like to '
                        'open the app settings to fix?'),
                    actions: [
                      PlatformDialogAction(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text('Close'),
                      ),
                      PlatformDialogAction(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text('Settings'),
                      ),
                    ],
                  );
                }) ==
            true) {
          await openAppSettings();
        }
      }
    }
  }

  Future<PermissionStatus> _getContactPermission() async {
    final status = await Permission.contacts.status;
    if (!status.isGranted) {
      final result = await Permission.contacts.request();
      return result;
    } else {
      return status;
    }
  }

  Future<void> askImagePermissions(context, {callback}) async {
    const _permissions = Permission.storage;
    final statuses = (await _permissions.request());
    if (statuses.isGranted) {
      if (callback != null) {
        callback();
      }
    } else {
      showPlatformDialog(
          context: context,
          builder: (context) {
            return PlatformAlertDialog(
              title: const Text('Image Permissions'),
              content: const Text(
                  'We are having problems retrieving permissions.  Would you like to '
                  'open the app settings to fix?'),
              actions: [
                PlatformDialogAction(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Close'),
                ),
                PlatformDialogAction(
                  onPressed: () {
                    Navigator.pop(context, true);
                    // PhotoManager.openSetting();
                    openAppSettings();
                  },
                  child: const Text('Settings'),
                ),
              ],
            );
          });
    }
  }

  Future<PermissionStatus> _getImagePermission() async {
    if (Platform.isIOS) {
      var photosStatus = await Permission.photos.status;
      if (photosStatus.isDenied) {
        var ps = await Permission.photos.request();
        return ps;
      }
      return photosStatus;
    } else {
      var ss = await Permission.storage.status;
      if (!ss.isGranted) {
        var storageStatus = await Permission.storage.request();
        return storageStatus;
      }
      return ss;
    }
  }

  void _handleInvalidPermissions(PermissionStatus permissionStatus) {
    // print(permissionStatus);
    if (permissionStatus == PermissionStatus.denied) {
      throw PlatformException(
          code: 'PERMISSION_DENIED',
          message: 'Access to location data denied',
          details: null);
    } else if (permissionStatus == PermissionStatus.restricted) {
      throw PlatformException(
          code: 'PERMISSION_DISABLED',
          message: 'Location data is not available on device',
          details: null);
    }
  }
}
