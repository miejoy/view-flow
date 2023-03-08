//
//  ViewPath.swift
//  
//
//  Created by 黄磊 on 2023/3/5.
//

import SwiftUI
import DataFlow

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
