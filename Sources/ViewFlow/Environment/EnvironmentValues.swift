//
//  EnvironmentValues.swift
//  
//
//  Created by 黄磊 on 2022/11/27.
//

import SwiftUI

extension EnvironmentValues {
    /// 场景 ID
    public var sceneId: SceneId {
        get { self[SceneIdKey.self] }
        set { self[SceneIdKey.self] = newValue }
    }
    
    /// 是否记录界面状态，默认 false
    public var recordViewState: Bool {
        get { self[RecordViewStateKey.self] }
        set { self[RecordViewStateKey.self] = newValue }
    }
    
    /// 当前 View 所在的 界面追踪路径
    public var viewPath: ViewPath {
        get { self[ViewPathKey.self] }
        set { self[ViewPathKey.self] = newValue }
    }
}

/// 场景 ID 对应 Key
struct SceneIdKey: EnvironmentKey {
    static var defaultValue: SceneId =  .main
}

/// 是否记录界面状态对应 Key
struct RecordViewStateKey: EnvironmentKey {
    static var defaultValue: Bool = false
}

/// 获取当前 View 所在 界面追踪路径 的环境 Key
struct ViewPathKey: EnvironmentKey {
    static var defaultValue: ViewPath = ViewPath()
}
