import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:stack_trace/stack_trace.dart';

import 'common.dart';

enum ALogMode {
  debug, // ð DEBUG
  warning, // ð WARNING
  info, // ð INFO
  error, // â¤ï¸ ERROR
}

Future debug(dynamic msg, {ALogMode mode = ALogMode.debug}) async {
  var chain = Chain.current();
  // Chain.forTrace(StackTrace.current);
  // å° core å flutter åçå æ åèµ·æ¥ï¼å³ç¸å³æ°æ®åªå©å¶ä¸­ä¸æ¡ï¼
  chain =
      chain.foldFrames((frame) => frame.isCore || frame.package == "flutter");
  // ååºææä¿¡æ¯å¸§
  final frames = chain.toTrace().frames;
  // æ¾å°å½åå½æ°çä¿¡æ¯å¸§
  final idx = frames.indexWhere((element) => element.member == "debug");
  if (idx == -1 || idx + 1 >= frames.length) {
    return "";
  }
  // è°ç¨å½åå½æ°çå½æ°ä¿¡æ¯å¸§
  final frame = frames[idx + 1];

  var modeStr = "";
  switch (mode) {
    case ALogMode.debug:
      modeStr = "ð DEBUG";
      break;
    case ALogMode.warning:
      modeStr = "ð WARNING";
      break;
    case ALogMode.info:
      modeStr = "ð INFO";
      break;
    case ALogMode.error:
      modeStr = "â¤ï¸ ERROR";
      break;
  }

  final printStr =
      "${DateTimeHelper.formatdatetime(DateTime.now())}\n $modeStr ${frame.uri.toString().split("/").last}(${frame.line}) - $msg \n";

  if (kReleaseMode) {
    // releaseæ¨¡å¼è¾åºå°æä»¶ï¼ä¸ºä¸æ¥æä¸åºç¡
    File(logfilename).writeAsStringSync(printStr, mode: FileMode.append);
  } else {
    debugPrint(printStr);
  }
}
