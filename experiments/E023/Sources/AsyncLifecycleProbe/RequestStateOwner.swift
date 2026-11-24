struct Request: Codable, Hashable, Sendable {
  let generation: Int
  let name: String
  let key: String
}

enum Payload: Codable, Equatable, Sendable {
  case success(String)
  case unavailable
}

enum DisplayState: Codable, Equatable {
  case idle
  case loading(Request)
  case success(String)
  case unavailable
  case invalidated
}

struct Ticket {
  let request: Request
  let task: Task<Void, Never>
}

struct Snapshot: Codable, Equatable {
  let state: DisplayState
  let current: Request?
}

enum Decision: String, Codable {
  case accepted
  case expired
  case invalidated
  case cancelled
}

struct Event: Codable {
  let sequence: Int
  let kind: String
  let request: Request?
  let payload: Payload?
  let sourceCancelled: Bool?
  let taskCancelled: Bool?
  let decision: Decision?
  let before: Snapshot?
  let after: Snapshot
}

@MainActor
final class RequestStateOwner {
  private let source: ControlledAsyncSource
  private var generation = 0
  private var current: Ticket?
  private var state = DisplayState.idle
  private(set) var events: [Event] = []

  init(source: ControlledAsyncSource) {
    self.source = source
  }

  var snapshot: Snapshot {
    Snapshot(state: state, current: current?.request)
  }

  func owns(_ ticket: Ticket) -> Bool {
    current?.request == ticket.request && current?.task == ticket.task
  }

  // Suppressing replacement cancellation is reserved for the identity-only experiment.
  func start(_ name: String, key: String, cancelSuperseded: Bool = true) -> Ticket? {
    guard state != .invalidated else {
      record("startRejected")
      return nil
    }

    let previous = current
    generation += 1
    let request = Request(generation: generation, name: name, key: key)
    let task = Task { [weak self, source] in
      let delivery = await source.load(request)
      self?.finish(request, delivery: delivery)
    }
    let ticket = Ticket(request: request, task: task)
    current = ticket
    state = .loading(request)
    record("started", request: request)

    if let previous, cancelSuperseded {
      cancel(previous)
    }
    return ticket
  }

  func cancelCurrent() {
    guard let current else { return }
    self.current = nil
    state = .idle
    record("currentRevoked", request: current.request)
    cancel(current)
  }

  func invalidate() {
    guard state != .invalidated else { return }
    let previous = current
    current = nil
    state = .invalidated
    record("ownerInvalidated", request: previous?.request)
    if let previous {
      cancel(previous)
    }
  }

  // The driver invokes this while the source is held at its barrier.
  func cancelHandleForControl(_ ticket: Ticket) {
    precondition(owns(ticket))
    cancel(ticket)
  }

  private func cancel(_ ticket: Ticket) {
    ticket.task.cancel()
    record("cancellationRequested", request: ticket.request, taskCancelled: ticket.task.isCancelled)
  }

  private func finish(_ request: Request, delivery: Delivery) {
    let before = snapshot
    let cancelled = Task.isCancelled
    let decision: Decision
    if state == .invalidated {
      decision = .invalidated
    } else if current?.request.generation != request.generation {
      decision = .expired
    } else if cancelled {
      decision = .cancelled
      current = nil
      state = .idle
    } else {
      decision = .accepted
      current = nil
      switch delivery.payload {
      case .success(let value): state = .success(value)
      case .unavailable: state = .unavailable
      }
    }
    record(
      "finished", request: request, payload: delivery.payload, sourceCancelled: delivery.cancelled,
      taskCancelled: cancelled, decision: decision, before: before)
  }

  func record(
    _ kind: String, request: Request? = nil, payload: Payload? = nil,
    sourceCancelled: Bool? = nil, taskCancelled: Bool? = nil, decision: Decision? = nil,
    before: Snapshot? = nil
  ) {
    events.append(
      Event(
        sequence: events.count + 1, kind: kind, request: request, payload: payload,
        sourceCancelled: sourceCancelled, taskCancelled: taskCancelled, decision: decision,
        before: before, after: snapshot))
  }
}
