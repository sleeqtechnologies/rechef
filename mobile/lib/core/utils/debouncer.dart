import 'dart:async';

class Debouncer {
  Debouncer({Duration? delay}) : _delay = delay ?? const Duration(milliseconds: 500);

  final Duration _delay;
  Timer? _timer;

  void call(void Function() callback) {
    _timer?.cancel();
    _timer = Timer(_delay, callback);
  }

  void dispose() {
    _timer?.cancel();
  }
}
