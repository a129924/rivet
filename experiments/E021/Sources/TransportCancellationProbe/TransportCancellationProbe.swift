import Foundation
import RivetHTTPClient

@main
struct TransportCancellationProbe {
  static func main() async throws {
    let arguments = CommandLine.arguments
    guard arguments.count == 2, let port = UInt16(arguments[1]), port > 0,
      let address = URL(string: "http://127.0.0.1:\(port)/probe")
    else { throw ProbeError.invalidPort }
    let url = try HTTPURL(address)
    let configuration = URLSessionConfiguration.ephemeral
    configuration.connectionProxyDictionary = [:]
    configuration.timeoutIntervalForRequest = 60
    configuration.timeoutIntervalForResource = 60
    let session = URLSession(configuration: configuration)
    defer { session.invalidateAndCancel() }
    let client = HTTPClient(transport: URLSessionTransport(session: session))
    let request = Task.detached { () -> Observation in
      do {
        let response = try await client.get(url: url)
        return Observation(
          kind: "response", status: response.statusCode,
          expectedBody: response.body == Data("ok".utf8))
      } catch HTTPClientError.cancelled(let underlying) {
        let detail = underlying as NSError
        return Observation(
          kind: "cancelled", underlyingType: String(reflecting: type(of: underlying)),
          underlyingDomain: detail.domain, underlyingCode: detail.code)
      } catch {
        return Observation(kind: "otherError", underlyingType: String(reflecting: type(of: error)))
      }
    }

    // The server sends a command only after reading the complete request.
    switch readLine() {
    case "cancel": request.cancel()
    case "release": break
    default: throw ProbeError.invalidCommand
    }
    var observation = await request.value
    observation.taskCancellationRequested = request.isCancelled
    let output = try JSONEncoder().encode(observation)
    try FileHandle.standardOutput.write(contentsOf: output + Data([10]))
    // Keep the session alive until the server has captured its peer observation.
    guard readLine() == "finish" else { throw ProbeError.invalidCommand }
  }
}

private enum ProbeError: Error {
  case invalidPort
  case invalidCommand
}

private struct Observation: Encodable {
  let kind: String
  var status: Int?
  var expectedBody: Bool?
  var underlyingType: String?
  var underlyingDomain: String?
  var underlyingCode: Int?
  var taskCancellationRequested = false
}
