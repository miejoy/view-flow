//
//  ViewMonitor.swift
//  
//
//  Created by 黄磊 on 2022/6/3.
//  Copyright © 2022 Miejoy. All rights reserved.
//  主要用于对当前模块这种事件的观察，外部可以通过添加观察者记录当前模块的各种动向

import Foundation
import Combine

/// 存储器变化事件
public enum ViewEvent {
    case viewDidAppear(viewPath: ViewPath, scene: SceneState)
    case viewDidDisappear(viewPath: ViewPath, scene: SceneState)
    case addViewState(state: any ViewStateStorable, viewPath: ViewPath, scene: SceneState)
    case updateViewState(state: any ViewStateStorable, viewPath: ViewPath, scene: SceneState)
    case removeViewState(state: any ViewStateStorable, viewPath: ViewPath, scene: SceneState)
    case fatalError(String)
}

public protocol ViewMonitorOberver: AnyObject {
    func receiveViewEvent(_ event: ViewEvent)
}


/// 存储器监听器
public final class ViewMonitor {
        
    struct Observer {
        let observerId: Int
        weak var observer: ViewMonitorOberver?
    }
    
    /// 监听器共享单例
    public static var shared: ViewMonitor = .init()
    
    /// 所有观察者
    var arrObservers: [Observer] = []
    var generateObserverId: Int = 0
    
    required init() {
    }
    
    /// 添加观察者
    public func addObserver(_ observer: ViewMonitorOberver) -> AnyCancellable {
        generateObserverId += 1
        let observerId = generateObserverId
        arrObservers.append(.init(observerId: generateObserverId, observer: observer))
        return AnyCancellable { [weak self] in
            if let index = self?.arrObservers.firstIndex(where: { $0.observerId == observerId}) {
                self?.arrObservers.remove(at: index)
            }
        }
    }
    
    /// 记录对应事件，这里只负责将所有事件传递给观察者
    @usableFromInline
    func record(event: ViewEvent) {
        guard !arrObservers.isEmpty else { return }
        arrObservers.forEach { $0.observer?.receiveViewEvent(event) }
    }
    
    @usableFromInline
    func fatalError(_ message: String) {
        guard !arrObservers.isEmpty else {
            #if DEBUG
            Swift.fatalError(message)
            #else
            return
            #endif
        }
        arrObservers.forEach { $0.observer?.receiveViewEvent(.fatalError(message)) }
    }
}
