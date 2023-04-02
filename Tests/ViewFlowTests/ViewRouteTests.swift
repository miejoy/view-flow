//
//  ViewRouteTests.swift
//  
//
//  Created by 黄磊 on 2023/3/8.
//

import XCTest
import ViewFlow
import SwiftUI
@testable import ViewFlow

final class ViewRouteTests: XCTestCase {
    func testRouteEqual() throws {
        let route1 = ViewRoute<Void>(routeId: s_defaultViewRouteId)
        let route2 = ViewRoute<Void>(routeId: s_defaultViewRouteId)
        
        XCTAssertEqual(route1, route2)
        XCTAssertEqual(route1.description, route2.description)
    }
    
    func testAnyRouteEqual() throws {
        let route1 = ViewRoute<Void>(routeId: s_defaultViewRouteId)
        let anyRoute1 = ViewRoute<Void>(routeId: s_defaultViewRouteId).eraseToAnyRoute()
        let anyRoute2 = ViewRoute<Void>(routeId: s_defaultViewRouteId).eraseToAnyRoute()
        
        XCTAssert(anyRoute1.equelToRoute(route1))
        XCTAssertEqual(route1.description, anyRoute1.description)
        XCTAssertEqual(anyRoute1, anyRoute2)
    }
    
    func testRouteNotEqualWithDifferentInitType() throws {
        let route1 = ViewRoute<Void>(routeId: s_defaultViewRouteId).eraseToAnyRoute()
        let route2 = ViewRoute<String>(routeId: s_defaultViewRouteId).eraseToAnyRoute()
        
        XCTAssertNotEqual(route1, route2)
    }
    
    func testRouteNotEqualWithDifferentRouteId() throws {
        let route1 = ViewRoute<Void>(routeId: s_defaultViewRouteId).eraseToAnyRoute()
        let route2 = ViewRoute<Void>(routeId: s_defaultViewRouteId + "1").eraseToAnyRoute()
        
        XCTAssertNotEqual(route1, route2)
    }
    
    func testRouteWrapperData() {
        let rightData: String = "test"
        let route = ViewRoute<String>(routeId: s_defaultViewRouteId)
        
        let routeData = route.wrapper(rightData)
        XCTAssertEqual(routeData.initData as? String, rightData)
        XCTAssertEqual(routeData.route, route.eraseToAnyRoute())
    }
    
    func testAnyRouteWrapperData() {
        let rightData: String = "test"
        let rightAnyData: Any = rightData
        let wrongData: Any = Int(1)
        let route = ViewRoute<String>(routeId: s_defaultViewRouteId)
        let anyRoute = route.eraseToAnyRoute()
        
        let anyRouteData1 = anyRoute.wrapper(rightData)
        let anyRouteData2 = anyRoute.wrapper(rightAnyData)
        let anyRouteData3 = anyRoute.wrapper(wrongData)
        
        XCTAssertEqual(anyRouteData1?.initData as? String, rightData)
        XCTAssertEqual(anyRouteData2?.initData as? String, rightData)
        XCTAssertNil(anyRouteData3)
    }
}

