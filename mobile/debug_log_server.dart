import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final logFile = File('/tmp/rechef_debug.log');
  final sink = logFile.openWrite(mode: FileMode.append);

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 9753);
  final msg = 'Debug log server listening on http://0.0.0.0:9753 (logging to /tmp/rechef_debug.log)';
  print(msg);
  sink.writeln(msg);

  await for (final request in server) {
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    if (request.method == 'POST') {
      final body = await utf8.decoder.bind(request).join();
      final timestamp = DateTime.now().toIso8601String();
      final line = '[$timestamp] $body';
      print(line);
      sink.writeln(line);
      await sink.flush();
      request.response
        ..statusCode = 200
        ..write('ok');
    } else {
      request.response
        ..statusCode = 200
        ..write('debug log server running');
    }
    await request.response.close();
  }
}
