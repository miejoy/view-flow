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
    
    /// 动态嫁接可比较的 State 属性为可绑定的属性
    @inlinable
    public subscript<Subject: Equatable>(dynamicMember keyPath: WritableKeyPath<State, Subject>) -> Binding<Subject> {
        self.binding(of: keyPath)
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
    /// 共享状态存储器，读取主场景的（线程安全的，可直接使用）
    public static var shared: Store<State> {
        Store<AllSceneState>.shared.sceneStore().state.getSharedStore(of: State.self)
    }
    
    /// 对应场景共享状态存储区（线程安全的，可直接使用）
    public static func shared(on sceneId: SceneId) -> Store<State> {
        return Store<AllSceneState>.shared.sceneStore(of: sceneId).state.getSharedStore(of: State.self)
    }
}

extension Store where State == SceneState {
    public static func shared(on sceneId: SceneId) -> Store<State> {
        Store<AllSceneState>.shared.sceneStore(of: sceneId)
    }
}

extension SceneSharableState {
    /// 共享状态存储器，读取主场景的（线程安全的，可直接使用）
    public static var sharedStore: Store<Self> {
        Store<AllSceneState>.shared.sceneStore().state.getSharedStore(of: Self.self)
    }
    
    /// 对应场景共享状态存储区（线程安全的，可直接使用）
    public static func sharedStore(on sceneId: SceneId) -> Store<Self> {
        Store<AllSceneState>.shared.sceneStore(of: sceneId).state.getSharedStore(of: Self.self)
    }
}
