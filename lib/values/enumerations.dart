enum NetworkState {
  idle,
  loading,
  success,
  error;

  bool get isIdle => this == NetworkState.idle;

  bool get isLoading => this == NetworkState.loading;

  bool get isSuccessful => this == NetworkState.success;

  bool get isFailed => this == NetworkState.error;
}

/// All the command codes that can be sent and received between [Detector] and
/// [_DetectorServer].
enum TensorflowProcessType {
  init,
  busy,
  ready,
  detect,
  result;
}
