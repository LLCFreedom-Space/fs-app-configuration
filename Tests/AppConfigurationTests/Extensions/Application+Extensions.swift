import Configuration
import Testing
import VaporTesting

@testable import AppConfiguration

extension Application {
    func mockClientRequest(
        status: HTTPResponseStatus = .ok,
        body: String? = nil,
        error: Error? = nil
    ) {
        clients.use { app in
            MockClient(eventLoop: app.eventLoopGroup.any()) { _ in
                if let error {
                    throw error
                }
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
}
