//
//  SceneId.swift
//
//
//  Created by 黄磊 on 2024/11/9.
//  场景ID

import Foundation
import DataFlow

/// 场景ID
public enum SceneId: CustomStringConvertible, Hashable, Sendable {
    /// 主场景
    case main
    case custom(String)
    
    public var description: String {
        switch self {
        case .main:
            return "main"
        case .custom(let str):
            return str
        }
    }
}
