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
