import Foundation

public protocol IRCConnection {
    /// Called for each complete line received from the network.
    var lineHandler: ((String) -> Void)? { get set }
    /// Establish the network connection.
    func connect()
    /// Send a single line terminated with CRLF.
    func send(line: String)
    /// Cancel the network connection.
    func cancel()
}

#if canImport(Network)
import Network

public final class NWIRCConnection: IRCConnection {
    public var lineHandler: ((String) -> Void)?
    private let connection: NWConnection
    private let queue = DispatchQueue(label: "NWIRCConnection")
    private var buffer = Data()
    private let crlf = "\r\n".data(using: .utf8)!

    public init(host: String, port: UInt16) {
        let tlsOptions = NWProtocolTLS.Options()
        let parameters = NWParameters(tls: tlsOptions)
        let nwPort = NWEndpoint.Port(rawValue: port) ?? .irc
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: parameters)
    }

    public func connect() {
        connection.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case .ready:
                self?.receive()
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    public func send(line: String) {
        let data = Data((line + "\r\n").utf8)
        connection.send(content: data, completion: .contentProcessed { _ in })
    }

    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if let data = data, !data.isEmpty {
                self.buffer.append(data)
                while let range = self.buffer.range(of: self.crlf) {
                    let lineData = self.buffer.subdata(in: self.buffer.startIndex..<range.lowerBound)
                    self.buffer.removeSubrange(self.buffer.startIndex..<range.upperBound)
                    if let line = String(data: lineData, encoding: .utf8) {
                        self.lineHandler?(line)
                    }
                }
            }
            if error == nil && !isComplete {
                self.receive()
            }
        }
    }

    public func cancel() {
        connection.cancel()
    }
}
#else
/// Placeholder implementation for platforms without Network framework support.
public final class NWIRCConnection: IRCConnection {
    public var lineHandler: ((String) -> Void)?
    public init(host: String, port: UInt16) {}
    public func connect() {}
    public func send(line: String) {}
    public func cancel() {}
}
#endif
#if canImport(Network)
private extension NWEndpoint.Port {
    /// Fallback port used when provided value is invalid.
    static let irc: NWEndpoint.Port = 6667
}
#endif
