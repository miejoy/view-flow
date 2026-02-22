//
//  AllSceneState.swift
//
//
//  Created by 黄磊 on 2022/5/3.
//  Copyright © 2022 Miejoy. All rights reserved.
//  所有场景状态，主要作为 SceneState 和 AppState 关联的桥梁

import Foundation
import DataFlow

enum AllSceneAction: Action, Sendable {
    // 添加 SceneStore 一般是一个自动的过程，这里先去掉了
    // case addSceneStore(_ sceneId: SceneId, _ sceneStore:Store<SceneState>)
    // 移除 SceneStore 可以直接通过 Store 提供方法移除
    // case removeSceneStore(_ sceneId: SceneId)
}

///  所有场景状态
struct AllSceneState: FullSharableState {
    typealias BindAction = AllSceneAction
    
    var subStates: [String : StorableState] = [:]
    
    @MainActor static func loadReducers(on store: Store<AllSceneState>) {        
    }
}

// MARK: - Storage

extension DefaultStoreStorageKey where Value == AllSceneStorage {
    static let allSceneStorage: Self = .init("allSceneStorage", AllSceneStorage())
}

final class AllSceneStorage: @unchecked Sendable {
    var sceneIdToStoreMap: [SceneId: Store<SceneState>] = [:]
    
    func sceneStore(of sceneId: SceneId) -> Store<SceneState> {
        return DispatchQueue.syncOnStoreQueue {
            if let store = sceneIdToStoreMap[sceneId] {
                return store
            }
            
            let state = SceneState(sceneId: sceneId)
            let store = Store<SceneState>.innerBox(state, configs: [.make(.inAllSceneStorage, true)])
            sceneIdToStoreMap[sceneId] = store
            return store
        }
    }
    
    func removeSceneStore(of sceneId: SceneId) {
        _ = DispatchQueue.syncOnStoreQueue {
            sceneIdToStoreMap.removeValue(forKey: sceneId)
        }
    }
}

extension Store where State == AllSceneState {
    nonisolated func sceneStore(of sceneId: SceneId = .main) -> Store<SceneState> {
        self[.allSceneStorage].sceneStore(of: sceneId)
    }
}

extension StoreConfigKey where Value == Bool {
    static let inAllSceneStorage: StoreConfigKey<Bool> = .init("InAllSceneStorage")
}
