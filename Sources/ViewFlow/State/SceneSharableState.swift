//
//  SceneSharableState.swift
//
//
//  Created by 黄磊 on 2023/6/10.
//  对当前场景内的可共享状态

import SwiftUI
import DataFlow

/// 同 scene 下可共享的状态
public protocol SceneSharableState: SharableState where UpState: SceneSharableState {
    associatedtype UpState = SceneState
    
    init(sceneId: SceneId)
}

/// 可以用空参数初始化的 scene 下可共享状态
public protocol VoidSceneSharableState: SceneSharableState {}

/// 用 sceneId 初始化的 scene 下可共享状态
public protocol SceneWithIdSharableState: SceneSharableState {}

/// 完整的 scene 下可共享状态
public protocol FullSceneSharableState: VoidSceneSharableState, ReducerLoadableState, ActionBindable {}

/// 完整用 sceneId 初始化的 scene 下可共享状态
public protocol FullSceneWithIdSharableState: SceneWithIdSharableState, ReducerLoadableState, ActionBindable {}


extension VoidSceneSharableState {
    /// 使用场景 ID 初始化，默认调用无参数初始化方法
    public init(sceneId: SceneId) {
        self.init()
    }
}

extension SceneWithIdSharableState {
    /// 无参数初始化方法默认用 SceneId.main 初始化，尽量不要调用到这里
    public init() {
        ViewMonitor.shared.record(event: .callSceneSharedStateInitWithoutSceneId(Self.self))
        self.init(sceneId: .main)
    }
}
