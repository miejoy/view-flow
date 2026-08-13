//
//  SceneStateTests.swift
//  
//
//  Created by 黄磊 on 2022/6/8.
//

import XCTest
import SwiftUI
import DataFlow
@testable import ViewFlow
@testable import DataFlow

@MainActor
final class SceneStateTests: XCTestCase {
    
    func resetAllSceneState() {
        Store<AllSceneState>.shared[.allSceneStorage] = .init()
        Store<AllSceneState>.shared.mapCancellable.removeAll()
    }
    
    func resetDefaultSceneState() {
        let sceneStore = Store<SceneState>.shared
        sceneStore.arrAppearViewPath = []
        (sceneStore.storage as ViewFlow.SceneStorage).storage = [:]
        sceneStore.mapCancellable.removeAll()
    }
    
    func testAllSceneState() throws {
        resetAllSceneState()
        let allSceneStore = Store<AllSceneState>.shared
        XCTAssert(allSceneStore.subStateIds.isEmpty)
        
        var sceneStore : Store<SceneState>? = Store<SceneState>.shared
        XCTAssertEqual(allSceneStore.subStateIds.count, 1)
        XCTAssert((allSceneStore.getSubStore(of: SceneState.self, stateId: sceneStore!.state.stateId) != nil))
        
        allSceneStore[.allSceneStorage].removeSceneStore(of: sceneStore!.sceneId)
        sceneStore = nil
        XCTAssert(allSceneStore.subStateIds.isEmpty)
        resetAllSceneState()
    }
    
    func testMultiSceneState() throws {
        resetAllSceneState()
        let allSceneStore = Store<AllSceneState>.shared
        XCTAssert(allSceneStore.subStateIds.isEmpty)
        
        var sceneStoreMain : Store<SceneState>? = Store<SceneState>.shared
        XCTAssertEqual(allSceneStore.subStateIds.count, 1)
        XCTAssert((allSceneStore.getSubStore(of: SceneState.self, stateId: sceneStoreMain!.state.stateId) != nil))
        
        var sceneStoreSecond : Store<SceneState>? = Store<SceneState>.shared(on: .custom("Second"))
        XCTAssertEqual(allSceneStore.subStateIds.count, 2)
        XCTAssert((allSceneStore.getSubStore(of: SceneState.self, stateId: sceneStoreSecond!.state.stateId) != nil))
        
        allSceneStore[.allSceneStorage].removeSceneStore(of: sceneStoreMain!.sceneId)
        allSceneStore[.allSceneStorage].removeSceneStore(of: sceneStoreSecond!.sceneId)
        
        sceneStoreMain = nil
        sceneStoreSecond = nil
        XCTAssert(allSceneStore.subStateIds.isEmpty)
        resetAllSceneState()
    }

    func testSceneStateAction() {
        resetDefaultSceneState()
        let sceneStore = Store<SceneState>.shared
        
        let firstPath = ViewPath(arrPaths: [], "MainView")
        let secondPath = ViewPath(arrPaths: firstPath.arrPaths, "SecondView")
        let thirdPath = ViewPath(arrPaths: firstPath.arrPaths, "ThirdView")
        XCTAssertEqual(sceneStore.arrAppearViewPath.count, 0)
        let testView = ContentRouteView()
        
        sceneStore.send(action: .onAppear(testView, firstPath))
        XCTAssertEqual(sceneStore.arrAppearViewPath.count, 1)
        XCTAssertEqual(sceneStore.arrAppearViewPath[0].description, firstPath.description)
        
        sceneStore.send(action: .onAppear(testView, secondPath))
        XCTAssertEqual(sceneStore.arrAppearViewPath.count, 2)
        XCTAssertEqual(sceneStore.arrAppearViewPath[0].description, secondPath.description)
        
        sceneStore.send(action: .onAppear(testView, thirdPath))
        XCTAssertEqual(sceneStore.arrAppearViewPath.count, 3)
        XCTAssertEqual(sceneStore.arrAppearViewPath[0].description, thirdPath.description)
        
        sceneStore.send(action: .onDisappear(testView, secondPath))
        XCTAssertEqual(sceneStore.arrAppearViewPath.count, 2)
        XCTAssertEqual(sceneStore.arrAppearViewPath[0].description, thirdPath.description)
        XCTAssertEqual(sceneStore.arrAppearViewPath[1].description, firstPath.description)
        
        sceneStore.send(action: .onDisappear(testView, thirdPath))
        XCTAssertEqual(sceneStore.arrAppearViewPath.count, 1)
        XCTAssertEqual(sceneStore.arrAppearViewPath[0].description, firstPath.description)
    }
    
    func testSceneStoreDestroy() {
        resetAllSceneState()
        let allSceneStore = Store<AllSceneState>.shared
        var sceneStore: Store<SceneState>? = nil
        sceneStore = Store<SceneState>.shared
        
        XCTAssertEqual(allSceneStore[.allSceneStorage].sceneIdToStoreMap.count, 1)
        XCTAssertTrue(allSceneStore[.allSceneStorage].sceneIdToStoreMap[.main] === sceneStore)
        XCTAssertEqual(allSceneStore.subStateIds.count, 1)
        
        allSceneStore[.allSceneStorage].removeSceneStore(of: .main)
        
        XCTAssertEqual(allSceneStore[.allSceneStorage].sceneIdToStoreMap.count, 0)
        XCTAssertEqual(allSceneStore.subStateIds.count, 1)
        
        sceneStore = nil
        XCTAssertEqual(allSceneStore.subStateIds.count, 0)
    }
}
