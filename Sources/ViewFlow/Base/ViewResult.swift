//
//  ViewResult.swift
//  view-flow
//
//  界面返回结果枚举与错误类型
//

import Foundation

// MARK: - ViewResult

/// 界面返回结果
public enum ViewResult<ResultData: Sendable>: Sendable {
    /// 界面正常完成，携带结果数据
    case finished(ResultData)
    /// 用户取消 / 界面被关闭而未返回结果
    case cancelled
    /// 路由展示失败
    case failed(reason: String)

    /// 获取结果数据，cancelled/failed 时 throw
    ///
    /// 配合 async 路由 API 使用：
    /// ```swift
    /// do {
    ///     let picked = try await store.present(route, data)
    /// } catch ViewRouteError.cancelled {
    ///     // 用户取消
    /// } catch ViewRouteError.failed(let reason) {
    ///     // 路由展示失败
    /// }
    /// ```
    public func get() throws -> ResultData {
        switch self {
        case .finished(let data):
            return data
        case .cancelled:
            throw ViewRouteError.cancelled
        case .failed(let reason):
            throw ViewRouteError.failed(reason: reason)
        }
    }
    
    /// 转换成 `Result`，用于 `continuation.resume(with:)`
    public func resultToResultData() -> Result<ResultData, ViewRouteError> {
        switch self {
        case .finished(let data):
            return .success(data)
        case .cancelled:
            return .failure(.cancelled)
        case .failed(let reason):
            return .failure(.failed(reason: reason))
        }
    }
}

// MARK: - Equatable（仅当 ResultData: Equatable 时）

extension ViewResult: Equatable where ResultData: Equatable {
    public static func == (lhs: ViewResult<ResultData>, rhs: ViewResult<ResultData>) -> Bool {
        switch (lhs, rhs) {
        case (.finished(let a), .finished(let b)): return a == b
        case (.cancelled, .cancelled):             return true
        case (.failed(let a), .failed(let b)):     return a == b
        default:                                   return false
        }
    }
}

// MARK: - ViewRouteError

/// 路由错误
public enum ViewRouteError: Error, Sendable, Equatable {
    /// 用户取消 / 界面被关闭而未返回结果
    case cancelled
    /// 路由展示失败
    case failed(reason: String)
}
