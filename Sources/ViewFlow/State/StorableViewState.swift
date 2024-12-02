//
//  StorableViewState.swift
//  
//
//  Created by 黄磊 on 2023/6/10.
//  可存储的界面状态

import DataFlow
import Foundation

/// 可存储的界面状态
public protocol StorableViewState: AttachableState where UpState == SceneState {
    /// 对应 Store 被加载到 View 时调用，尽量不要重写他，如果确实要重写，请注意 ReducerLoadableState 相关方法的调用
    static func didAddStoreToView(_ store: Store<some StorableViewState>)
}
public protocol FullStorableViewState: StorableViewState, ReducerLoadableState, ActionBindable {}


extension StorableViewState {
    /// 添加空的默认实现
    public static func didAddStoreToView(_ store: Store<some StorableViewState>) {
    }
}

extension Store where State: StorableViewState {    
    /// 当前 ViewState 对应 Store 所在的场景ID
    public var sceneId: SceneId {
        self[SceneIdKey.self]
    }
    
    /// 当前 ViewState 对应 Store 所在的界面追踪路径
    public var viewPath: ViewPath {
        self[ViewPathKey.self]
    }
}

extension ReducerLoadableState where Self: StorableViewState {
    public static func didBoxed(on store: Store<some StorableState>) {
        // 这里不做任何事情，主要是为了屏蔽自动调用加载处理器
        // 只有对应 store 被加载到 view 上才需要加载处理器
        // 被 ViewState 包装的 StorableViewState 如果继承了 ReducerLoadableState，
        // 在 Store 被加载到 view 上时，会通过 didAddStoreToView 自动调用加载处理器
    }
    
    public static func didAddStoreToView(_ store: Store<some StorableViewState>) {
        if let store = store as? Store<Self> {
            loadReducers(on: store)
        }
    }
}
