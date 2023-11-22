//
//  SceneState.swift
//
//
//  Created by 黄磊 on 2022/5/3.
//  Copyright © 2022 Miejoy. All rights reserved.
//  场景状态，包括当前场景的所有 SceneSharedState 和 ViewState 以及所有 SceneSharedState 对应的 Store

import Foundation
import DataFlow
import SwiftUI

public enum SceneId: CustomStringConvertible, Hashable {
    case main
    case custom(String)
    
    public var description: String {
        switch self {
        case .main:
            return "main"
        case .custom(let str):
            return str
        }
    }
}

/// 场景事件
public enum SceneAction: Action {
    case onAppear(any RoutableView, ViewPath)
    case onDisappear(any RoutableView, ViewPath)
}

/// 场景状态
public struct SceneState: StateContainable, SceneSharableState, ActionBindable {
    
    public typealias UpState = Never
    public typealias BindAction = SceneAction
    
    /// 当前场景 ID
    public let sceneId: SceneId
    /// 当前正在显示的所有 View 的 ViewPath，最后一个为最顶层的 View 对应的 ViewPath
    public var arrAppearViewPath: [ViewPath] = []
    
    public var subStates: [String : StorableState] = [:]
    
    /// 当前场景的数据存储器，其他模块可以使用这个存储器保持自己的数据
    public var storage: SceneStorage
    
    public init() {
        self.init(sceneId: .main)
    }
    
    public init(sceneId: SceneId) {
        self.sceneId = sceneId
        self.storage = SceneStorage()
    }
}

extension SceneState: ReducerLoadableState {
    
    public static func didBoxed(on store: Store<some StorableState>) {
        if let store = store as? Store<SceneState> {
            store.state.storage.sceneStore = store
            // 手动绑定上级 store
            let upStore = Store<AllSceneState>.shared
            let sceneIdStr = store.state.sceneId.description
            guard upStore.state.subStates[sceneIdStr] == nil else {
                ViewMonitor.shared.fatalError(
                    "Attach SceneState[\(sceneIdStr)] to AllSceneState failed: exist SceneState with same sceneId!"
                )
                return
            }
            upStore.state.subStates[sceneIdStr] = store.state
            store.setDestroyCallback { [weak upStore] state in
                upStore?.subStates.removeValue(forKey: sceneIdStr)
            }
            
            if Thread.isMainThread {
                upStore.observe(store: store) { [weak upStore] newState, _ in
                    upStore?.subStates[sceneIdStr] = newState
                }
                loadReducers(on: store)
            } else {
                DispatchQueue.main.async { [weak upStore, weak store] in
                    guard let upStore = upStore else { return }
                    guard let store = store else { return }
                    upStore.observe(store: store) { [weak upStore] newState, _ in
                        upStore?.subStates[sceneIdStr] = newState
                    }
                    loadReducers(on: store)
                }
            }
        }
    }
    
    public static func loadReducers(on store: Store<SceneState>) {        
        store.registerDefault { state, action in
            switch action {
            case .onAppear(let view, let viewPath):
                // 找的当前 view 的 父 view
                let index = state.arrAppearViewPath.firstIndex { item in
                    !(item.isSubPath(of: viewPath))
                } ?? 0
                state.arrAppearViewPath.insert(viewPath, at: index)
                ViewMonitor.shared.record(event: .viewDidAppear(view: view, viewPath: viewPath, scene: state))
            case .onDisappear(let view, let viewPath):
                if let index = state.arrAppearViewPath.firstIndex(where: { $0 == viewPath }) {
                    state.arrAppearViewPath.remove(at: index)
                }
                ViewMonitor.shared.record(event: .viewDidDisappear(view: view, viewPath: viewPath, scene: state))
            }
        }
    }
}

/// 让 Never 可以作为 SceneState 的上级，而 SceneState 真实上级是 AllSceneState
extension Never : SceneSharableState {
    public init(sceneId: SceneId) { self.init() }
}

/// 场景容器，各子功能可用它存在数据
public final class SceneStorage {
    /// 当前场景的存储器
    weak var sceneStore: Store<SceneState>? = nil
    var storage: [ObjectIdentifier: Any] = [:]
    
    public subscript<Key: SceneStorageKey>(_ keyType: Key.Type) -> Key.Value {
        get {
            DispatchQueue.syncOnStoreQueue {
                let key = ObjectIdentifier(Key.self)
                if let value = storage[key] as? Key.Value {
                    return value
                }
                let value = Key.defaultValue(on: sceneStore)
                storage[key] = value
                return value
            }
        }
    }
}

public protocol SceneStorageKey {
    associatedtype Value
    static func defaultValue(on sceneStore: Store<SceneState>?) -> Value
}
