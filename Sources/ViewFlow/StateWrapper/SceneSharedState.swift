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
}

/// 完整的 scene 下可共享状态
public protocol FullSceneSharableState: SceneSharableState, ReducerLoadableState, ActionBindable {}


@propertyWrapper
public struct SceneSharedState<State: SceneSharableState> : DynamicProperty {
    
    @ObservedObject private var store: Store<State>

    static func getSceneStore() -> Store<SceneState> {
        Store<SceneState>.curSceneStore
    }
    
    public init() {
        store = Store<SceneState>.curSceneStore.state.getSharedStore(of: State.self)
    }
    
    public var wrappedValue: State {
        get {
            store.state
        }
        
        nonmutating set {
            store.state = newValue
        }
    }
    
    public var projectedValue: Store<State> {
        store
    }
}

extension SceneSharedState where State : ReducerLoadableState {
    public init() {
        store = Self.getSceneStore().state.getSharedStore(of: State.self)
        if !(State.self is SceneState.Type) {
            // 这里有可能获取 SceneStore ，需要屏蔽一下
            State.loadReducers(on: store)
        }
    }
}

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
        let store = Store<State>()
        // 判断 upStore 是否添加了当前的状态
        if !(State.UpState.self is Never.Type) {
            let upStore = self.getSharedStore(of: State.UpState.self)
            if let existState = upStore.subStates[store.state.stateId] {
                ViewMonitor.shared.fatalError(
                    "Attach State[\(String(describing: State.self))] to UpState[\(String(describing: State.UpState.self))] " +
                    "with stateId[\(store.state.stateId)] failed: " +
                    "exist State[\(String(describing: type(of: existState)))] with same stateId!")
            }
            upStore.append(subStore: store)
        }
        
        mapExistSharedStore[key] = store.eraseToAnyStore()
        return store
    }
}
