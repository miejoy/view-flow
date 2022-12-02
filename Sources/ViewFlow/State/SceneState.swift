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
    
    public init(_ rawValue: String) {
        if rawValue == "main" {
            self = .main
        } else {
            self = .custom(rawValue)
        }
    }
    
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
    case onAppear(ViewPath)
    case onDisappear(ViewPath)
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
    
    var storage: SceneStorage
    
    public init() {
        self.init(.main)
    }
    
    public init(_ sceneId: SceneId) {
        self.sceneId = sceneId
        self.storage = SceneStorage()
    }
}

extension SceneState: ReducerLoadableState {
    public static func loadReducers(on store: Store<SceneState>) {
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
        upStore.observe(store: store) { newState, _ in
            Store<AllSceneState>.shared.subStates[sceneIdStr] = newState
        }
        store.setDestroyCallback { state in
            Store<AllSceneState>.shared.subStates.removeValue(forKey: sceneIdStr)
        }
        
        store.registerDefault { state, action in
            switch action {
            case .onAppear(let viewPath):
                // 找的当前 view 的 父 view
                let index = state.arrAppearViewPath.firstIndex { item in
                    !(item.isSubPath(of: viewPath))
                } ?? 0
                state.arrAppearViewPath.insert(viewPath, at: index)
                ViewMonitor.shared.record(event: .viewDidAppear(viewPath: viewPath, scene: state))
            case .onDisappear(let viewPath):
                if let index = state.arrAppearViewPath.firstIndex(where: { $0 == viewPath }) {
                    state.arrAppearViewPath.remove(at: index)
                }
                ViewMonitor.shared.record(event: .viewDidDisappear(viewPath: viewPath, scene: state))
            }
        }
    }
}

/// 让 Never 可以作为 SceneState 的上级，而 SceneState 真实上级是 AllSceneState
extension Never : SceneSharableState {}

/// 场景容器，各子功能可用它存在数据
final class SceneStorage {
    
    weak var sceneStore: Store<SceneState>? = nil
    var storage: [ObjectIdentifier: Any] = [:]
    
    public subscript<Key: SceneStorageKey>(_ keyType: Key.Type) -> Key.Value {
        get {
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

public protocol SceneStorageKey {
    associatedtype Value
    static func defaultValue(on sceneStore: Store<SceneState>?) -> Value
}
