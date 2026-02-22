//
//  SharedState.swift
//  
//
//  Created by 黄磊 on 2023/6/4.
//

import DataFlow
import SwiftUI
import Combine

/**
 DynamicProperty 中 update() 方法虽然是 mutating，但是在这里修改 struct，不会影响原本的 struct
 这里只能用 struct，使用 class 界面似乎不会更新
 */

/// 共享状态包装器
@MainActor
@propertyWrapper
public struct SharedState<State: SharableState>: @preconcurrency DynamicProperty {
    
    /// 内部存储
    @ObservedObject
    var storage: SharedStoreStorage<State>
        
    @Environment(\.sceneId)
    var sceneId
    
    public init() {
        // 这里是默认初始化方法，如果当前只是 SharableState，会走这里，SceneSharableState 会走另一个 init 方法
        storage = .init { _ in .shared }
        storage.configStoreIfNeed(.main)
    }
    
    public var wrappedValue: State {
        get {
            if let store = storage.store {
                return store.state
            }
            ViewMonitor.shared.fatalError("Can't get state before update() get call")
            return .init()
        }

        nonmutating set {
            if let store = storage.store {
                store.state = newValue
            } else {
                ViewMonitor.shared.fatalError("Can't set state before update() get call")
            }
        }
    }
    
    public var projectedValue: Store<State> {
        if let store = storage.store {
            return store
        }
        ViewMonitor.shared.fatalError("Can't get projectedValue before update() get call")
        return .box(.init(), configs: [.make(.useBoxOnShared, true)])
    }
    
    mutating public func update() {
        if storage.store == nil {
            storage.configStoreIfNeed(sceneId)
        }
    }
}


// MARK: - SharedStoreStorage

/// 场景共享状态包装器对应存储器，暂时只在内部使用
@MainActor final class SharedStoreStorage<State: SharableState>: ObservableObject {
    
    @Published
    var refreshTrigger: Bool = false
    var store: Store<State>? = nil
    
    var cancellable: AnyCancellable? = nil
    
    var makeStore: (_ sceneId: SceneId) -> Store<State>
    
    init(makeStore: @escaping (_ sceneId: SceneId) -> Store<State>) {
        self.makeStore = makeStore
    }
    
    @inlinable
    func configStoreIfNeed(_ sceneId: SceneId) {
        if store == nil {
            let newStore = makeStore(sceneId)
            self.cancellable = newStore.addObserver { [weak self] new, old in
                self?.refreshTrigger.toggle()
            }
            self.store = newStore
        }
    }
}

// MARK: - SceneSharableState

extension SharedState where State: SceneSharableState {
    public init() {
        // 这里只构造 storage，store 在调用首次 update 方法是构造
        storage = .init { Store<State>.shared(on: $0) }
    }
}

// MARK: - SceneSharedStoreContainer

extension Store where State == SceneState {
    /// 当前场景可共享状态的 Store 存储器
    @usableFromInline
    nonisolated var sharedStoreContainer: SceneSharedStoreContainer {
        self.storage[SceneSharedStoreContainerKey.self]
    }
    
    /// 获取当前 Scene 共享的状态
    @usableFromInline
    nonisolated func getSharedStore<S: SceneSharableState>(of stateType: S.Type) -> Store<S> {
        return sharedStoreContainer.getSharedStore(of: S.self)
    }
}

struct SceneSharedStoreContainerKey: SceneStorageKey {
    static func defaultValue(on sceneStore: Store<SceneState>?) -> SceneSharedStoreContainer {
        return .init(sceneStore: sceneStore)
    }
}

/// 自定义 store 存储器，scene 中的共享 store 需要有地方保存
@usableFromInline
final class SceneSharedStoreContainer {
    let sceneId: SceneId
    var mapExistSharedStore: [ObjectIdentifier:AnyStore] = [:]
    weak var sceneStore: Store<SceneState>?
    
    init(sceneStore: Store<SceneState>?) {
        self.sceneId = sceneStore?[.sceneId] ?? .main
        self.mapExistSharedStore = [:]
        self.sceneStore = sceneStore
    }
    
    @MainActor private static func attachToUpStore<State: SceneSharableState>(_ store: Store<State>, on sceneId: SceneId) {
        // 判断 upStore 是否添加了当前的状态
        if !(State.UpState.self is Never.Type) {
            let upStore = SceneState.sharedStore(on: sceneId).getSharedStore(of: State.UpState.self)
            if let existState = upStore.subStates[store.state.stateId] {
                ViewMonitor.shared.fatalError(
                    "Attach SceneSharableState[\(String(describing: State.self))] to UpState[\(String(describing: State.UpState.self))] " +
                    "with stateId[\(store.state.stateId)] failed: " +
                    "exist State[\(String(describing: type(of: existState)))] with same stateId!")
            }
            upStore.add(subStore: store)
        }
    }
    
    func getSharedStore<State: SceneSharableState>(of stateType: State.Type) -> Store<State> {
        let key = ObjectIdentifier(State.self)
        var existOne: Bool = false
        let sceneId = sceneId
        let store: Store<State> = DispatchQueue.syncOnStoreQueue {
            if let theStore = mapExistSharedStore[key]?.store as? Store<State> {
                existOne = true
                return theStore
            }
            // 一直向上会获取到 sceneStore，这里需要截断
            if State.self is SceneState.Type {
                if let theStore = sceneStore as? Store<State> {
                    return theStore
                }
                ViewMonitor.shared.fatalError("Get scene store failed")
                return .innerBox()
            }
            let theStore = Store<State>.innerBox(State(sceneId: sceneId))
            mapExistSharedStore[key] = theStore.eraseToAny()
            return theStore
        }
        if existOne {
            return store
        }
        
        DispatchQueue.executeOnMain {
            Self.attachToUpStore(store, on: sceneId)
        }
        return store
    }
}
