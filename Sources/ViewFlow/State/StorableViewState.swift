//
//  StorableViewState.swift
//  
//
//  Created by 黄磊 on 2023/6/10.
//  可存储的界面状态

import DataFlow
import Foundation

/// 可存储的界面状态，
/// 注意：尽量在 ViewState 包装器中使用，如果不是，将无法获取可靠的 sceneId 和 viewPath
public protocol StorableViewState: AttachableState where UpState == SceneState {
    /// 对应 Store 被加载到 View 时调用，尽量不要重写他，如果确实要重写，请注意 ReducerLoadableState 相关方法的调用
    @MainActor static func didAddStoreToView(_ store: Store<some StorableViewState>)
}
public protocol FullStorableViewState: StorableViewState, ReducerLoadableState, ActionBindable {}


extension StorableViewState {
    /// 添加空的默认实现
    @MainActor public static func didAddStoreToView(_ store: Store<some StorableViewState>) {
    }
}

extension Store where State: StorableViewState {    
    /// 当前 ViewState 对应 Store 所在的场景ID
    public var sceneId: SceneId {
        self[.sceneId]
    }
    
    /// 当前 ViewState 对应 Store 所在的界面追踪路径
    public var viewPath: ViewPath {
        self[.viewPath]
    }
}

extension ReducerLoadableState where Self: StorableViewState {
    public static func didBoxed(on store: Store<some StorableState>, state: some StorableState) {
        guard let store = store as? Store<Self> else { return }
        DispatchQueue.executeOnMain {
            if !store[.useViewStateWrapper, default: false] {
                // 如果没有使用 ViewState 包装，则需要立即加载 处理器，因为 didAddStoreToView 将不会被自动调用
                loadReducers(on: store)
            }
        }
    }
    
    @MainActor public static func didAddStoreToView(_ store: Store<some StorableViewState>) {
        guard let store = store as? Store<Self> else { return }
        if store[.useViewStateWrapper, default: false] {
            // 只有使用 ViewState 包装的存储器材需要在这里自动加载 处理器
            loadReducers(on: store)
        }
    }
}

extension StoreConfigKey where Value == Bool {
    /// 是否使用 ViewState 包装，仅内部使用
    static let useViewStateWrapper: StoreConfigKey<Bool> = .init("UseViewStateWrapper")
}
