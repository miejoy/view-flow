//
//  RoutableView.swift
//  
//
//  Created by 黄磊 on 2023/3/5.
//  Copyright © 2023 Miejoy. All rights reserved.
//  可路由界面

import SwiftUI
import DataFlow

/// 可路由的界面
public protocol RoutableView: TrackableView, InitializableView {
}

public protocol VoidRoutableView: RoutableView, VoidInitializableView {
}

extension RoutableView {
    public var body: some View {
        RouteWrapperView(trackId: trackId) {
            self.content
        }
    }
    
    @inlinable
    public static var defaultRoute: ViewRoute<InitData> { .init(routeId: String(describing: Self.self)) }
}

struct RouteWrapperView<Content: View> : View {
    
    @Environment(\.viewPath) var viewPath
    @Environment(\.sceneId) var sceneId
    var trackId: String
    
    @ViewBuilder var content: Content

    var body: some View {
        return self.content
            .environment(\.viewPath, viewPath.appendPath(trackId))
            .onDisappear {
                Store<SceneState>.shared(on: sceneId).send(action: .onDisappear(viewPath.appendPath(trackId)))
            }
            .onAppear {
                Store<SceneState>.shared(on: sceneId).send(action: .onAppear(viewPath.appendPath(trackId)))
            }
    }
}

