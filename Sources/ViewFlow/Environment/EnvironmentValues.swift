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
}

/// 场景 ID 对应 Key
struct SceneIdKey: EnvironmentKey {
    static var defaultValue: SceneId =  .main
}
