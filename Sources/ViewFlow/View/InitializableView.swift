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
    
    init(_ data: InitData)
}

/// 可无需参数初始化的 View
public protocol VoidInitializableView: InitializableView where InitData == Void {
    init()
}

extension VoidInitializableView {
    public init(_ data: InitData) {
        self.init()
    }
}
