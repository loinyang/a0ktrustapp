import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:stack_trace/stack_trace.dart';

import 'common.dart';

enum ALogMode {
  debug, // 💚 DEBUG
  warning, // 💛 WARNING
  info, // 💙 INFO
  error, // ❤️ ERROR
}

Future debug(dynamic msg, {ALogMode mode = ALogMode.debug}) async {
  var chain = Chain.current();
  // Chain.forTrace(StackTrace.current);
  // 将 core 和 flutter 包的堆栈合起来（即相关数据只剩其中一条）
  chain =
      chain.foldFrames((frame) => frame.isCore || frame.package == "flutter");
  // 取出所有信息帧
  final frames = chain.toTrace().frames;
  // 找到当前函数的信息帧
  final idx = frames.indexWhere((element) => element.member == "debug");
  if (idx == -1 || idx + 1 >= frames.length) {
    return "";
  }
  // 调用当前函数的函数信息帧
  final frame = frames[idx + 1];

  var modeStr = "";
  switch (mode) {
    case ALogMode.debug:
      modeStr = "💚 DEBUG";
      break;
    case ALogMode.warning:
      modeStr = "💛 WARNING";
      break;
    case ALogMode.info:
      modeStr = "💙 INFO";
      break;
    case ALogMode.error:
      modeStr = "❤️ ERROR";
      break;
  }

  final printStr =
      "${DateTimeHelper.formatdatetime(DateTime.now())}\n $modeStr ${frame.uri.toString().split("/").last}(${frame.line}) - $msg \n";

  if (kReleaseMode) {
    // release模式输出到文件，为上报打下基础
    File(logfilename).writeAsStringSync(printStr, mode: FileMode.append);
  } else {
    debugPrint(printStr);
  }
}
