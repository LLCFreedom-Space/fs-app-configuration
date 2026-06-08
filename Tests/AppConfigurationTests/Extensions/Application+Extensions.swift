@testable import AppConfiguration
import VaporTesting
import Testing
import Configuration

extension Application {
    func mockHTTP(status: HTTPResponseStatus = .ok, body: String? = nil) {
        clients.use { app in
            MockHTTPClient(eventLoop: app.eventLoopGroup.any()) { _ in
                var response = ClientResponse()
                response.status = status
                if let body {
                    var buffer = ByteBufferAllocator().buffer(capacity: body.utf8.count)
                    buffer.writeString(body)
                    response.body = buffer
                }
                return response
            }
        }
    }

    func mockHTTP(throwing error: Error) {
        clients.use { app in
            MockHTTPClient(eventLoop: app.eventLoopGroup.any()) { _ in throw error }
        }
    }
}
