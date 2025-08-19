public struct IRCParser {
    public init() {}

    public func parse(_ line: String) -> IRCMessage {
        var rest = line[...]
        var tags: [String: String] = [:]

        // Tags
        if rest.first == "@" {
            if let spaceIndex = rest.firstIndex(of: " ") {
                let tagPart = rest[rest.index(after: rest.startIndex)..<spaceIndex]
                for pair in tagPart.split(separator: ";") {
                    let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                    let key = String(parts[0])
                    let value = parts.count > 1 ? String(parts[1]) : ""
                    tags[key] = value
                }
                rest = rest[rest.index(after: spaceIndex)...]
            } else {
                let tagPart = rest.dropFirst()
                for pair in tagPart.split(separator: ";") {
                    let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                    let key = String(parts[0])
                    let value = parts.count > 1 ? String(parts[1]) : ""
                    tags[key] = value
                }
                rest = rest[rest.endIndex...]
            }
        }

        // Prefix
        var prefix: IRCPrefix? = nil
        if rest.first == ":" {
            if let spaceIndex = rest.firstIndex(of: " ") {
                let prefixStr = String(rest[rest.index(after: rest.startIndex)..<spaceIndex])
                prefix = parsePrefix(prefixStr)
                rest = rest[rest.index(after: spaceIndex)...]
            } else {
                let prefixStr = String(rest.dropFirst())
                prefix = parsePrefix(prefixStr)
                rest = rest[rest.endIndex...]
            }
        }

        // Command
        let commandEnd = rest.firstIndex(of: " ") ?? rest.endIndex
        let commandStr = String(rest[..<commandEnd])
        let command = IRCCommand(commandStr)
        rest = commandEnd == rest.endIndex ? rest[commandEnd...] : rest[rest.index(after: commandEnd)...]

        // Parameters
        var params: [String] = []
        var tmp = rest
        while !tmp.isEmpty {
            if tmp.first == ":" {
                params.append(String(tmp.dropFirst()))
                break
            }
            if let spaceIndex = tmp.firstIndex(of: " ") {
                params.append(String(tmp[..<spaceIndex]))
                tmp = tmp[tmp.index(after: spaceIndex)...]
            } else {
                params.append(String(tmp))
                break
            }
        }

        return IRCMessage(tags: tags, prefix: prefix, command: command, parameters: params)
    }

    private func parsePrefix(_ str: String) -> IRCPrefix {
        if let bang = str.firstIndex(of: "!") {
            let nick = String(str[..<bang])
            let remainder = str[str.index(after: bang)...]
            if let at = remainder.firstIndex(of: "@") {
                let user = String(remainder[..<at])
                let host = String(remainder[remainder.index(after: at)...])
                return .user(nick: nick, user: user.isEmpty ? nil : user, host: host.isEmpty ? nil : host)
            } else {
                return .user(nick: nick, user: String(remainder), host: nil)
            }
        } else if let at = str.firstIndex(of: "@") {
            let nick = String(str[..<at])
            let host = String(str[str.index(after: at)...])
            return .user(nick: nick, user: nil, host: host.isEmpty ? nil : host)
        } else {
            return .server(str)
        }
    }
}

extension IRCCommand {
    public init(_ raw: String) {
        switch raw.uppercased() {
        case "PRIVMSG": self = .privmsg
        case "JOIN": self = .join
        case "PART": self = .part
        case "PING": self = .ping
        case "PONG": self = .pong
        case "CAP": self = .cap
        case "AUTHENTICATE": self = .authenticate
        case "NICK": self = .nick
        case "USER": self = .user
        default:
            if let num = Int(raw) {
                self = .numeric(num)
            } else {
                self = .other(raw)
            }
        }
    }
}
