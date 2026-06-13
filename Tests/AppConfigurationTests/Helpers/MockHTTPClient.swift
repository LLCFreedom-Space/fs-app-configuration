@testable import AppConfiguration
import VaporTesting
import Testing
import Configuration

final class MockHTTPClient: Client, @unchecked Sendable {
    let eventLoop: any EventLoop
    let responder: @Sendable (ClientRequest) throws -> ClientResponse

    init(
        eventLoop: any EventLoop,
        responder: @escaping @Sendable (ClientRequest) throws -> ClientResponse
    ) {
        self.eventLoop = eventLoop
        self.responder = responder
    }
    func delegating(to eventLoop: any EventLoop) -> any Client { self }
    
    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        do {
            return eventLoop.makeSucceededFuture(try responder(request))
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}
