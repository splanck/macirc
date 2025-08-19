import XCTest
@testable import NetKit

final class SASLTests: XCTestCase {
    func testPlainSASLFlow() {
        let mock = MockIRCConnection()
        let client = IRCClient(connection: mock, nick: "nick", username: "user", sasl: .plain(username: "user", password: "pass"))
        client.start()
        XCTAssertEqual(mock.sentLines, ["CAP LS 302"])
        mock.feed(Data(":server CAP * LS :sasl\r\n".utf8))
        XCTAssertEqual(mock.sentLines, ["CAP LS 302", "CAP REQ :sasl"])
        mock.feed(Data(":server CAP * ACK :sasl\r\n".utf8))
        XCTAssertEqual(mock.sentLines, ["CAP LS 302", "CAP REQ :sasl", "AUTHENTICATE PLAIN"])
        mock.feed(Data("AUTHENTICATE +\r\n".utf8))
        XCTAssertEqual(mock.sentLines, ["CAP LS 302", "CAP REQ :sasl", "AUTHENTICATE PLAIN", "AUTHENTICATE AHVzZXIAcGFzcw=="])
        mock.feed(Data(":server 903 nick :SASL authentication successful\r\n".utf8))
        XCTAssertEqual(mock.sentLines, ["CAP LS 302", "CAP REQ :sasl", "AUTHENTICATE PLAIN", "AUTHENTICATE AHVzZXIAcGFzcw==", "CAP END", "NICK nick", "USER user 0 * :user"])
    }

    func testExternalSASLFlow() {
        let mock = MockIRCConnection()
        let client = IRCClient(connection: mock, nick: "nick", username: "user", sasl: .external)
        client.start()
        XCTAssertEqual(mock.sentLines, ["CAP LS 302"])
        mock.feed(Data(":server CAP * LS :sasl\r\n".utf8))
        XCTAssertEqual(mock.sentLines, ["CAP LS 302", "CAP REQ :sasl"])
        mock.feed(Data(":server CAP * ACK :sasl\r\n".utf8))
        XCTAssertEqual(mock.sentLines, ["CAP LS 302", "CAP REQ :sasl", "AUTHENTICATE EXTERNAL"])
        mock.feed(Data("AUTHENTICATE +\r\n".utf8))
        XCTAssertEqual(mock.sentLines, ["CAP LS 302", "CAP REQ :sasl", "AUTHENTICATE EXTERNAL", "AUTHENTICATE ="])
        mock.feed(Data(":server 903 nick :SASL authentication successful\r\n".utf8))
        XCTAssertEqual(mock.sentLines, ["CAP LS 302", "CAP REQ :sasl", "AUTHENTICATE EXTERNAL", "AUTHENTICATE =", "CAP END", "NICK nick", "USER user 0 * :user"])
    }
}
