//
//  AllSceneState.swift
//
//
//  Created by 黄磊 on 2022/5/3.
//  Copyright © 2022 Miejoy. All rights reserved.
//  所有场景状态，主要作为 SceneState 和 AppState 关联的桥梁

import Foundation
import DataFlow

enum AllSceneAction: Action {
    // 添加 SceneStore 一般是一个自动的过程，这里先去掉了
    // case addSceneStore(_ sceneId: SceneId, _ sceneStore:Store<SceneState>)
    case removeSceneStore(_ sceneId: SceneId)
}

///  所有场景状态
struct AllSceneState: FullSharableState {
    typealias BindAction = AllSceneAction
    
    var allSceneStorage: AllSceneStorage = .init()
    var subStates: [String : StorableState] = [:]
    
    static func loadReducers(on store: Store<AllSceneState>) {
        store.registerDefault { state, action in
            switch action {
            // case let .addSceneStore(sceneId, sceneStore):
            //     state.allSceneStorage[sceneId] = sceneStore
            case let .removeSceneStore(sceneId):
                state.allSceneStorage.removeSceneStore(of: sceneId)
            }
        }
    }
}

final class AllSceneStorage {
    var sceneIdToStoreMap: [SceneId: Store<SceneState>] = [:]
    
    func sceneStore(of sceneId: SceneId) -> Store<SceneState> {
        return DispatchQueue.syncOnStoreQueue {
            if let store = sceneIdToStoreMap[sceneId] {
                return store
            }
            
            let state = SceneState(sceneId: sceneId)
            let store = Store<SceneState>.box(state)
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
    func sceneStore(of sceneId: SceneId = .main) -> Store<SceneState> {
        state.allSceneStorage.sceneStore(of: sceneId)
    }
}
