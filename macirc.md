Below is a complete, end-to-end development plan for macIRC—a beautiful, Mac-only IRC client written in Swift + SwiftUI with a modern architecture, IRCv3 support, and production-grade foundations. It’s structured so you can hand sections directly to an implementation agent (e.g., “ChatGPT Pro 5 Codex”) as tickets.

0) Product brief

Goal: A fast, reliable, elegant IRC client for macOS with first-class SwiftUI UX, excellent IRCv3 support (SASL, server-time, message-tags, CHATHISTORY, echo-message, etc.), persistent logs with full-text search, theming, and power-user features.

Non-goals (initially): Mobile, Windows/Linux ports; bouncer hosting; video/voice; full plugin sandbox for untrusted native code.

Target macOS: 13+ (Ventura) minimum. Prefer 14+ for best SwiftUI/TextKit2 behavior.
Distribution: Mac App Store (MAS) and/or notarized DMG (Sparkle updates).

1) Feature set
MVP (Foundational)

Multi-server, multi-network connections.

IRCv3 capability negotiation: sasl, server-time, message-tags, echo-message, cap-notify, away-notify, account-notify, chghost, setname, multi-prefix, batch, labeled-response, standard-replies.

Auth: SASL PLAIN + EXTERNAL; NickServ fallback.

Channels, queries/DMs, notices, topics, modes; WHO/WHOX; user lists with away/op/voice badges.

CTCP: ACTION (/me), PING, TIME, VERSION.

Command system: /connect, /join, /part, /msg, /query, /topic, /mode, /kick, /ban, /op, /deop, /nick, /whois, /whowas, /away, /quit, /ignore, /invite, /notice, /list, /queryclose, /close.

Rendering: Rich message view with mIRC formatting codes (bold, italic, underline, colors), links, mentions, and code spans.

Persistent logs, scrollback, and resume (CHATHISTORY if server supports; ZNC/soju friendly).

Notifications for highlights/mentions/PMs with quiet hours/Focus filters.

Reconnect with exponential backoff; lag meter via PING.

Security: TLS with proper certificate validation; Keychain for secrets.

UI: Sidebar (networks/channels), tabs, unified compose box, nick autocomplete, emoji, configurable timestamps, nick coloring.

Settings: Accounts, Networks, Identity, Themes, Highlights, Ignore rules, Logging, Notifications, Proxies.

v1 polish

Full-text search (FTS) across logs.

Per-channel rules: notification level, word highlights, sound, badge.

Theming engine (light/dark/custom JSON); color-blind accessible presets.

Keyboard-first UX (Slack-like + IRC classics); menu commands; command palette.

Transcripts export (Plaintext/HTML/Markdown); Core Spotlight indexing.

Shortcuts support: “Join Channel”, “Send Message”, “Toggle Away”, “Search Logs”, etc.

Preliminary DCC CHAT (SEND optional later due to security/firewall complexity).

Optional URL preview (oEmbed/OpenGraph) with privacy guard (manual fetch).

Later / stretch

Draft typing indicator (IRCv3 draft/typing tags) with opt-in.

Plugins via a constrained ExtensionKit/JS sandbox (no unsigned native dylibs).

AppleScript dictionary for simple automation.

2) Architecture overview

Pattern: MVVM + Swift Concurrency + Actors, with a unidirectional data flow to SwiftUI views.

Layers:

IRCKit (Core) — IRC protocol types, parser, serializer, capability negotiation, state reducers, command router.

NetKit — Networking (Network.framework NWConnection), TLS, proxies, backoff/reconnect.

DataKit — Persistence (SQLite + FTS via GRDB or Core Data; plan below uses GRDB).

AppStore — App-level observable state (@MainActor ObservableObject) + Combine bridges.

UI — SwiftUI views, ViewModels, theming, app/scene/commands.

Integration — Keychain, Notifications, Shortcuts, Spotlight, Sparkle (non-MAS).

Concurrency model:

IRCClient and IRCConnection as actors.

Parsing and state mutation in isolated actors; view updates marshaled to main actor.

Event flow:
Socket read → line framing → parse to IRCMessage → capability/router → reducer updates session state → state diff published → UI renders.

3) Repository & module layout
macirc/
  Package.swift
  Sources/
    IRCKit/              # Protocol types, parser, serializer, caps, reducers
    NetKit/              # NWConnection, TLS, proxy, backoff
    DataKit/             # GRDB DB, migrations, FTS, repositories
    AppKitBridge/        # TextKit2 / NSTextView wrappers (SwiftUI compatible)
    ThemeKit/            # Theme model, JSON load/save, tokens
    macIRCApp/           # App target (SwiftUI), Scenes, ViewModels, Views
  Tests/
    IRCKitTests/
    NetKitTests/
    DataKitTests/
    IntegrationTests/    # Spins local InspIRCd container or mocks


If MAS-only: exclude Sparkle and Docker scripts from App target.

4) Data model
Core entities

Account: id, displayName, realName, saslMechanism, username, keychainRef, certIdentityRef (for EXTERNAL).

Network: id, accountId, name, servers[], preferredNick, altNicks[], autoJoinChannels[], useProxy?.

Server: host, port, tls, sniHost, passwordKeychainRef, enabledCaps[], isupport (serialized).

Buffer (generic container for channel, query, status): id, networkId, kind(.channel/.query/.status), name, topic, unreadCount, highlightCount, lastReadTimestamp.

User: nick, user, host, realname, account, modes, away.

Message: id, bufferId, networkId, serverTime, tags(json), sender(nick!user@host), kind(enum: privmsg/notice/action/join/part/kick/mode/topic/quit/etc), text, isSelf, labels (for labeled-response), batchId.

HighlightRule: pattern/regex, caseSensitive, channels[], networks[], notify, sound.

IgnoreRule: mask (nick!user@host), kinds[], duration?, reason?

Theme: id, name, base(light|dark), token map (see §11).

Preference: basic app settings (serialized).

Persistence choice

SQLite (GRDB) with normalized tables; FTS5 virtual table (messages_fts(text, content='messages', content_rowid='id')).

Pros: fast FTS, simple migrations, easy testability.

If you prefer Core Data, map with a lightweight schema and add a Spotlight indexer for search.

5) IRC protocol implementation
Standards & variants

RFC1459/2812 compliant base; numeric mapping table.

ISUPPORT (005) parser → features: CHANMODES, PREFIX, CASEMAPPING, STATUSMSG, TARGMAX, CHANLIMIT, NICKLEN, etc.

Capability negotiation flow:

Send CAP LS 302

Request intersection: CAP REQ :sasl server-time message-tags echo-message batch chathistory setname account-notify away-notify multi-prefix cap-notify labeled-response standard-replies

SASL auth if requested (AUTHENTICATE flow).

CAP END.

SASL

PLAIN (base64 authzid\0authcid\0passwd); secrets from Keychain.

EXTERNAL (client cert identity via Secure Transport/NWProtocolTLS) optional.

CHATHISTORY / ZNC/soju

If server advertises chathistory, fetch on join to backfill scrollback in windows.

Friendly to ZNC: recognize znc.in/batch-playback, znc.in/self-message, etc.

CTCP

Encode/decode CTCP frames over PRIVMSG/NOTICE; support ACTION, PING, TIME, VERSION.

Flood & rate limiting

Token bucket per connection; split long messages (512-byte IRC line limit including tags and CRLF).

6) Networking & reconnection

Network.framework (NWConnection) for TCP/TLS; configure TLS options and SNI.

SOCKS5/HTTP proxy: read system proxy settings; support manual overrides (fall back to CFStream if needed).

Reconnect policy: exponential backoff with jitter; reset after stable 5+ minutes; manual retry.

7) Security

Enforce TLS by default. Certificate validation via default trust; optional “Trust on first use” and manual pinning (advanced pref).

Secrets in Keychain with Access Group for future helpers.

Private data redaction in logs; “privacy mode” when sharing diagnostics.

8) App state & reducers

SessionState (per network) holds: myNick, user modes, channel maps, user lists, capabilities, batches, pending labeled requests, lag.

Reducers handle each IRCMessage (pure-ish transformations).

@MainActor AppStore publishes snapshot summaries used by ViewModels (derived values like sorted buffers, unread badges, etc.).

9) UI/UX plan (SwiftUI + AppKit bridge where needed)
Layout

Primary window: NavigationSplitView

Sidebar: Networks → Buffers (channels/queries) with badges (unread/highlight).

Content: Message transcript + topic bar + members list toggle.

Composer: Single-line grows to multi-line; supports /commands, nick/emoji autocomplete, file/URL paste (uploads only as URLs).

Secondary panes: Right side members list with roles (op/voice/away).

Tabs: per window or per network; quick switcher (⌘K).

Settings: native Settings scene with panes (Accounts, Networks, Appearance, Notifications, Logging, Advanced).

Message view

Use TextKit 2 (NSTextView) wrapped via NSViewRepresentable for high-performance attributed rendering with link detection, hover tooltips, and context menu; or a custom AttributedText renderer if TextKit 2 suffices in SwiftUI.

Inline styling for mIRC control codes; theme tokens for nick colors; timestamps in gutter optional.

Accessibility & polish

Dynamic type scaling; VoiceOver labels for roles/joins/parts; high-contrast themes.

Keyboard shortcuts for every major action; Command Palette (⌘P/⌘K).

10) Command system

Registry: CommandRegistry mapping /name → handler.

Parser: tokenizes respecting quotes; provides argv + raw tail.

Help: /help [command] prints usage, args, examples.

Aliases: user-configurable; environment variables for nick/channel substitution.

Seed commands & usage (examples):

/connect irc.libera.chat +6697 -n MyNick -u myuser -r "Real Name" --sasl=plain

/join #swift,#macos

/msg nick hello there

/notice #channel Maintenance in 5m

/topic #swift New release is out

/mode #swift +o @alice

/whois bob

/ignore badguy!*@*

/me waves

/quit Gone fishing

11) Theming

Theme model (JSON):

{
  "id": "solarized-dark",
  "name": "Solarized Dark",
  "base": "dark",
  "tokens": {
    "bg.window": "#002b36",
    "bg.sidebar": "#073642",
    "fg.primary": "#eee8d5",
    "fg.secondary": "#93a1a1",
    "fg.link": "#268bd2",
    "msg.self": "#b58900",
    "msg.highlight.bg": "#3b4c52",
    "nick.colors": ["#268bd2","#2aa198","#859900","#b58900","#cb4b16","#d33682","#6c71c4"]
  }
}


Tokenized palette → SwiftUI Color via ThemeKit.

mIRC color translation table in ThemeKit (e.g., 0-15 to theme tokens).

Live theme switch; per-channel overrides (optional later).

12) Notifications

UNUserNotificationCenter; deliver highlights/PMs with:

per-buffer rules (All/Highlight/None).

quiet hours; Focus integration; clicking notification focuses buffer.

Badge counts on app icon; per-network unread badges in sidebar.

13) Search & logs

Store all messages in SQLite.

FTS5 virtual table mirrors message text for instant search; filter by network/buffer/sender/time range.

Spotlight indexing (optional): create searchable items per day/channel.

Log export: plaintext/HTML/Markdown; include topic header and timestamps.

14) Preferences & onboarding

First-run: add account (nickname, username, realname), pick networks from presets (Libera, OFTC, etc.), optional SASL, auto-join channels.

Preferences panes:

Accounts (identity, alt nicks, SASL, certs)

Networks & Servers (list, order, proxy per network)

Appearance (theme, font, size, timestamp style, compact/comfortable density)

Notifications (global + per-buffer overrides)

Logging & Search (retention, export, FTS index rebuild)

Advanced (TLS, trust/pinning, flood control, debug logs)

15) Error handling & diagnostics

Status buffer per network for connection/system messages.

In-app diagnostics view: connection log (info/warn/error), capability list, ISUPPORT dump.

Optional shareable diagnostic bundle (redacted).

16) Testing strategy

IRCKitTests: parser/serializer golden tests; numeric handling; mIRC codes; CAP/SASL flows.

NetKitTests: connection lifecycle, backoff, TLS handshake with local test certs.

DataKitTests: migrations, FTS queries, retention pruning.

IntegrationTests: scripted sessions against mocked server or Dockerized InspIRCd (CI optional).

UITests (XCTest): join channel, send message, search logs, notification tap.

17) Build, signing, distribution

App Sandbox: com.apple.security.network.client = true, Keychain access, optionally files.user-selected.read-write for custom log folder.

MAS build vs. DMG: If DMG, integrate Sparkle for updates.

swift-format + SwiftLint; per-target optimization flags (-Osize for release).

18) Performance plan

Measure render throughput with 100k-message buffers; virtualize message list (TextKit view handles efficient layout).

Avoid main-thread work in parsing/networking; coalesce UI updates.

Use diff-aware append for live messages; prune in-memory caches by LRU.

19) Risks & mitigations

SwiftUI text performance → use TextKit2 bridge for transcripts.

Server variance (ISUPPORT quirks) → robust parser; feature gates per network.

FTS index size → retention policies; per-channel toggles; vacuum/rebuild commands.

20) Implementation milestones (sequence, no dates)

Project scaffolding & packages (IRCKit, NetKit, DataKit, ThemeKit, App).

Line parser & message types (MVP numerics + PRIVMSG/NOTICE/JOIN/PART/TOPIC/MODE).

NWConnection + TLS (basic connect/send/receive loop).

CAP + SASL (PLAIN, EXTERNAL), echo-message, server-time.

Reducers & AppStore (session state, buffers, users, topics).

SwiftUI shell (Sidebar, Transcript via TextKit bridge, Composer).

Command registry (core commands).

Persistence & FTS (store, hydrate buffers, search UI).

Notifications & highlights.

Theming (tokens + 2 built-in themes).

ISUPPORT & modes; users list; WHO/WHOX; badges.

CHATHISTORY backfill; ZNC/soju playback compatibility.

Settings panes; onboarding.

QA & hardening (profiling, backoff, edge numerics, crash fixes).

Docs & distribution (MAS/DMG, Sparkle if DMG).

21) Code skeletons (ready for expansion)
21.1 IRC message types & parser (IRCKit)
// Sources/IRCKit/IRCMessage.swift
public struct IRCMessage: Sendable {
    public struct Prefix: Sendable {
        public let nick: String?
        public let user: String?
        public let host: String?
    }

    public let raw: String
    public let tags: [String: String]
    public let prefix: Prefix?
    public let command: IRCCommand
    public let params: [String]
    public let serverTime: Date?
}

public enum IRCCommand: Equatable, Sendable {
    case cap, authenticate, privmsg, notice, join, part, topic, mode, ping, pong, quit, nick, error
    case numeric(Int)
}

// Sources/IRCKit/IRCParser.swift
public enum IRCParseError: Error { case invalid, tooLong }

public struct IRCParser: Sendable {
    public init() {}

    public func parseLine(_ line: String) throws -> IRCMessage {
        // RFC 1459 framing with IRCv3 message tags
        var s = line
        guard s.utf8.count <= 512 else { throw IRCParseError.tooLong }

        var tags: [String:String] = [:]
        if s.hasPrefix("@") {
            let parts = s.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
            if let tagPart = parts.first {
                for kv in tagPart.dropFirst().split(separator: ";") {
                    let pair = kv.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                    let k = String(pair[0])
                    let v = pair.count > 1 ? String(pair[1]).replacingOccurrences(of: "\\:", with: ";") : ""
                    tags[k] = v
                }
            }
            s = parts.count > 1 ? String(parts[1]) : ""
        }

        var prefix: IRCMessage.Prefix? = nil
        if s.hasPrefix(":") {
            let parts = s.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
            let p = String(parts[0].dropFirst())
            let nickUserHost = p.split(separator: "!", maxSplits: 1, omittingEmptySubsequences: false)
            if nickUserHost.count == 2 {
                let userHost = nickUserHost[1].split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
                prefix = .init(nick: String(nickUserHost[0]), user: userHost.first.map(String.init), host: userHost.count > 1 ? String(userHost[1]) : nil)
            } else {
                prefix = .init(nick: nil, user: nil, host: p)
            }
            s = parts.count > 1 ? String(parts[1]) : ""
        }

        var params: [String] = []
        var command = ""
        if let firstSpace = s.firstIndex(of: " ") {
            command = String(s[..<firstSpace])
            var rest = s[s.index(after: firstSpace)...]
            while !rest.isEmpty {
                if rest.first == ":" {
                    params.append(String(rest.dropFirst()))
                    break
                }
                if let sp = rest.firstIndex(of: " ") {
                    params.append(String(rest[..<sp]))
                    rest = rest[rest.index(after: sp)...]
                } else {
                    params.append(String(rest))
                    break
                }
                while rest.first == " " { rest.removeFirst() }
            }
        } else {
            command = s
        }

        let cmd: IRCCommand = Int(command).map { .numeric($0) } ??
            [
                "CAP": .cap, "AUTHENTICATE": .authenticate, "PRIVMSG": .privmsg,
                "NOTICE": .notice, "JOIN": .join, "PART": .part, "TOPIC": .topic,
                "MODE": .mode, "PING": .ping, "PONG": .pong, "QUIT": .quit, "NICK": .nick, "ERROR": .error
            ][command.uppercased()] ?? .numeric(-1)

        let serverTime: Date? = {
            if let ts = tags["time"] {
                // ISO8601 `server-time`
                return ISO8601DateFormatter().date(from: ts)
            }
            return nil
        }()

        return IRCMessage(raw: line, tags: tags, prefix: prefix, command: cmd, params: params, serverTime: serverTime)
    }
}

21.2 Connection & client actors
// Sources/NetKit/IRCConnection.swift
import Network

public actor IRCConnection {
    public enum State { case idle, connecting, connected, failed(Error), cancelled }
    public private(set) var state: State = .idle

    private var connection: NWConnection?
    private let host: NWEndpoint.Host
    private let port: NWEndpoint.Port
    private let useTLS: Bool

    public init(host: String, port: UInt16, tls: Bool) {
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: port)!
        self.useTLS = tls
    }

    public func connect() {
        let params = NWParameters.tcp
        if useTLS {
            let tls = NWProtocolTLS.Options()
            // Configure TLS if needed (SNI, client identity)
            params.defaultProtocolStack.applicationProtocols.insert(tls, at: 0)
        }
        let conn = NWConnection(host: host, port: port, using: params)
        self.connection = conn
        state = .connecting
        conn.stateUpdateHandler = { [weak self] newState in
            Task { await self?.handle(state: newState) }
        }
        conn.start(queue: .global())
        receiveLoop()
    }

    public func send(line: String) {
        guard let conn = connection else { return }
        var s = line
        if !s.hasSuffix("\r\n") { s += "\r\n" }
        conn.send(content: s.data(using: .utf8), completion: .contentProcessed { _ in })
    }

    public func cancel() {
        connection?.cancel()
        connection = nil
        state = .cancelled
    }

    private func receiveLoop() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let d = data, !d.isEmpty {
                Task { await self?.bufferAndEmit(d) }
            }
            if let error = error {
                Task { await self?.state = .failed(error) }
                return
            }
            if isComplete { Task { await self?.cancel() }; return }
            self?.receiveLoop()
        }
    }

    // Framing bytes into CRLF delimited lines; call listener with each line.
    private var partial = Data()
    public var onLine: ((String) -> Void)?

    private func bufferAndEmit(_ data: Data) {
        partial.append(data)
        while let range = partial.firstRange(of: Data([13,10])) { // CRLF
            let lineData = partial.subdata(in: 0..<range.lowerBound)
            partial.removeSubrange(0..<range.upperBound)
            if let line = String(data: lineData, encoding: .utf8) {
                onLine?(line)
            }
        }
    }

    private func handle(state newState: NWConnection.State) {
        switch newState {
        case .ready: state = .connected
        case .failed(let err): state = .failed(err)
        case .cancelled: state = .cancelled
        default: break
        }
    }
}

// Sources/IRCKit/IRCClient.swift
public actor IRCClient {
    private let connection: IRCConnection
    private let parser = IRCParser()
    private(set) var caps: Set<String> = []
    // ... session state (nick, channels, users)

    public init(connection: IRCConnection) {
        self.connection = connection
    }

    public func start() {
        connection.onLine = { [weak self] line in
            Task { await self?.handle(line: line) }
        }
        Task { await connection.connect() }
        send("CAP LS 302")
        // then NICK/USER sequence
    }

    public func send(_ line: String) {
        Task { await connection.send(line: line) }
    }

    private func handle(line: String) {
        do {
            let msg = try parser.parseLine(line)
            try await route(msg)
        } catch { /* log parse error */ }
    }

    private func route(_ m: IRCMessage) async throws {
        switch m.command {
        case .ping: send("PONG \(m.params.last ?? "")")
        case .cap:
            // handle LS/ACK/NAK; request caps; SASL flow
            break
        case .authenticate:
            // SASL steps
            break
        case .privmsg:
            // reduce into state, publish to observers
            break
        case .numeric(let code):
            // RPL_WELCOME, ISUPPORT, WHO, etc.
            break
        default: break
        }
    }
}

21.3 App store & views
// Sources/macIRCApp/AppStore.swift
import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var networks: [NetworkViewState] = []
    @Published var selectedBufferID: UUID?
    // derived counters, highlights, etc.
}

// Sources/macIRCApp/macIRCApp.swift
@main
struct macIRCApp: App {
    @StateObject private var store = AppStore()
    var body: some Scene {
        WindowGroup("macIRC") { RootView().environmentObject(store) }
        Settings { SettingsView().environmentObject(store) }
        // Commands (menus)
        .commands { AppCommands(store: store) }
    }
}

// Sources/macIRCApp/Views/RootView.swift
struct RootView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } content: {
            BufferListView()
        } detail: {
            TranscriptView()
                .toolbar { ComposerView() }
        }
    }
}


For the transcript, wrap an NSTextView (TextKit 2) via NSViewRepresentable for high-performance attributed layouts and live insertion.

22) GRDB schema & migrations (DataKit)

Migration 1 (initial):

CREATE TABLE accounts (
  id TEXT PRIMARY KEY, displayName TEXT, realName TEXT, saslMechanism TEXT,
  username TEXT, keychainRef TEXT, certIdentityRef TEXT
);
CREATE TABLE networks (
  id TEXT PRIMARY KEY, accountId TEXT, name TEXT, preferredNick TEXT,
  altNicks TEXT, autoJoin TEXT, useProxy INTEGER, FOREIGN KEY(accountId) REFERENCES accounts(id)
);
CREATE TABLE servers (
  id TEXT PRIMARY KEY, networkId TEXT, host TEXT, port INTEGER, tls INTEGER,
  sniHost TEXT, passwordKeychainRef TEXT, enabledCaps TEXT, isupport TEXT,
  FOREIGN KEY(networkId) REFERENCES networks(id)
);
CREATE TABLE buffers (
  id TEXT PRIMARY KEY, networkId TEXT, kind INTEGER, name TEXT, topic TEXT,
  unreadCount INTEGER, highlightCount INTEGER, lastReadTs REAL
);
CREATE TABLE messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bufferId TEXT, networkId TEXT, serverTime REAL, sender TEXT, kind INTEGER,
  text TEXT, isSelf INTEGER, tags TEXT, batchId TEXT,
  FOREIGN KEY(bufferId) REFERENCES buffers(id)
);
CREATE VIRTUAL TABLE messages_fts USING fts5(text, content='messages', content_rowid='id');
CREATE TRIGGER messages_ai AFTER INSERT ON messages BEGIN
  INSERT INTO messages_fts(rowid, text) VALUES (new.id, new.text);
END;
CREATE TRIGGER messages_ad AFTER DELETE ON messages BEGIN
  INSERT INTO messages_fts(messages_fts, rowid, text) VALUES('delete', old.id, old.text);
END;

23) Highlighting & ignore

Compile HighlightRule into NSRegularExpression on load; evaluate on inbound messages → mark & notify.

IgnoreRule matches nick!user@host masks and message kinds; drop before persistence (optional “shadow” mode to keep but hide).

24) Keyboard shortcuts

Global: ⌘K Quick Switcher; ⌘T new tab; ⌘W close buffer; ⌘F search; ⌘L focus composer; ⌘/ help; ⇧⌘A toggle members list.

Navigating buffers: ⌥⌘↑/↓ or ⌘1…⌘9 for quick slots.

Message actions: ⌘↩ send; ⌥↩ new line.

25) Definition of Done (per major area)

Connection: TLS handshake succeeds; reconnect after network loss; PING/PONG w/ <1s overhead; backlog preserved across reconnect (CHATHISTORY or buffered logs).
Parser: 100% test coverage for numerics/CTCP/mIRC codes; rejects >512 bytes lines.
UI: 60fps transcript scroll on 100k messages; copy/paste keeps formatting and links.
Persistence: FTS search returns results under 50 ms for 100k messages/channel on average hardware.
Notifications: Highlight rules trigger only once per message; notification click focuses correct buffer.
Theming: Switch theme without restart; transcript repaints within one frame.

26) Initial “ticket seeds”

Scaffold SPM workspace & targets (Package.swift, targets, sample test).

Implement IRCParser + tests (golden vectors).

NWConnection wrapper with CRLF framing and send queue.

CAP/SASL negotiator (PLAIN) + integration test with mock.

Session reducers for JOIN/PART/PRIVMSG/NOTICE/TOPIC/MODE.

TextKit2 SwiftUI bridge for transcript; link detection; context menu.

Sidebar + buffers list (badges).

Composer with /command parsing and nick autocomplete.

GRDB database + repositories; message append + hydrate buffers.

FTS search UI (in-buffer & global).

Highlights & notifications (+ quiet hours).

Settings panes (Accounts, Networks, Appearance, Notifications, Logging, Advanced).

ISUPPORT parser; WHO/WHOX; members list with roles.

CHATHISTORY backfill; ZNC batch playback.

Theming engine; two built-in themes (Light, Dark).

QA pass (profiling, memory, race checks), crash reporting hook, release configs.

27) Notes on MAS compliance

Avoid private APIs; no dynamic code loading for plugins in MAS build.

Respect user privacy for URL previews (off by default, click-to-load).

Only request notification permission on first highlight event or settings screen.

28) Future enhancements (design-ready)

Draft typing (send/receive message tags like +draft/typing=active/paused).

DCC SEND (with sandboxed “Downloads” folder and safety warnings).

Plugin SDK using JavaScriptCore/ExtensionKit with strict API surface (messages in/out, UI add-ins via WebView panels).

Appendix A: mIRC control codes map

Bold: \u{02}; Italic: \u{1D}; Underline: \u{1F}; Reverse: \u{16}; Color: \u{03}(\d{1,2})(?:,(\d{1,2}))?; Reset: \u{0F}.

Appendix B: Safe message splitting

Compute UTF-8 byte length of tags + prefix + command + params + CRLF; ensure ≤512 bytes; if over, split the trailing parameter text into multiple PRIVMSGs with (n/total) continuation marker (optional).

What to implement first (in order)

Parser + tests → 2) Connection + send/recv loop → 3) CAP/SASL negotiator → 4) Reducers + AppStore → 5) SwiftUI shell (Sidebar/Transcript/Composer) → 6) Persistence + FTS → 7) Highlights + notifications → 8) ISUPPORT/WHO/Users list → 9) CHATHISTORY → 10) Theming → 11) Settings/onboarding → 12) Stabilize & ship.
