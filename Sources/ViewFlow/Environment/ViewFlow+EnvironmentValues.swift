//
//  ViewFlow+EnvironmentValues.swift
//  
//
//  Created by 黄磊 on 2022/11/27.
//

import SwiftUI
import DataFlow

extension EnvironmentValues {
    /// 场景 ID
    public var sceneId: SceneId {
        get { self[SceneIdKey.self] }
        set { self[SceneIdKey.self] = newValue }
    }
        
    /// 当前 View 所在的 界面追踪路径
    public var viewPath: ViewPath {
        get { self[ViewPathKey.self] }
        set { self[ViewPathKey.self] = newValue }
    }
    
    /// 是否记录界面状态，默认 false
    public var recordViewState: Bool {
        get { self[RecordViewStateKey.self] }
        set { self[RecordViewStateKey.self] = newValue }
    }
    
    /// 建议的导航标题
    public var suggestNavTitle: String? {
        get { self[SuggestNavTitleKey.self] }
        set { self[SuggestNavTitleKey.self] = newValue }
    }
}

/// 场景 ID 对应 Key，可在 StorableViewState 对应 Store 中使用
struct SceneIdKey: EnvironmentKey {
    static let defaultValue: SceneId = .main
}

/// 获取当前 View 所在 界面追踪路径 的环境 Key，可在 StorableViewState 对应 Store 中使用
struct ViewPathKey: EnvironmentKey {
    static let defaultValue: ViewPath = ViewPath()
}

/// 是否记录界面状态对应 Key
struct RecordViewStateKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

/// 获取当前建议导航标题的 Key
struct SuggestNavTitleKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

// MARK: - StoreStorageKey

extension DefaultStoreStorageKey where Value == SceneId {
    /// 场景 ID 对应 Key，可在 StorableViewState 对应 Store 中使用
    static let sceneId: Self = .init("sceneId", .main)
}

extension DefaultStoreStorageKey where Value == ViewPath {
    /// 获取当前 View 所在 界面追踪路径 的环境 Key，可在 StorableViewState 对应 Store 中使用
    static let viewPath: Self = .init("viewPath", ViewPath())
}
