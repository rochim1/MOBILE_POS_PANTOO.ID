/// Page history inside the POS shell, independent from pushed detail/dialog
/// routes. Keeping back separate from visit prevents back/forward loops.
class PosNavigationHistory {
  PosNavigationHistory({int initial = 1}) : _current = initial;

  int _current;
  final List<int> _previous = [];
  int get current => _current;
  bool get canGoBack => _previous.isNotEmpty;

  void visit(int destination) {
    if (destination == _current) return;
    _previous.add(_current);
    if (_previous.length > 100) _previous.removeAt(0);
    _current = destination;
  }

  void reset(int destination) {
    _previous.clear();
    _current = destination;
  }

  int back({required int fallback, bool Function(int)? isAllowed}) {
    while (_previous.isNotEmpty) {
      final destination = _previous.removeLast();
      if (destination == _current || isAllowed?.call(destination) == false) {
        continue;
      }
      return _current = destination;
    }
    // No previous page: stay in the app, never pop into a pre-login route.
    return _current = fallback;
  }
}
