//
//  AllSceneState.swift
//
//
//  Created by 黄磊 on 2022/5/3.
//  Copyright © 2022 Miejoy. All rights reserved.
//  所有场景状态，主要作为 SceneState 和 AppState 关联的桥梁

import Foundation
import DataFlow

///  所有场景状态
struct AllSceneState: StateContainable, SharableState {
    
    typealias UpState = AppState
    
    var subStates: [String : StorableState] = [:]
}
