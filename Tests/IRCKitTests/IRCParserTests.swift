import XCTest
@testable import IRCKit

final class IRCParserTests: XCTestCase {
    func testPrivmsgParsing() {
        let parser = IRCParser()
        let message = parser.parse("@aaa=bbb;ccc :nick!user@host PRIVMSG #channel :Hello world")
        XCTAssertEqual(message.tags["aaa"], "bbb")
        XCTAssertEqual(message.tags["ccc"], "")
        if case let .user(nick, user, host) = message.prefix {
            XCTAssertEqual(nick, "nick")
            XCTAssertEqual(user, "user")
            XCTAssertEqual(host, "host")
        } else {
            XCTFail("Expected user prefix")
        }
        XCTAssertEqual(message.command, .privmsg)
        XCTAssertEqual(message.parameters, ["#channel", "Hello world"])
    }

    func testNumericParsing() {
        let parser = IRCParser()
        let message = parser.parse(":server 001 nick :Welcome")
        XCTAssertEqual(message.prefix, .server("server"))
        XCTAssertEqual(message.command, .numeric(1))
        XCTAssertEqual(message.parameters, ["nick", "Welcome"])
    }

    func testPingParsing() {
        let parser = IRCParser()
        let message = parser.parse("PING :server")
        XCTAssertNil(message.prefix)
        XCTAssertEqual(message.command, .ping)
        XCTAssertEqual(message.parameters, ["server"])
    }
}
