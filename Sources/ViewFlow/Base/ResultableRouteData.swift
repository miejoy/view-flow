//
//  ResultableRouteData.swift
//  view-flow
//
//  带结果返回的界面路由数据
//

import Foundation
import DataFlow

// MARK: - CancellableRouteData

/// 可被路由管理方取消的路由数据
///
/// 路由管理方（present-flow / navigation-flow）在界面关闭或展示失败时，
/// 必须对实现了该协议的路由数据调用对应方法，否则调用方将永久挂起。
public protocol CancellableRouteData: Sendable {
    /// 取消路由（幂等）。用户侧滑返回 / dismiss / pop 时调用
    func cancelRoute()
    /// 路由展示失败（幂等）。路由未注册、数据类型不匹配等场景调用
    func failRoute(reason: String)
}

// MARK: - ResultableRouteData

/// 带结果返回的界面初始化数据
///
/// 作为 `ViewRoute` 的泛型实参使用，使界面能够在关闭时返回结果给调用方。
/// 典型场景：选择界面传入参数 → 用户选择完成 → 返回选中数据。
///
/// 路由管理方（present-flow / navigation-flow）的 async API 只提供 throws 版本，
/// 调用方通过 `do-catch` 或 `try` 处理取消和失败：
/// ```swift
/// do {
///     let picked = try await store.present(ItemPickerView.defaultResultRoute, items)
/// } catch ViewRouteError.cancelled {
///     // 用户取消
/// } catch ViewRouteError.failed(let reason) {
///     // 路由展示失败
/// }
/// ```
public struct ResultableRouteData<InitData: Sendable, ResultData: Sendable>: CancellableRouteData {

    /// 初始化界面所需数据
    public let initData: InitData

    /// 结果回调句柄，保证回调有且仅有一次
    let handle: ResultHandle<ResultData>

    /// 创建带结果返回的初始化数据
    /// - Parameters:
    ///   - initData: 初始化界面所需数据
    ///   - callback: 结果回调，有且仅有一次。收到 `.finished` / `.cancelled` / `.failed`
    public init(_ initData: InitData, callback: @escaping @Sendable (ViewResult<ResultData>) -> Void) {
        self.initData = initData
        self.handle = .init(callback)
    }

    /// 界面主动返回结果。调用后路由管理方再调 `cancelRoute()` 是 no-op（幂等）
    public func finishRoute(_ result: ResultData) {
        handle.trigger(.finished(result))
    }

    /// 取消路由，回调 `.cancelled`（幂等）
    public func cancelRoute() {
        handle.trigger(.cancelled)
    }

    /// 路由展示失败，回调 `.failed`（幂等）
    public func failRoute(reason: String) {
        handle.trigger(.failed(reason: reason))
    }
}

// MARK: - Void ResultData 便利

extension ResultableRouteData where ResultData == Void {
    /// 界面主动返回结果（Void 版本）
    public func finishRoute() {
        handle.trigger(.finished(()))
    }
}

// MARK: - ResultHandle

/// 结果回调句柄：保证回调有且仅有一次
///
/// 用 `DispatchQueue.syncOnStoreQueue` 取出即置空，所有竞争路径天然安全：
/// - `finishRoute` 后再 `cancelRoute` → no-op
/// - 连续两次 `finishRoute` → 只回调一次
/// - 路由管理方漏调 → `deinit` 兜底回调 `.cancelled`，防止调用方永久挂起
final class ResultHandle<ResultData: Sendable>: @unchecked Sendable {

    private var callback: (@Sendable (ViewResult<ResultData>) -> Void)?

    init(_ callback: @escaping @Sendable (ViewResult<ResultData>) -> Void) {
        self.callback = callback
    }

    /// 触发回调。取出并置空 callback，保证有且仅有一次
    func trigger(_ result: ViewResult<ResultData>) {
        let cb = DispatchQueue.syncOnStoreQueue {
            let captured = callback
            callback = nil
            return captured
        }
        cb?(result)
    }

    /// 兜底：路由管理方漏调 cancel/fail 时防止调用方永久挂起
    deinit {
        trigger(.cancelled)
    }
}

// MARK: - ResultViewRoute

/// 带结果返回的界面路由（`ViewRoute` 零改动）
public typealias ResultViewRoute<InitData: Sendable, ResultData: Sendable>
    = ViewRoute<ResultableRouteData<InitData, ResultData>>

// MARK: - ViewRouteData 便利方法

extension ViewRouteData {

    /// 如果 initData 实现了 `CancellableRouteData`，调用其 `cancelRoute()`
    /// 对普通 initData 是 no-op
    public func cancelRouteIfNeeded() {
        (initData as? CancellableRouteData)?.cancelRoute()
    }

    /// 如果 initData 实现了 `CancellableRouteData`，调用其 `failRoute(reason:)`
    /// 对普通 initData 是 no-op
    public func failRouteIfNeeded(reason: String) {
        (initData as? CancellableRouteData)?.failRoute(reason: reason)
    }
}
