//
//  RoutableViewTests.swift
//  
//
//  Created by 黄磊 on 2023/3/8.
//

import XCTest
import SwiftUI
import DataFlow
@testable import ViewFlow
import XCTViewFlow

@MainActor
final class RoutableViewTests: XCTestCase {
    
    // 暂时无法测试，后期可能用 ViewInspector 测试
    func testViewAppear() {
        let mainView = MainRouteView()
        let host = ViewTest.host(mainView)
        let mainBody = mainView.body
        
        let bodyStr = String(describing: mainBody)
        
        XCTAssert(bodyStr.contains("TrackWrapperView"))
        XCTAssert(bodyStr.contains("ContentRouteView"))
        
        ViewTest.releaseHost(host)
    }
    
    func testDefaultRoute() {
        XCTAssertEqual(ContentRouteView.defaultRoute.description, "ContentRouteView<Void>")
    }
}

struct MainRouteView: TrackableView {
    @Environment(\.viewPath) var viewPath
    var content: some View {
        ContentRouteView()
    }
}

struct ContentRouteView: VoidRoutableView {
    @Environment(\.viewPath) var viewPath
    var content: some View {
        Text("Hello")
    }
}
