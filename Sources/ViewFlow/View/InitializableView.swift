//
//  InitializableView.swift
//  
//
//  Created by 黄磊 on 2022/8/5.
//

import SwiftUI

/// 可初始化的 View
public protocol InitializableView: View {
    associatedtype InitData
    
    /// 初始化方法
    init(_ data: InitData)
    
    /// 尝试构造初始化所需数据
    static func makeInitializeData(from data: Any) -> InitData?
}

/// 可无需参数初始化的 View
public protocol VoidInitializableView: InitializableView where InitData == Void {
    init()
}


extension InitializableView {
    public static func makeInitializeData(from data: Any) -> InitData? {
        return nil
    }
}

extension VoidInitializableView {
    public init(_ data: InitData) {
        self.init()
    }
    
    public static func makeInitializeData(from data: Any) -> InitData? {
        return ()
    }
}
