import Foundation
import IRCKit

public final class IRCClient {
    public enum SASLMechanism {
        case plain(username: String, password: String)
        case external
    }

    private var connection: IRCConnection
    private let parser = IRCParser()
    private let nick: String
    private let username: String
    private let sasl: SASLMechanism?

    public init(connection: IRCConnection, nick: String, username: String, sasl: SASLMechanism? = nil) {
        self.connection = connection
        self.nick = nick
        self.username = username
        self.sasl = sasl
    }

    public func start() {
        connection.lineHandler = { [weak self] line in
            self?.handle(line: line)
        }
        connection.connect()
        connection.send(line: "CAP LS 302")
    }

    private func handle(line: String) {
        let message = parser.parse(line)
        switch message.command {
        case .cap:
            handleCap(message)
        case .authenticate:
            handleAuthenticate(message)
        case .numeric(let code):
            if code == 903 { // RPL_SASLSUCCESS
                connection.send(line: "CAP END")
                connection.send(line: "NICK \(nick)")
                connection.send(line: "USER \(username) 0 * :\(username)")
            }
        default:
            break
        }
    }

    private func handleCap(_ message: IRCMessage) {
        guard message.parameters.count >= 2 else { return }
        let sub = message.parameters[1].uppercased()
        switch sub {
        case "LS":
            guard sasl != nil else {
                connection.send(line: "CAP END")
                connection.send(line: "NICK \(nick)")
                connection.send(line: "USER \(username) 0 * :\(username)")
                return
            }
            if message.parameters.count >= 3 {
                let caps = message.parameters[2].split(separator: " ")
                if caps.contains("sasl") {
                    connection.send(line: "CAP REQ :sasl")
                }
            }
        case "ACK":
            guard sasl != nil else { return }
            switch sasl! {
            case .plain:
                connection.send(line: "AUTHENTICATE PLAIN")
            case .external:
                connection.send(line: "AUTHENTICATE EXTERNAL")
            }
        default:
            break
        }
    }

    private func handleAuthenticate(_ message: IRCMessage) {
        guard message.parameters.first == "+" else { return }
        guard let sasl = sasl else { return }
        switch sasl {
        case .plain(let user, let password):
            let auth = "\u{0000}\(user)\u{0000}\(password)"
            if let data = auth.data(using: .utf8) {
                let base64 = data.base64EncodedString()
                connection.send(line: "AUTHENTICATE \(base64)")
            }
        case .external:
            connection.send(line: "AUTHENTICATE =")
        }
    }
}
