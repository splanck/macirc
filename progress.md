# Progress

- Scaffolded modules: IRCKit, NetKit, DataKit, ThemeKit, macIRCApp
- Initial package setup committed
- Implemented IRCMessage and IRCParser with support for tags, prefixes, and basic commands
- Added unit tests covering numerics and common IRC messages
- Implemented NWConnection wrapper with TLS and CRLF framing plus mockable interface
- Added tests validating send/receive CRLF behavior and updated networking scaffolding
- Introduced capability negotiation with SASL PLAIN and EXTERNAL support in NetKit
- Added integration tests using mocked server responses to verify CAP/SASL flows
- Integration tests pass confirming successful CAP negotiation and SASL authentication
