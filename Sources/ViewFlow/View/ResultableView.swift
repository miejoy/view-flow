//
//  ResultableView.swift
//  view-flow
//
//  可返回结果的界面协议
//

import SwiftUI

/// 可返回结果的界面
///
/// `InitData` 约束为 `ResultableRouteData<InitParam, ResultData>`，使界面能够在关闭时返回结果。
///
/// 关闭界面推荐使用 `@Environment(\.dismiss)`，对 sheet 和 NavigationStack push 都有效，
/// 界面无需知道自己是被 present 还是 push 的：
/// ```swift
/// struct ItemPickerView: ResultableView {
///     typealias InitParam = [Item]
///     typealias ResultData = [Item]
///
///     @Environment(\.dismiss) var dismiss
///     let routeData: ResultableRouteData<[Item], [Item]>
///
///     init(_ routeData: ResultableRouteData<[Item], [Item]>) {
///         self.routeData = routeData
///     }
///
///     var content: some View {
///         Button("完成") {
///             routeData.finishRoute(selected)
///             dismiss()
///         }
///     }
/// }
/// ```
public protocol ResultableView: RoutableView
    where InitData == ResultableRouteData<InitParam, ResultData> {
    /// 初始化界面所需参数类型
    associatedtype InitParam: Sendable
    /// 界面返回的结果数据类型
    associatedtype ResultData: Sendable
}

/// 无需初始化参数的可返回结果界面
public protocol VoidResultableView: ResultableView where InitParam == Void {}
