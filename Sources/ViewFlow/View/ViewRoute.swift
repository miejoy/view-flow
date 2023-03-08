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

public struct AnyViewRoute: Equatable {
    
    var initDataType: Any.Type
    
    var routeId: String
    
    var hashValue: AnyHashable
    
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

extension ViewRoute {
    public func eraseToAnyRoute() -> AnyViewRoute {
        .init(route: self)
    }
}

