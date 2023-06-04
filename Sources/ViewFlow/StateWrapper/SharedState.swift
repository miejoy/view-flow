//
//  SharedState.swift
//  
//
//  Created by 黄磊 on 2023/6/4.
//

import DataFlow
import SwiftUI

/// 共享状态包装器
@propertyWrapper
public struct SharedState<State: SharableState>: DynamicProperty {
    
    @ObservedObject private var store: Store<State>
    
    public init() {
        store = .shared
    }
    
    public var wrappedValue: State {
        get {
            store.state
        }
        
        nonmutating set {
            store.state = newValue
        }
    }
    
    public var projectedValue: Store<State> {
        store
    }
}
