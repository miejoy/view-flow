//
//  ViewStore.swift
//
//
//  Created by 黄磊 on 2022/5/1.
//  Copyright © 2022 Miejoy. All rights reserved.
//  界面状态

import SwiftUI
import DataFlow
import Combine


@propertyWrapper
public struct ViewState<State: StorableViewState> : DynamicProperty {

    @StateObject
    var storage: ViewStateWrapperStorage<State>
    
    @Environment(\.sceneId)
    var sceneId
    @Environment(\.viewPath)
    var viewPath
    @Environment(\.recordViewState)
    var recordViewState
    
    public init(wrappedValue value: State) {
        self._storage = .init(wrappedValue: .init(state: value))
    }
    
    public var wrappedValue: State {
        get {
            storage.store.state
        }
        
        nonmutating set {
            storage.store.state = newValue
        }
    }
    
    public var projectedValue: Store<State> {
        storage.store
    }
    
    public func update() {
        if !storage.isReady {
            storage.configIfNeed(sceneId, viewPath, recordViewState)
        }
    }
}

// MARK: - ViewStateWrapperStorage

/// 界面状态包装器对应存储器，暂时只在内部使用
final class ViewStateWrapperStorage<State: StorableViewState>: ObservableObject {
    
    @Published
    var refreshTrigger: Bool = false

    var store: Store<State>
    var isReady: Bool = false
    
    var cancellable: AnyCancellable? = nil
    
    init(state: State) {
        self.store = .box(state)
    }
    
    func configIfNeed(_ sceneId: SceneId, _ viewPath: ViewPath, _ recordViewState: Bool) {
        if !isReady {
            self.cancellable = store.addObserver { [weak self] new, old in
                self?.refreshTrigger.toggle()
            }
            if recordViewState {
                setupLifeCycle(sceneId, viewPath)
            }
            isReady = true
        }
    }
    
    // 记录 ViewState 的话想，需要设置生命周期中的各种过程
    func setupLifeCycle(_ sceneId: SceneId, _ viewPath: ViewPath) {
        let sceneStore = Store<AllSceneState>.shared.sceneStore(of: sceneId)
        sceneStore.state.addViewState(state: store.state, on: viewPath)
        sceneStore.observe(store: store) { [weak sceneStore] new, _ in
            sceneStore?.state.updateViewState(state: new, on: viewPath)
        }
        
        store.setDestroyCallback { [weak sceneStore] state in
            sceneStore?.state.removeViewState(state: state, on: viewPath)
        }
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
        return .init(sceneId: sceneStore?.sceneId ?? .main)
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
    let sceneId: SceneId
    var mapViewState: [ViewStateId:StorableState] = [:]
    
    init(sceneId: SceneId) {
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
