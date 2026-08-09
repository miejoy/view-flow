//
//  Store+Utils.swift
//  
//
//  Created by 黄磊 on 2022/6/7.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import DataFlow
import SwiftUI

// MARK: - 安全更新标记

extension DefaultStoreStorageKey where Value == Bool {
    /// 标记当前 Store 是否处于安全更新中（state 立即更新，但 observer 通知异步触发）
    static let safeUpdating: Self = .init("SafeUpdating", false)
}

extension Store {

    /// 当前是否处于安全更新中。
    /// 通过 `safeUpdating` 设置，observer 据此决定是否异步触发 refreshTrigger。
    public var isSafeUpdating: Bool {
        self[.safeUpdating]
    }

    /// 安全更新：在 block 内更新 state，标记期间 observer 会异步触发 refreshTrigger，
    /// 避免在 SwiftUI 渲染周期内同步修改 @Published 导致崩溃。
    public func safeUpdating(_ block: () -> Void) {
        self[.safeUpdating] = true
        defer { self[.safeUpdating] = false }
        block()
    }
}

// MARK: - Binding

extension Store {
    
    /// 生成对应值的绑定类型
    ///
    /// - Parameter keyPath: 对应值的 keyPath
    /// - Returns: 返回对应值的绑定类型
    public func binding<T: Equatable>(of keyPath: WritableKeyPath<State, T>) -> Binding<T> {
        Binding<T>.init {
            self.state[keyPath: keyPath]
        } set: { (value, transaction) in
            if self.state[keyPath: keyPath] == value {
                // 相同值时不更新
                return
            }
            // 通过 safeUpdating 更新：state 立即生效，但 refreshTrigger 异步触发
            self.safeUpdating {
                self[dynamicMember: keyPath] = value
            }
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
        Binding<T>.init {
            self.state[keyPath: keyPath]
        } set: { (value, transaction) in
            if self.state[keyPath: keyPath] == value {
                // 相同值时不更新
                return
            }
            self.safeUpdating {
                self.send(action: transformSetToAction(value))
            }
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
        Binding<T>.init {
            self.state[keyPath: keyPath]
        } set: { (value, transaction) in
            if self.state[keyPath: keyPath] == value {
                // 相同值时不更新
                return
            }
            self.safeUpdating {
                self.send(action: transformSetToAction(value, transaction))
            }
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
            self.safeUpdating {
                self.send(action: transformSetToAction(value))
            }
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
            self.safeUpdating {
                self.send(action: transformSetToAction(value, transaction))
            }
        }
    }
}

extension Store where State: SceneSharableState {
    /// 内部使用包装器
    nonisolated static func innerBox(_ state: State = State(), configs: [StoreConfigPair] = []) -> Self {
        var newConfigs = configs
        newConfigs.append(.make(.useBoxOnShared, true))
        return box(state, configs: newConfigs)
    }
    
    /// 共享状态存储器，读取主场景的（线程安全的，可直接使用）
    public nonisolated static var shared: Store<State> {
        Store<AllSceneState>.shared.sceneStore().getSharedStore(of: State.self)
    }
    
    /// 对应场景共享状态存储区（线程安全的，可直接使用）
    public nonisolated static func shared(on sceneId: SceneId) -> Store<State> {
        return Store<AllSceneState>.shared.sceneStore(of: sceneId).getSharedStore(of: State.self)
    }
}

extension Store where State == SceneState {
    public nonisolated static func shared(on sceneId: SceneId) -> Store<State> {
        Store<AllSceneState>.shared.sceneStore(of: sceneId)
    }
}

extension SceneSharableState {
    /// 共享状态存储器，读取主场景的（线程安全的，可直接使用）
    public static var sharedStore: Store<Self> {
        Store<AllSceneState>.shared.sceneStore().getSharedStore(of: Self.self)
    }
    
    /// 对应场景共享状态存储区（线程安全的，可直接使用）
    public static func sharedStore(on sceneId: SceneId) -> Store<Self> {
        Store<AllSceneState>.shared.sceneStore(of: sceneId).getSharedStore(of: Self.self)
    }
}
