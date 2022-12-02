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
    case addSceneStore(_ sceneId: SceneId, _ sceneStore:Store<SceneState>)
}

///  所有场景状态
struct AllSceneState: FullSharableState {
    typealias BindAction = AllSceneAction
    
    var allSceneStorage: [SceneId: Store<SceneState>] = [:]
    var subStates: [String : StorableState] = [:]
    
    static func loadReducers(on store: Store<AllSceneState>) {
        store.registerDefault { state, action in
            switch action {
            case let .addSceneStore( sceneId, sceneStore):
                state.allSceneStorage[sceneId] = sceneStore
            }
        }
    }
}

extension Store where State == AllSceneState {
    func sceneStore(of sceneId: SceneId = .main) -> Store<SceneState> {
        if let store = state.allSceneStorage[sceneId] {
            return store
        }
        let state = SceneState(sceneId)
        let store = Store<SceneState>.box(state)
        self.apply(action: .addSceneStore(sceneId, store))
        return store
    }
}
