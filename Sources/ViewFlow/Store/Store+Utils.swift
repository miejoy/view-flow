//
//  Store+Utils.swift
//  
//
//  Created by 黄磊 on 2022/6/7.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import DataFlow
import SwiftUI

extension Store {
    
    // MARK: - Binding
    
    /// 生成对应值的绑定类型
    ///
    /// - Parameter keyPath: 对应值的 keyPath
    /// - Returns: 返回对应值的绑定类型
    public func binding<T: Equatable>(of keyPath: WritableKeyPath<State, T>) -> Binding<T> {
        Binding<T>.init(get: { () -> T in
            self.state[keyPath: keyPath]
        }) { (value, transaction) in
            if self.state[keyPath: keyPath] == value {
                // 相同值时不更新
                return
            }
            // 这里设置会自动调用监听者
            self[dynamicMember: keyPath] = value
        }
    }
    
    /// 生成对应值的绑定类型
    ///
    /// - Parameter keyPath: 对应值的 keyPath
    /// - Parameter transformSetToAction: 将 set 方法转化为 action 的闭包
    /// - Returns: 返回对应值的绑定类型
    public func binding<T: Equatable, A: Action>(
        of keyPath: KeyPath<State, T>,
        _ transformSetToAction: @escaping (_ newValue: T) -> A
    ) -> Binding<T> {
        Binding<T>.init(get: { () -> T in
            self.state[keyPath: keyPath]
        }) { (value, transaction) in
            if self.state[keyPath: keyPath] == value {
                // 相同值时不更新
                return
            }
            self.send(action: transformSetToAction(value))
        }
    }
    
    /// 生成对应值的绑定类型
    ///
    /// - Parameter keyPath: 对应值的 keyPath
    /// - Parameter transformSetToAction: 将 set 方法转化为 action 的闭包
    /// - Returns: 返回对应值的绑定类型
    public func binding<T: Equatable, A: Action>(
        of keyPath: KeyPath<State, T>,
        _ transformSetToAction: @escaping (_ newValue: T, _ transaction: Transaction) -> A
    ) -> Binding<T> {
        Binding<T>.init(get: { () -> T in
            self.state[keyPath: keyPath]
        }) { (value, transaction) in
            if self.state[keyPath: keyPath] == value {
                // 相同值时不更新
                return
            }
            self.send(action: transformSetToAction(value, transaction))
        }
    }
}

extension Store where State: ActionBindable {
    
    /// 生成对应值的绑定类型
    ///
    /// - Parameter keyPath: 对应值的 keyPath
    /// - Parameter transformSetToAction: 将 set 方法转化为 action 的闭包
    /// - Returns: 返回对应值的绑定类型
    public func bindingDefault<T: Equatable>(
        of keyPath: KeyPath<State, T>,
        _ transformSetToAction: @escaping (_ newValue: T) -> State.BindAction
    ) -> Binding<T> {
        Binding<T>.init(get: { () -> T in
            self.state[keyPath: keyPath]
        }) { (value, transaction) in
            if self.state[keyPath: keyPath] == value {
                // 相同值时不更新
                return
            }
            self.send(action: transformSetToAction(value))
        }
    }
    
    /// 生成对应值的绑定类型
    ///
    /// - Parameter keyPath: 对应值的 keyPath
    /// - Parameter transformSetToAction: 将 set 方法转化为 action 的闭包
    /// - Returns: 返回对应值的绑定类型
    public func bindingDefault<T: Equatable>(
        of keyPath: KeyPath<State, T>,
        _ transformSetToAction: @escaping (_ newValue: T, _ transaction: Transaction) -> State.BindAction
    ) -> Binding<T> {
        Binding<T>.init(get: { () -> T in
            self.state[keyPath: keyPath]
        }) { (value, transaction) in
            if self.state[keyPath: keyPath] == value {
                // 相同值时不更新
                return
            }
            self.send(action: transformSetToAction(value, transaction))
        }
    }
}

extension Store where State: SceneSharableState {
    // 默认读取 主场景
    public static var shared: Store<State> {
        Store<AllSceneState>.shared.sceneStore().state.getSharedStore(of: State.self)
    }
}

extension Store where State: SceneSharableState & ReducerLoadableState {
    // 默认读取 主场景
    public static var shared: Store<State> {
        let store = Store<AllSceneState>.shared.sceneStore().state.getSharedStore(of: State.self)
        State.loadReducers(on: store)
        return store
    }
}

extension Store where State == SceneState {
    /// 环境变量窃取器
    @usableFromInline
    struct EnvironmentStealer {
        @usableFromInline
        @Environment(\.sceneId) var sceneId
    }
    
    public static var curSceneStore: Store<State> {
        Store<AllSceneState>.shared.sceneStore(of: EnvironmentStealer().sceneId)
    }
}
