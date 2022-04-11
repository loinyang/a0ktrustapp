import 'dart:io';
import 'package:local_image_pager/local_image_pager.dart';


class AlbumManager {

  Future<List<File>> listCameraImages() async {
    final pager = LocalImagePager();
    var total = await LocalImagePager.totalNumber;
    if (total == null) return [];
    
    var v = await pager.latestImages(1, total);
    if (v == null) return [];
    
    return v.map((e) => File(e)).toList();
  }
}
