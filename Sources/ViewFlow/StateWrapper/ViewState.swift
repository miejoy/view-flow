//
//  ViewStore.swift
//
//
//  Created by 黄磊 on 2022/5/1.
//  Copyright © 2022 Miejoy. All rights reserved.
//  界面状态

import SwiftUI
import DataFlow

/// 可存储的界面状态
public protocol StorableViewState: AttachableState where UpState == SceneState {}
public protocol FullStorableViewState: StorableViewState, ReducerLoadableState, ActionBindable {}

@propertyWrapper
public struct ViewState<State: StorableViewState> : DynamicProperty {
    
    @ObservedObject private var store: Store<State>
    
    /// 环境变量窃取器
    struct EnvironmentStealer {
        @Environment(\.sceneStore) var sceneStore
        @Environment(\.viewPath) var viewPath
    }
    
    public init(wrappedValue value: State) {
        store = Store<State>.box(value)
        setupLifeCircly()
    }
    
    public init() where State: InitializableState {
        self.init(wrappedValue: State())
    }
    
    func setupLifeCircly() {
        let stealer = EnvironmentStealer()
        stealer.sceneStore.state.addViewState(state: store.state, on: stealer.viewPath)
        stealer.sceneStore.observe(store: store) { new, _ in
            stealer.sceneStore.state.updateViewState(state: new, on: stealer.viewPath)
        }
        store.setDestroyCallback { state in
            stealer.sceneStore.state.removeViewState(state: state, on: stealer.viewPath)
        }
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

extension ViewState where State: ReducerLoadableState {
    public init(wrappedValue value: State) {
        store = Store<State>.box(value)
        setupLifeCircly()
        State.loadReducers(on: store)
    }
}

extension ViewState where State: ReducerLoadableState & InitializableState {
    public init() {
        self.init(wrappedValue: State())
        State.loadReducers(on: store)
    }
}

extension SceneState {
    
    /// 当前场景所有 ViewState 的存储器
    @usableFromInline
    var viewStateContainer: ViewStateContainer {
        self.storage[ViewStateContainerKey.self]
    }
    
    /// 添加对应 ViewState，不触发 SceneState 变化通知
    @usableFromInline
    func addViewState<State:StorableViewState>(state: State, on viewPath: ViewPath) {
        viewStateContainer.addViewState(state: state, on: viewPath)
        ViewMonitor.shared.record(event: .addViewState(state: state, viewPath: viewPath, scene: self))
    }
    
    /// 更新对应 ViewState，不触发 SceneState 变化通知
    @usableFromInline
    func updateViewState<State:StorableViewState>(state: State, on viewPath: ViewPath) {
        viewStateContainer.updateViewState(state: state, on: viewPath)
        ViewMonitor.shared.record(event: .updateViewState(state: state, viewPath: viewPath, scene: self))
    }
    
    /// 删除对应 ViewState，不触发 SceneState 变化通知
    @usableFromInline
    func removeViewState<State:StorableViewState>(state: State, on viewPath: ViewPath) {
        viewStateContainer.removeViewState(state: state, on: viewPath)
        ViewMonitor.shared.record(event: .removeViewState(state: state, viewPath: viewPath, scene: self))
    }
}


struct ViewStateContainerKey: SceneStorageKey {
    static func defaultValue(on sceneStore: Store<SceneState>?) -> ViewStateContainer {
        return .init(sceneId: sceneStore?.sceneId ?? "")
    }
}

@usableFromInline
final class ViewStateContainer {
    struct ViewStateId: Hashable, CustomStringConvertible {
        let viewPath: ViewPath
        let stateId: String
        
        var description: String {
            viewPath.description + "->" + stateId
        }
    }
    let sceneId: String
    var mapViewState: [ViewStateId:StorableState] = [:]
    
    init(sceneId: String) {
        self.sceneId = sceneId
        self.mapViewState = [:]
    }
    
    @usableFromInline
    func addViewState<State:StorableViewState>(state: State, on viewPath: ViewPath) {
        let viewStateId = ViewStateId(viewPath: viewPath, stateId: state.stateId)
        if let state = mapViewState[viewStateId] {
            ViewMonitor.shared.fatalError("Add view state[\(state.stateId)] to scene[\(sceneId)] failed: exist same state")
            return
        }
        mapViewState[viewStateId] = state
    }
    
    @usableFromInline
    func updateViewState<State:StorableViewState>(state: State, on viewPath: ViewPath) {
        let viewStateId = ViewStateId(viewPath: viewPath, stateId: state.stateId)
        if mapViewState[viewStateId] == nil {
            ViewMonitor.shared.fatalError("Update view state[\(state.stateId)] on scene[\(sceneId)] failed: state not exist")
            return
        }
        mapViewState[viewStateId] = state
    }
    
    @usableFromInline
    func removeViewState<State:StorableViewState>(state: State, on viewPath: ViewPath) {
        let viewStateId = ViewStateId(viewPath: viewPath, stateId: state.stateId)
        guard mapViewState[viewStateId] != nil else {
            ViewMonitor.shared.fatalError("Remove view state[\(state.stateId)] on scene[\(sceneId)] failed: state not exist")
            return
        }
        mapViewState.removeValue(forKey: viewStateId)
    }
}
