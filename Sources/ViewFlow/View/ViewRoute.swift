//
//  ViewRoute.swift
//  
//
//  Created by 黄磊 on 2023/3/8.
//  Copyright © 2023 Miejoy. All rights reserved.
//  界面路由标识

import Foundation

/// 默认展示界面路由 ID
public let s_defaultViewRouteId = "__default__"

/// 界面对应路由标识
public struct ViewRoute<InitData>: Hashable, CustomStringConvertible {
    var routeId: String
    
    public init(routeId: String = s_defaultViewRouteId) {
        self.routeId = routeId
    }
    
    public var description: String {
        "\(routeId)<\(String(describing: InitData.self).replacingOccurrences(of: "()", with: "Void"))>"
    }
}

/// 抹除初始化类型的界面对应路由标识
public struct AnyViewRoute: Equatable {
    
    public var initDataType: Any.Type
    
    public var routeId: String
    
    public var hashValue: AnyHashable
    
    init<InitData>(route: ViewRoute<InitData>) {
        self.initDataType = InitData.self
        self.routeId = route.routeId
        self.hashValue = AnyHashable(route)
    }
    
    func equelToRoute<InitData>(_ route: ViewRoute<InitData>) -> Bool {
        InitData.self == initDataType && routeId == route.routeId
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    public var description: String {
        "\(routeId)<\(String(describing: initDataType).replacingOccurrences(of: "()", with: "Void"))>"
    }
}

/// 包含数据的界面路由，这个包含了初始化界面需要的所有内容
public struct ViewRouteData {
    
    public let route: AnyViewRoute
    
    public let initData: Any
    
    init(route: AnyViewRoute, initData: Any) {
        self.initData = initData
        self.route = route
    }
        
    init<InitData>(route: ViewRoute<InitData>, data: InitData) {
        self.init(route: route.eraseToAnyRoute(), initData: data)
    }
}

extension ViewRoute {
    public func eraseToAnyRoute() -> AnyViewRoute {
        .init(route: self)
    }
    
    /// 包装成完整路由
    public func wrapper(_ data: InitData) -> ViewRouteData {
        .init(route: self, data: data)
    }
}

extension AnyViewRoute {
    /// 包装成完整路由，如果传入的数据类型不是初始化的数据类型，会返回 nil
    public func wrapper(_ data: Any) -> ViewRouteData? {
        guard type(of: data) == self.initDataType else {
            ViewMonitor.shared.record(event: .wrapperRouteDataFailed(route: self, data: data))
            return nil
        }
        return .init(route: self, initData: data)
    }
}

