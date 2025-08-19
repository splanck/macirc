import XCTest
@testable import NetKit

final class MockIRCConnection: IRCConnection {
    var lineHandler: ((String) -> Void)?
    private(set) var sentData: [Data] = []
    private var buffer = Data()
    private let crlf = Data("\r\n".utf8)

    func connect() {}

    func send(line: String) {
        sentData.append(Data((line + "\r\n").utf8))
    }

    func cancel() {}

    /// Helper to feed raw data as if it was received from the network.
    func feed(_ data: Data) {
        buffer.append(data)
        while let range = buffer.range(of: crlf) {
            let lineData = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
            buffer.removeSubrange(buffer.startIndex..<range.upperBound)
            if let line = String(data: lineData, encoding: .utf8) {
                lineHandler?(line)
            }
        }
    }
}

final class NetKitTests: XCTestCase {
    func testInit() {
        _ = NetKit()
        XCTAssertTrue(true)
    }

    func testSendAppendsCRLF() {
        let mock = MockIRCConnection()
        mock.send(line: "PING")
        let sent = String(data: mock.sentData.first ?? Data(), encoding: .utf8)
        XCTAssertEqual(sent, "PING\r\n")
    }

    func testReceiveSplitsOnCRLF() {
        let mock = MockIRCConnection()
        var lines: [String] = []
        mock.lineHandler = { lines.append($0) }
        mock.feed(Data("first\r\nsecond\r\npartial".utf8))
        XCTAssertEqual(lines, ["first", "second"])
        mock.feed(Data("\r\n".utf8))
        XCTAssertEqual(lines, ["first", "second", "partial"])
    }
}
