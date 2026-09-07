import Foundation

public struct URLSessionTransport: Transport {
  private let session: URLSession

  public init(session: URLSession = .shared) {
    self.session = session
  }

  public func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
    do {
      let (body, response) = try await session.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw HTTPClientError.nonHTTPResponse
      }

      let headers = HTTPHeaders(
        httpResponse.allHeaderFields.reduce(into: [String: String]()) { headers, field in
          guard let name = field.key as? String else {
            return
          }
          headers[name] = String(describing: field.value)
        }
      )

      return HTTPResponse(statusCode: httpResponse.statusCode, headers: headers, body: body)
    } catch let error as HTTPClientError {
      throw error
    } catch let error as URLError {
      throw .urlLoading(error)
    } catch {
      throw .unexpected(error)
    }
  }
}
