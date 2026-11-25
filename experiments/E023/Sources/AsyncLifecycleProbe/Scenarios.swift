import Dispatch
import Foundation

package enum Scenario: String, CaseIterable, Sendable {
  case v01, v02, v03, v04, v05
  case v06abc, v06acb, v06bac, v06bca, v06cab, v06cba
  case v07
  case v08replacement, v08identity, v08cancelled, v08revoked
  case v10

  fileprivate var refreshOrder: [String] {
    rawValue.dropFirst(3).map { String($0).uppercased() }
  }
}

package struct Report: Encodable {
  let scenario: Scenario.RawValue
  let events: [Event]
  let final: Snapshot
  let checks: [String]
  package let failures: [String]
}

@MainActor
package func run(_ scenario: Scenario) async -> Report {
  let watchdog = DispatchSource.makeTimerSource(queue: .global())
  watchdog.schedule(deadline: .now() + .seconds(10))
  watchdog.setEventHandler {
    FileHandle.standardError.write(Data("Watchdog: \(scenario.rawValue) did not finish\n".utf8))
    exit(124)
  }
  watchdog.resume()
  defer { watchdog.cancel() }

  let driver = Driver()
  await driver.execute(scenario)
  return await driver.report(scenario)
}

@MainActor
private final class Driver {
  private let source: ControlledAsyncSource
  private let owner: RequestStateOwner
  private var started: [Request] = []
  private var checks: [String] = []
  private var failures: [String] = []

  init() {
    let source = ControlledAsyncSource()
    self.source = source
    self.owner = RequestStateOwner(source: source)
  }

  private func check(_ condition: Bool, _ description: String) {
    checks.append(description)
    if !condition { failures.append(description) }
  }

  private func start(
    _ name: String, key: String? = nil, cancelSuperseded: Bool = true
  ) async -> Ticket {
    guard let ticket = owner.start(name, key: key ?? name, cancelSuperseded: cancelSuperseded)
    else {
      preconditionFailure("Expected the scenario owner to accept \(name)")
    }
    started.append(ticket.request)
    await source.waitForRequest(ticket.request)
    owner.record("sourceWaiting", request: ticket.request)
    check(owner.owns(ticket), "\(name) owns its Task handle")
    check(owner.snapshot.state == .loading(ticket.request), "\(name) is loading")
    return ticket
  }

  private func finish(
    _ ticket: Ticket, payload: Payload, decision: Decision, cancelled: Bool = false
  ) async {
    let name = ticket.request.name
    owner.record("sourceReleased", request: ticket.request, payload: payload)
    await source.release(ticket.request, with: payload)
    await ticket.task.value
    let event = owner.events.last
    check(
      event?.kind == "finished" && event?.request == ticket.request, "\(name) finished exactly here"
    )
    check(event?.decision == decision, "\(name) decision is \(decision.rawValue)")
    check(event?.payload == payload, "\(name) source delivered the requested payload")
    check(
      event?.sourceCancelled == cancelled && event?.taskCancelled == cancelled,
      "\(name) source and completion cancellation flags are \(cancelled)")
    if decision == .expired || decision == .invalidated {
      check(event?.before == event?.after, "\(name) made no state or slot write")
    }
  }

  private func expect(_ state: DisplayState) {
    check(
      owner.snapshot == Snapshot(state: state, current: nil),
      "Terminal state is \(state), slot cleared")
  }

  func execute(_ scenario: Scenario) async {
    switch scenario {
    case .v01:
      let ticketA = await start("A")
      await finish(ticketA, payload: .success("A"), decision: .accepted)
      expect(.success("A"))
    case .v02, .v03, .v04, .v08replacement, .v08identity, .v10:
      await replacement(scenario)
    case .v05:
      let ticketA = await start("A")
      owner.invalidate()
      check(ticketA.task.isCancelled, "Invalidation cancelled A")
      expect(.invalidated)
      owner.invalidate()
      check(owner.start("B", key: "B") == nil, "Invalidated owner rejects a new start")
      await finish(ticketA, payload: .success("A"), decision: .invalidated, cancelled: true)
      expect(.invalidated)
    case .v06abc, .v06acb, .v06bac, .v06bca, .v06cab, .v06cba:
      await repeatedRefresh(order: scenario.refreshOrder)
    case .v07:
      let ticketA = await start("A")
      await finish(ticketA, payload: .unavailable, decision: .accepted)
      expect(.unavailable)
    case .v08cancelled:
      let ticketA = await start("A")
      owner.cancelHandleForControl(ticketA)
      check(owner.owns(ticketA), "Cancelled A remains current for the control")
      await finish(ticketA, payload: .success("A"), decision: .cancelled, cancelled: true)
      expect(.idle)
    case .v08revoked:
      let ticketA = await start("A")
      owner.cancelCurrent()
      check(ticketA.task.isCancelled, "Explicit revocation cancelled A")
      expect(.idle)
      await finish(ticketA, payload: .success("A"), decision: .expired, cancelled: true)
      expect(.idle)
      let ticketB = await start("B")
      await finish(ticketB, payload: .success("B"), decision: .accepted)
      expect(.success("B"))
    }
  }

  private func replacement(_ scenario: Scenario) async {
    let identityControl = scenario == .v08identity
    let ticketA = await start("A", key: identityControl ? "same-pr" : "A")
    let ticketB = await start(
      "B", key: identityControl ? "same-pr" : "B", cancelSuperseded: !identityControl)
    check(
      ticketA.request.generation != ticketB.request.generation,
      "Replacement gives B a new generation")
    check(
      ticketA.task.isCancelled == !identityControl,
      "A has the expected replacement cancellation flag")
    if identityControl {
      check(ticketA.request.key == ticketB.request.key, "Identity control refreshes the same PR")
    }
    let aPayload: Payload = scenario == .v04 ? .unavailable : .success("A")
    let releaseAWhileLoading = scenario == .v10 || scenario == .v08replacement || identityControl
    if releaseAWhileLoading {
      await finish(ticketA, payload: aPayload, decision: .expired, cancelled: !identityControl)
      check(owner.owns(ticketB), "Late A leaves the actual B handle in the slot")
      check(owner.snapshot.state == .loading(ticketB.request), "Late A leaves B loading")
      await finish(ticketB, payload: .success("B"), decision: .accepted)
    } else {
      await finish(ticketB, payload: .success("B"), decision: .accepted)
      expect(.success("B"))
      await finish(ticketA, payload: aPayload, decision: .expired, cancelled: true)
    }
    expect(.success("B"))
  }

  private func repeatedRefresh(order: [String]) async {
    let ticketA = await start("A", key: "same-pr")
    let ticketB = await start("B", key: "same-pr")
    let ticketC = await start("C", key: "same-pr")
    let tickets = ["A": ticketA, "B": ticketB, "C": ticketC]
    var cFinished = false
    for name in order {
      guard let ticket = tickets[name] else { preconditionFailure("Unexpected refresh input") }
      let isCurrent = name == "C"
      await finish(
        ticket, payload: .success(name), decision: isCurrent ? .accepted : .expired,
        cancelled: !isCurrent)
      cFinished = cFinished || isCurrent
      if cFinished {
        expect(.success("C"))
      } else {
        check(owner.owns(ticketC), "C retains its actual Task handle")
        check(owner.snapshot.state == .loading(ticketC.request), "C remains loading")
      }
    }
  }

  func report(_ scenario: Scenario) async -> Report {
    check(await source.requests == started, "Source started exactly the accepted requests")
    check(await source.isDrained, "Source has no outstanding continuations")
    check(
      owner.events.filter { $0.kind == "finished" }.count == started.count,
      "Every launched Task settled once")
    return Report(
      scenario: scenario.rawValue, events: owner.events, final: owner.snapshot, checks: checks,
      failures: failures)
  }
}
