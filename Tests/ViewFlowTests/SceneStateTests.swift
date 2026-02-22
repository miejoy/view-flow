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
        Store<AllSceneState>.shared.subStates = [:]
        Store<AllSceneState>.shared.mapCancellable.removeAll()
    }
    
    func resetDefaultSceneState() {
        let sceneStore = Store<SceneState>.shared
        sceneStore.subStates = [:]
        sceneStore.arrAppearViewPath = []
        (sceneStore.storage as ViewFlow.SceneStorage).storage = [:]
        sceneStore.mapCancellable.removeAll()
    }
    
    func testAllSceneState() throws {
        resetAllSceneState()
        let allSceneStore = Store<AllSceneState>.shared
        XCTAssert(allSceneStore.state.subStates.isEmpty)
        
        var sceneStore : Store<SceneState>? = Store<SceneState>.shared
        XCTAssertEqual(allSceneStore.state.subStates.count, 1)
        XCTAssert((allSceneStore.state.subStates[sceneStore!.sceneId.description] != nil))
        
        allSceneStore[.allSceneStorage].removeSceneStore(of: sceneStore!.sceneId)
        sceneStore = nil
        XCTAssert(allSceneStore.state.subStates.isEmpty)
        resetAllSceneState()
    }
    
    func testMuiltSceneState() throws {
        resetAllSceneState()
        let allSceneStore = Store<AllSceneState>.shared
        XCTAssert(allSceneStore.state.subStates.isEmpty)
        
        var sceneStoreMain : Store<SceneState>? = Store<SceneState>.shared
        XCTAssertEqual(allSceneStore.state.subStates.count, 1)
        XCTAssert((allSceneStore.state.subStates[sceneStoreMain!.sceneId.description] != nil))
        
        var sceneStoreSecond : Store<SceneState>? = Store<SceneState>.shared(on: .custom("Second"))
        XCTAssertEqual(allSceneStore.state.subStates.count, 2)
        XCTAssert((allSceneStore.state.subStates[sceneStoreSecond!.state.sceneId.description] != nil))
        
        allSceneStore[.allSceneStorage].removeSceneStore(of: sceneStoreMain!.sceneId)
        allSceneStore[.allSceneStorage].removeSceneStore(of: sceneStoreSecond!.sceneId)
        
        sceneStoreMain = nil
        sceneStoreSecond = nil
        XCTAssert(allSceneStore.state.subStates.isEmpty)
        resetAllSceneState()
    }

    // 目前不可能出现同一个 SceneId 重复注册的情况
//    func testTwoSceneWithSameSceneId() {
//        resetDefaultSceneState()
//        let sceneStore = SharedState<Never>.getSceneStore()
//        let mainSceneId: SceneId = .main
//        XCTAssertEqual(sceneStore.sceneId, mainSceneId)
//        
//        ViewMonitor.shared.arrObservers = []
//        class Oberver: ViewMonitorOberver {
//            var sameSceneIdFatalErrorCall = false
//            func receiveViewEvent(_ event: ViewEvent) {
//                if case .fatalError(let message) = event,
//                    message == "Attach SceneState[Main] to AllSceneState failed: exist SceneState with same sceneId!" {
//                    sameSceneIdFatalErrorCall = true
//                }
//            }
//        }
//        let oberver = Oberver()
//        let cancellable = ViewMonitor.shared.addObserver(oberver)
//        
//        XCTAssert(!oberver.sameSceneIdFatalErrorCall)
//        let sameSceneStore = Store<SceneState>.shared
//        XCTAssertEqual(sceneStore.sceneId, sameSceneStore.sceneId)
//        XCTAssert(oberver.sameSceneIdFatalErrorCall)
//        
//        cancellable.cancel()
//    }
    
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
        XCTAssertEqual(allSceneStore.subStates.count, 1)
        
        allSceneStore[.allSceneStorage]?.removeSceneStore(of: .main)
        
        XCTAssertEqual(allSceneStore[.allSceneStorage].sceneIdToStoreMap.count, 0)
        XCTAssertEqual(allSceneStore.subStates.count, 1)
        
        sceneStore = nil
        XCTAssertEqual(allSceneStore.subStates.count, 0)
    }
}
