public struct IRCMessage: Equatable {
    public let tags: [String: String]
    public let prefix: IRCPrefix?
    public let command: IRCCommand
    public let parameters: [String]

    public init(tags: [String: String] = [:], prefix: IRCPrefix? = nil, command: IRCCommand, parameters: [String] = []) {
        self.tags = tags
        self.prefix = prefix
        self.command = command
        self.parameters = parameters
    }
}

public enum IRCPrefix: Equatable {
    case server(String)
    case user(nick: String, user: String?, host: String?)
}

public enum IRCCommand: Equatable {
    case privmsg
    case join
    case part
    case ping
    case pong
    case numeric(Int)
    case other(String)
}
