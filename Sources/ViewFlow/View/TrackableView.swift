//
//  TrackableView.swift
//
//
//  Created by 黄磊 on 2022/5/2.
//  Copyright © 2022 Miejoy. All rights reserved.
//  可追踪的 View

import SwiftUI
import DataFlow

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
    
    @Environment(\.viewPath) var viewPath
    var trackId: String
    
    @ViewBuilder var content: Content

    var body: some View {
        return self.content
            .environment(\.viewPath, viewPath.appendPath(trackId))
    }    
}
