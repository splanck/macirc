import Foundation
#if canImport(Combine)
import Combine
public typealias ObservableObject = Combine.ObservableObject
public typealias Published = Combine.Published
#else
public protocol ObservableObject: AnyObject {}
@propertyWrapper public struct Published<Value> {
    public var wrappedValue: Value
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
#endif

public struct BufferState: Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var topic: String?

    public init(id: UUID = UUID(), name: String, topic: String? = nil) {
        self.id = id
        self.name = name
        self.topic = topic
    }
}

public enum BufferAction: Equatable {
    case add(BufferState)
    case remove(UUID)
    case setTopic(id: UUID, topic: String?)
}

public func buffersReducer(state: inout [UUID: BufferState], action: BufferAction) {
    switch action {
    case .add(let buffer):
        state[buffer.id] = buffer
    case .remove(let id):
        state.removeValue(forKey: id)
    case let .setTopic(id, topic):
        if var buffer = state[id] {
            buffer.topic = topic
            state[id] = buffer
        }
    }
}

public struct UserState: Identifiable, Equatable {
    public let id: UUID
    public var nick: String

    public init(id: UUID = UUID(), nick: String) {
        self.id = id
        self.nick = nick
    }
}

public enum UserAction: Equatable {
    case add(UserState)
    case remove(UUID)
}

public func usersReducer(state: inout [UUID: UserState], action: UserAction) {
    switch action {
    case .add(let user):
        state[user.id] = user
    case .remove(let id):
        state.removeValue(forKey: id)
    }
}

public struct TopicState: Equatable {
    public var text: String
    public var setBy: String?

    public init(text: String, setBy: String? = nil) {
        self.text = text
        self.setBy = setBy
    }
}

public enum TopicAction: Equatable {
    case set(bufferID: UUID, TopicState)
}

public func topicsReducer(state: inout [UUID: TopicState], action: TopicAction) {
    switch action {
    case let .set(bufferID, topic):
        state[bufferID] = topic
    }
}

public struct AppState: Equatable {
    public var buffers: [UUID: BufferState] = [:]
    public var users: [UUID: UserState] = [:]
    public var topics: [UUID: TopicState] = [:]

    public init(buffers: [UUID: BufferState] = [:], users: [UUID: UserState] = [:], topics: [UUID: TopicState] = [:]) {
        self.buffers = buffers
        self.users = users
        self.topics = topics
    }
}

public enum AppAction: Equatable {
    case buffer(BufferAction)
    case user(UserAction)
    case topic(TopicAction)
}

public func appReducer(state: inout AppState, action: AppAction) {
    switch action {
    case .buffer(let action):
        buffersReducer(state: &state.buffers, action: action)
    case .user(let action):
        usersReducer(state: &state.users, action: action)
    case .topic(let action):
        topicsReducer(state: &state.topics, action: action)
    }
}

public final class AppStore: ObservableObject {
    @Published public private(set) var state: AppState

    public init(initial state: AppState = AppState()) {
        self.state = state
    }

    public func dispatch(_ action: AppAction) {
        appReducer(state: &state, action: action)
    }
}
