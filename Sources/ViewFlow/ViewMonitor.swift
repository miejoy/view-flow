//
//  ViewMonitor.swift
//  
//
//  Created by 黄磊 on 2022/6/3.
//  Copyright © 2022 Miejoy. All rights reserved.
//  主要用于对当前模块这种事件的观察，外部可以通过添加观察者记录当前模块的各种动向

import Foundation
import Combine
import ModuleMonitor

/// 存储器变化事件
public enum ViewEvent: MonitorEvent, @unchecked Sendable {
    case viewDidAppear(view: any RoutableView, viewPath: ViewPath, scene: SceneState)
    case viewDidDisappear(view: any RoutableView, viewPath: ViewPath, scene: SceneState)
    case addViewState(state: any StorableViewState, viewPath: ViewPath, scene: SceneState)
    case updateViewState(state: any StorableViewState, viewPath: ViewPath, scene: SceneState)
    case removeViewState(state: any StorableViewState, viewPath: ViewPath, scene: SceneState)
    case wrapperRouteDataFailed(route: AnyViewRoute, data: Any)
    case callSceneSharedStateInitWithoutSceneId(any SceneWithIdSharableState.Type)
    case fatalError(String)
}

public protocol ViewMonitorObserver: MonitorObserver {
    @MainActor
    func receiveViewEvent(_ event: ViewEvent)
}

/// 存储器监听器
public final class ViewMonitor: ModuleMonitor<ViewEvent> {
    public nonisolated(unsafe) static let shared: ViewMonitor = {
        ViewMonitor { event, observer in
            DispatchQueue.executeOnMain {
                (observer as? ViewMonitorObserver)?.receiveViewEvent(event)
            }
        }
    }()

    public func addObserver(_ observer: ViewMonitorObserver) -> AnyCancellable {
        super.addObserver(observer)
    }
    
    public override func addObserver(_ observer: MonitorObserver) -> AnyCancellable {
        Swift.fatalError("Only ViewMonitorObserver can observer this monitor")
    }
}
