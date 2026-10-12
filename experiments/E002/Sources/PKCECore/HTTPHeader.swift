import Foundation

struct HTTPHeader {
  static let maximumBytes = 8 * 1024
  private(set) var data = Data()

  enum Result: Equatable {
    case incomplete
    case rejected
    case request(method: String, target: String)
  }

  mutating func append(_ chunk: Data) -> Result {
    data.append(chunk)
    let separator = Data("\r\n\r\n".utf8)
    if let range = data.range(of: separator) {
      guard range.upperBound <= Self.maximumBytes,
        let text = String(data: data[..<range.lowerBound], encoding: .utf8),
        let line = text.components(separatedBy: "\r\n").first
      else { return .rejected }
      let parts = line.split(separator: " ", omittingEmptySubsequences: false)
      guard parts.count == 3, !parts[0].isEmpty, !parts[1].isEmpty,
        parts[2] == "HTTP/1.1" || parts[2] == "HTTP/1.0"
      else { return .rejected }
      return .request(method: String(parts[0]), target: String(parts[1]))
    }
    return data.count >= Self.maximumBytes ? .rejected : .incomplete
  }

  static func response(status: Int, message: String) -> Data {
    let reason =
      switch status {
      case 200: "OK"
      case 404: "Not Found"
      case 405: "Method Not Allowed"
      default: "Bad Request"
      }
    let body = Data(message.utf8)
    let headers =
      "HTTP/1.1 \(status) \(reason)\r\n"
      + "Content-Type: text/plain; charset=utf-8\r\n"
      + "Content-Length: \(body.count)\r\n"
      + "Cache-Control: no-store\r\nConnection: close\r\n\r\n"
    return Data(headers.utf8) + body
  }
}
