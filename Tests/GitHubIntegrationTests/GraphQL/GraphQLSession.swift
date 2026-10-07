import Apollo
import Foundation

struct GraphQLChunks: AsyncChunkSequence {
  let chunks: [Data]
  func makeAsyncIterator() -> Iterator { Iterator(chunks: chunks) }
  struct Iterator: AsyncIteratorProtocol {
    var chunks: [Data]
    mutating func next() async -> Data? { chunks.isEmpty ? nil : chunks.removeFirst() }
  }
}

actor GraphQLSession: ApolloURLSession {
  struct Reply: Sendable {
    let status: Int
    let body: String
    init(_ status: Int = 200, _ body: String = #"{"data":{"probe":"ok"}}"#) {
      self.status = status
      self.body = body
    }
  }
  private var replies: [Reply]
  let error: (any Error & Sendable)?
  let initialGate: GraphQLGate?
  let nonHTTPResponse: Bool
  private var countWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
  private(set) var requests: [URLRequest] = []

  init(
    replies: [Reply] = [Reply()], error: (any Error & Sendable)? = nil,
    initialGate: GraphQLGate? = nil, nonHTTPResponse: Bool = false
  ) {
    self.replies = replies
    self.error = error
    self.initialGate = initialGate
    self.nonHTTPResponse = nonHTTPResponse
  }

  func waitForRequests(_ count: Int) async {
    if requests.count < count {
      await withCheckedContinuation { countWaiters.append((count, $0)) }
    }
  }

  func chunks(for request: URLRequest) async throws -> (any AsyncChunkSequence, URLResponse) {
    requests.append(request)
    let ready = countWaiters.filter { requests.count >= $0.0 }
    countWaiters.removeAll { requests.count >= $0.0 }
    for waiter in ready { waiter.1.resume() }
    if let error { throw error }
    let reply = replies.isEmpty ? Reply() : replies.removeFirst()
    if let initialGate {
      if request.value(forHTTPHeaderField: "Authorization") == "Bearer initial" {
        await initialGate.enter()
      }
    }
    let chunks = reply.body.isEmpty ? [] : [Data(reply.body.utf8)]
    if nonHTTPResponse {
      let response = URLResponse(
        url: request.url!, mimeType: "application/json",
        expectedContentLength: reply.body.utf8.count,
        textEncodingName: "utf-8")
      return (GraphQLChunks(chunks: chunks), response)
    }
    let response = HTTPURLResponse(
      url: request.url!, statusCode: reply.status, httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": "application/json"]
    )!
    return (GraphQLChunks(chunks: chunks), response)
  }
}

actor GraphQLCacheProbe: NormalizedCache {
  private(set) var reads = 0
  private(set) var writes = 0
  func loadRecords(forKeys keys: Set<CacheKey>) async throws -> [CacheKey: Record] {
    reads += 1
    return [:]
  }
  func merge(records: RecordSet) async throws -> Set<CacheKey> {
    writes += 1
    return []
  }
  func removeRecord(for key: CacheKey) async throws {}
  func removeRecords(matching pattern: CacheKey) async throws {}
  func clear() async throws {}
}
