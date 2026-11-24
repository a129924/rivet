struct Delivery: Sendable {
  let payload: Payload
  let cancelled: Bool
}

actor ControlledAsyncSource {
  private var pending: [Request: CheckedContinuation<Payload, Never>] = [:]
  private var waiting: [Request: CheckedContinuation<Void, Never>] = [:]
  private(set) var requests: [Request] = []

  func load(_ request: Request) async -> Delivery {
    let payload = await withCheckedContinuation { continuation in
      precondition(pending[request] == nil)
      pending[request] = continuation
      requests.append(request)
      waiting.removeValue(forKey: request)?.resume()
    }
    return Delivery(payload: payload, cancelled: Task.isCancelled)
  }

  func waitForRequest(_ request: Request) async {
    if pending[request] != nil { return }
    await withCheckedContinuation { continuation in
      precondition(waiting[request] == nil)
      waiting[request] = continuation
    }
  }

  func release(_ request: Request, with payload: Payload) {
    guard let continuation = pending.removeValue(forKey: request) else {
      preconditionFailure("Release must follow the source-waiting barrier")
    }
    continuation.resume(returning: payload)
  }

  var isDrained: Bool {
    pending.isEmpty && waiting.isEmpty
  }
}
