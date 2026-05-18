import 'dart:async';

/// Broadcast stream that notifies all finance cubits when any finance data changes.
/// After a successful mutation, call [FinanceEventBus.notify].
/// Cubits subscribe in their constructor and unsubscribe in [close].
class FinanceEventBus {
  FinanceEventBus._();

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  static Stream<void> get onDataChanged => _controller.stream;

  static void notify() => _controller.add(null);
}
