//
//  TrackableView.swift
//
//
//  Created by 黄磊 on 2022/5/2.
//  Copyright © 2022 Miejoy. All rights reserved.
//  可追踪的 View

import SwiftUI

/// 可追踪的 View
public protocol TrackableView: View {
    
    associatedtype Content : View

    /// 内部保护的 View
    @ViewBuilder var content: Self.Content { get }
    /// 当前 View 的追踪标识，默认为 当前类名
    var trackId: String { get }
}

extension TrackableView {
    
    public var trackId: String {
        String(describing: Self.self)
    }
    
    public var body: some View {
        TrackWrapperView(trackId: trackId) {
            self.content
        }
    }
}

struct TrackWrapperView<Content: View> : View {
    
    /// 环境变量窃取器
    @usableFromInline
    struct EnvironmentStealer {
        @usableFromInline
        @Environment(\.sceneStore) var sceneStore
    }
    
    @Environment(\.viewPath) var viewPath
    var trackId: String
    
    @ViewBuilder var content: Content

    var body: some View {
        return self.content
            .environment(\.viewPath, viewPath.appendPath(trackId))
            .onDisappear {
                EnvironmentStealer().sceneStore.send(action: .onDisappear(viewPath.appendPath(trackId)))
            }
            .onAppear {
                EnvironmentStealer().sceneStore.send(action: .onAppear(viewPath.appendPath(trackId)))
            }
    }
}

extension EnvironmentValues {
    /// 当前 View 所在的 界面追踪路径
    var viewPath: ViewPath {
        get { self[ViewPathKey.self] }
        set { self[ViewPathKey.self] = newValue }
    }
}

/// 获取当前 View 所在 界面追踪路径 的环境 Key
struct ViewPathKey: EnvironmentKey {
    public static var defaultValue: ViewPath = ViewPath()
}

/// 界面追踪路径
public struct ViewPath: Hashable, CustomStringConvertible {
    
    public var arrPaths: [String] = []
    
    init() {}
    
    init(arrPaths: [String], _ path: String) {
        self.arrPaths = arrPaths
        self.arrPaths.append(path)
    }
    
    public func appendPath(_ path: String) -> ViewPath {
        ViewPath(arrPaths: arrPaths, path)
    }
    
    public var description: String {
        arrPaths.joined(separator: "->")
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.arrPaths == rhs.arrPaths
    }
    
    public func isSubPath(of viewPath: ViewPath) -> Bool {
        if arrPaths.count < viewPath.arrPaths.count {
            return false
        }
        
        return arrPaths.prefix(viewPath.arrPaths.count) == viewPath.arrPaths.prefix(viewPath.arrPaths.count)
    }
}
