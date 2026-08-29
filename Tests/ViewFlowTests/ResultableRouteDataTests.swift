//
//  ResultableRouteDataTests.swift
//  view-flow
//
//  ResultableRouteData / ResultableView / ResultViewRoute / ViewResult 测试
//

import XCTest
import ViewFlow
import SwiftUI
@testable import ViewFlow

final class ResultableRouteDataTests: XCTestCase {

    // MARK: - 基本返回

    func testFinishReturnsFinished() {
        let result = waitForResult(initData: "init") { routeData in
            routeData.finishRoute("hello")
        }
        XCTAssertEqual(result, .finished("hello"))
    }

    func testCancelReturnsCancelled() {
        let result = waitForResult(initData: "init") { (routeData: ResultableRouteData<String, String>) in
            routeData.cancelRoute()
        }
        XCTAssertEqual(result, .cancelled)
    }

    func testFailReturnsFailed() {
        let result = waitForResult(initData: "init") { (routeData: ResultableRouteData<String, String>) in
            routeData.failRoute(reason: "not registered")
        }
        XCTAssertEqual(result, .failed(reason: "not registered"))
    }

    // MARK: - 幂等

    func testFinishThenCancelIsNoop() {
        let result = waitForResult(initData: "init") { routeData in
            routeData.finishRoute("done")
            routeData.cancelRoute()
            routeData.failRoute(reason: "test")
        }
        XCTAssertEqual(result, .finished("done"))
    }

    func testCancelThenFinishIsNoop() {
        let result = waitForResult(initData: "init") { (routeData: ResultableRouteData<String, String>) in
            routeData.cancelRoute()
            routeData.finishRoute("done")
        }
        XCTAssertEqual(result, .cancelled)
    }

    func testDoubleFinishOnlyCallbacksOnce() {
        nonisolated(unsafe) var callbackCount = 0
        let routeData = ResultableRouteData<String, Int>("init") { _ in
            callbackCount += 1
        }
        routeData.finishRoute(1)
        routeData.finishRoute(2)
        routeData.finishRoute(3)
        XCTAssertEqual(callbackCount, 1)
    }

    // MARK: - ViewResult.get() throws

    func testGetReturnsDataOnFinished() throws {
        let result = ViewResult.finished("ok")
        XCTAssertEqual(try result.get(), "ok")
    }

    func testGetThrowsOnCancelled() {
        let result = ViewResult<String>.cancelled
        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertEqual(error as? ViewRouteError, .cancelled)
        }
    }

    func testGetThrowsOnFailed() {
        let result = ViewResult<String>.failed(reason: "boom")
        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertEqual(error as? ViewRouteError, .failed(reason: "boom"))
        }
    }

    // MARK: - Void ResultData

    func testVoidFinishReturnsFinished() {
        nonisolated(unsafe) var received: ViewResult<Void>?
        let routeData = ResultableRouteData<Void, Void>(()) { result in
            received = result
        }
        routeData.finishRoute()
        if case .finished = received {} else {
            XCTFail("expected .finished, got \(String(describing: received))")
        }
    }

    // MARK: - deinit 兜底

    func testDeinitFiresCancelled() {
        nonisolated(unsafe) var received: ViewResult<String>?
        do {
            let routeData = ResultableRouteData<String, String>("init") { result in
                received = result
            }
            _ = routeData
        }
        XCTAssertEqual(received, .cancelled)
    }

    // MARK: - ResultViewRoute typealias

    func testResultViewRouteNotEqualToPlainViewRoute() {
        // InitData 都是 String，仅区分「带不带结果返回」
        let resultRoute = ResultViewRoute<String, Void>("Picker").eraseToAnyRoute()
        let plainRoute = ViewRoute<String>("Picker").eraseToAnyRoute()
        XCTAssertNotEqual(resultRoute, plainRoute)
    }

    func testResultViewRouteEqualToSameType() {
        let r1 = ResultViewRoute<String, Int>("Picker").eraseToAnyRoute()
        let r2 = ResultViewRoute<String, Int>("Picker").eraseToAnyRoute()
        XCTAssertEqual(r1, r2)
    }

    func testResultViewRouteDifferentResultDataNotEqual() {
        let r1 = ResultViewRoute<String, Int>("Picker").eraseToAnyRoute()
        let r2 = ResultViewRoute<String, String>("Picker").eraseToAnyRoute()
        XCTAssertNotEqual(r1, r2)
    }

    func testResultViewRouteWrapperProducesResultableRouteData() {
        let route = ResultViewRoute<String, String>("Picker")
        let inner = ResultableRouteData<String, String>("init") { _ in }
        let routeData = route.wrapper(inner)
        XCTAssertNotNil(routeData.initData as? ResultableRouteData<String, String>)
    }

    // MARK: - ViewRouteData.cancelRouteIfNeeded

    func testCancelRouteIfNeededOnPlainDataIsNoop() {
        let route = ViewRoute<String>("PlainRoute")
        let routeData = route.wrapper("hello")
        routeData.cancelRouteIfNeeded()
        routeData.failRouteIfNeeded(reason: "test")
        XCTAssertEqual(routeData.initData as? String, "hello")
    }

    func testCancelRouteIfNeededOnResultableData() {
        nonisolated(unsafe) var received: ViewResult<String>?
        let route = ViewRoute<ResultableRouteData<String, String>>("ResultRoute")
        let inner = ResultableRouteData<String, String>("init") { result in
            received = result
        }
        let routeData = route.wrapper(inner)
        routeData.cancelRouteIfNeeded()
        XCTAssertEqual(received, .cancelled)
    }

    // MARK: - initData 访问

    func testInitDataAccessible() {
        let routeData = ResultableRouteData<[String], Int>(["a", "b"]) { _ in }
        XCTAssertEqual(routeData.initData, ["a", "b"])
    }

    // MARK: - 默认 callback（不处理结果）

    func testDefaultCallbackDoesNotFire() {
        // 不传 callback，finishRoute / cancelRoute 不崩溃，回调为默认空实现
        let routeData = ResultableRouteData<String, String>("init")
        routeData.finishRoute("done")
        routeData.cancelRoute()
        // 能正常访问 initData 即可
        XCTAssertEqual(routeData.initData, "init")
    }

    // MARK: - Helper

    private func waitForResult<R: Sendable & Equatable>(
        initData: String,
        action: (ResultableRouteData<String, R>) -> Void
    ) -> ViewResult<R> {
        nonisolated(unsafe) var received: ViewResult<R>?
        let routeData = ResultableRouteData<String, R>(initData) { result in
            received = result
        }
        action(routeData)
        guard let result = received else {
            XCTFail("callback not fired")
            return .cancelled
        }
        return result
    }
}
