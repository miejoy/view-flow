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

final class SceneStateTests: XCTestCase {
    
    func resetAllSceneState() {
        Store<AllSceneState>.shared.subStates = [:]
    }
    
    func resetDefaultSceneState() {
        let sceneStore = SceneSharedState<Never>.getSceneStore()
        sceneStore.subStates = [:]
        sceneStore.arrAppearViewPath = []
        sceneStore.storage.storage = [:]
    }
    
    func testAllSceneState() throws {
        resetAllSceneState()
        let allSceneStore = Store<AllSceneState>.shared
        XCTAssert(allSceneStore.state.subStates.isEmpty)
        
        var sceneStore : Store<SceneState>? = Store<SceneState>()
        XCTAssertEqual(allSceneStore.state.subStates.count, 1)
        XCTAssert((allSceneStore.state.subStates[sceneStore!.sceneId.description] != nil))
        
        sceneStore = nil
        XCTAssert(allSceneStore.state.subStates.isEmpty)
    }
    
    func testMuiltSceneState() throws {
        let allSceneStore = Store<AllSceneState>.shared
        XCTAssert(allSceneStore.state.subStates.isEmpty)
        
        var sceneStoreMain : Store<SceneState>? = Store<SceneState>()
        XCTAssertEqual(allSceneStore.state.subStates.count, 1)
        XCTAssert((allSceneStore.state.subStates[sceneStoreMain!.sceneId.description] != nil))
        
        var sceneStoreSecond : Store<SceneState>? = Store<SceneState>.box(SceneState(.custom("Second")))
        XCTAssertEqual(allSceneStore.state.subStates.count, 2)
        XCTAssert((allSceneStore.state.subStates[sceneStoreSecond!.state.sceneId.description] != nil))
        
        sceneStoreMain = nil
        sceneStoreSecond = nil
        XCTAssert(allSceneStore.state.subStates.isEmpty)
    }

    // 目前不可能出现同一个 SceneId 重复注册的情况
//    func testTwoSceneWithSameSceneId() {
//        resetDefaultSceneState()
//        let sceneStore = SceneSharedState<Never>.getSceneStore()
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
        let sceneStore = SceneSharedState<Never>.getSceneStore()
        
        let firstPath = ViewPath(arrPaths: [], "MainView")
        let secondPath = ViewPath(arrPaths: firstPath.arrPaths, "SecondView")
        let thirdPath = ViewPath(arrPaths: firstPath.arrPaths, "ThirdView")
        XCTAssert(sceneStore.arrAppearViewPath.isEmpty)
        
        sceneStore.send(action: .onAppear(firstPath))
        XCTAssertEqual(sceneStore.arrAppearViewPath.count, 1)
        XCTAssertEqual(sceneStore.arrAppearViewPath[0].description, firstPath.description)
        
        sceneStore.send(action: .onAppear(secondPath))
        XCTAssertEqual(sceneStore.arrAppearViewPath.count, 2)
        XCTAssertEqual(sceneStore.arrAppearViewPath[0].description, secondPath.description)
        
        sceneStore.send(action: .onAppear(thirdPath))
        XCTAssertEqual(sceneStore.arrAppearViewPath.count, 3)
        XCTAssertEqual(sceneStore.arrAppearViewPath[0].description, thirdPath.description)
        
        sceneStore.send(action: .onDisappear(secondPath))
        XCTAssertEqual(sceneStore.arrAppearViewPath.count, 2)
        XCTAssertEqual(sceneStore.arrAppearViewPath[0].description, thirdPath.description)
        XCTAssertEqual(sceneStore.arrAppearViewPath[1].description, firstPath.description)
        
        sceneStore.send(action: .onDisappear(thirdPath))
        XCTAssertEqual(sceneStore.arrAppearViewPath.count, 1)
        XCTAssertEqual(sceneStore.arrAppearViewPath[0].description, firstPath.description)
    }
}
