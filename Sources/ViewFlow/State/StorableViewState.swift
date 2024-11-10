//
//  StorableViewState.swift
//  
//
//  Created by 黄磊 on 2023/6/10.
//  可存储的界面状态

import DataFlow

/// 可存储的界面状态
public protocol StorableViewState: AttachableState where UpState == SceneState {}
public protocol FullStorableViewState: StorableViewState, ReducerLoadableState, ActionBindable {}

extension Store where State: StorableViewState {
    /// 当前 ViewState 对应 Store 所在的场景ID
    public var sceneId: SceneId {
        self[SceneIdKey.self]
    }
}
