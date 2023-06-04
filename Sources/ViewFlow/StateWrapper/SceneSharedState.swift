//
//  SceneState.swift
//
//
//  Created by 黄磊 on 2022/5/3.
//  Copyright © 2022 Miejoy. All rights reserved.
//  对当前场景内的可共享状态

import Combine
import SwiftUI
import DataFlow

/// 同 scene 下可共享的状态
public protocol SceneSharableState: SharableState where UpState: SceneSharableState {
    associatedtype UpState = SceneState
    
    init(on sceneId: SceneId)
}

/// 完整的 scene 下可共享状态
public protocol FullSceneSharableState: SceneSharableState, ReducerLoadableState, ActionBindable {}

extension SceneSharableState {
    /// 默认调用无参数初始化方法
    public init(on sceneId: SceneId) {
        self.init()
    }
}

/**
 DynamicProperty 中 update() 方法虽然是 mutating，但是在这里修改 struct，不会影响原本的 struct
 这里只能用 struct，使用 class 界面似乎不会更新
 */

/// 场景内共享状态包装器
@propertyWrapper
public struct SceneSharedState<State: SceneSharableState>: DynamicProperty {

    /// 内部存储
    @ObservedObject
    var storage: SceneSharedStateWrapperStorage<State> = .init()
    
    @Environment(\.sceneId)
    var sceneId

    public init() {}
    
    public var wrappedValue: State {
        get {
            if let store = storage.store {
                return store.state
            }
            fatalError("Can't get state before update() get call")
        }

        nonmutating set {
            if let store = storage.store {
                store.state = newValue
            } else {
                fatalError("Can't set state before update() get call")
            }
        }
    }
    
    public var projectedValue: Store<State> {
        if let store = storage.store {
            return store
        }
        fatalError("Can't get projectedValue before update() get call")
    }
    
    public func update() {
        if storage.store == nil {
            storage.configStoreIfNeed(sceneId)
        }
    }
}

// MARK: - SceneSharedStateWrapperStorage

/// 场景共享状态包装器对应存储器，暂时只在内部使用
final class SceneSharedStateWrapperStorage<State: SceneSharableState>: ObservableObject {
    
    @Published
    var refreshTrigger: Bool = false
    var store: Store<State>? = nil
    
    var cancellable: AnyCancellable? = nil
        
    func configStoreIfNeed(_ sceneId: SceneId) {
        if store == nil {
            let newStore = initStore(sceneId)
            self.cancellable = newStore.addObserver { [weak self] new, old in
                self?.refreshTrigger.toggle()
            }
            self.store = newStore
        }
    }
    
    func initStore(_ sceneId: SceneId) -> Store<State> {
        Store<State>.shared(on: sceneId)
    }
}

// MARK: - SceneSharedStoreContainer

extension SceneState {
    /// 当前场景可共享状态的 Store 存储器
    @usableFromInline
    var storeContainer: SceneSharedStoreContainer {
        self.storage[SceneSharedStoreContainerKey.self]
    }
    
    /// 获取当前 Scene 共享的状态
    @usableFromInline
    func getSharedStore<State: SceneSharableState>(of stateType: State.Type) -> Store<State> {
        return storeContainer.getSharedStore(of: State.self)
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
        self.sceneId = sceneStore?.sceneId ?? .main
        self.mapExistSharedStore = [:]
        self.sceneStore = sceneStore
    }
    
    func getSharedStore<State: SceneSharableState>(of stateType: State.Type) -> Store<State> {
        let key = ObjectIdentifier(State.self)
        if let store = mapExistSharedStore[key]?.value as? Store<State> {
            return store
        }
        // 一直向上会获取到 sceneStore，这里需要截断
        if State.self is SceneState.Type {
            if let theStore = sceneStore as? Store<State> {
                return theStore
            }
            fatalError("Get scene store failed")
        }
        let store = Store<State>.box(State(on: sceneId))
        // 判断 upStore 是否添加了当前的状态
        if !(State.UpState.self is Never.Type) {
            let upStore = self.getSharedStore(of: State.UpState.self)
            if let existState = upStore.subStates[store.state.stateId] {
                ViewMonitor.shared.fatalError(
                    "Attach State[\(String(describing: State.self))] to UpState[\(String(describing: State.UpState.self))] " +
                    "with stateId[\(store.state.stateId)] failed: " +
                    "exist State[\(String(describing: type(of: existState)))] with same stateId!")
            }
            upStore.add(subStore: store)
        }
        
        mapExistSharedStore[key] = store.eraseToAnyStore()
        return store
    }
}
