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

final class RoutableViewTests: XCTestCase {
    
    // 暂时无法测试，后期可能用 ViewInspector 测试
    func testViewAppear() {
        let mainView = MainRouteView()
        let mainBody = mainView.body

        XCTAssert(((mainBody as? TrackWrapperView<ContentRouteView>) != nil))

        let contentWrapperView = mainBody as! TrackWrapperView<ContentRouteView>
        let contentView = contentWrapperView.content
        let contentBody = contentView.body
        XCTAssert(((contentBody as? RouteWrapperView<Text>) != nil))
        print(contentBody.body)
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
