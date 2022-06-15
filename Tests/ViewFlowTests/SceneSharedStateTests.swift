//
//  SceneSharedStateTests.swift
//  
//
//  Created by 黄磊 on 2022/6/11.
//

import XCTest
import SwiftUI
import DataFlow
@testable import ViewFlow

final class SceneSharedStateTests: XCTestCase {
    
    func resetDefaultSceneState() {
        let sceneStore = SceneSharedState<NormalSharedState>.getSceneStore()
        sceneStore.subStates = [:]
        sceneStore.arrAppearViewPath = []
        sceneStore.viewStateContainer.mapViewState = [:]
        sceneStore.storage.storage = [:]
    }
    
    func testSceneSharedState() {
        resetDefaultSceneState()
        let sceneStore = SceneSharedState<NormalSharedState>.getSceneStore()
        XCTAssert(sceneStore.storeContainer.mapExistSharedStore.isEmpty)
        XCTAssert(sceneStore.state.subStates.isEmpty)
        
        let normalSharedStateWrapper = SceneSharedState<NormalSharedState>()
        XCTAssertEqual(sceneStore.storeContainer.mapExistSharedStore.count, 1)
        XCTAssert(sceneStore.state.subStates[normalSharedStateWrapper.wrappedValue.stateId] != nil)
        
        let secondSharedStateWrapper = SceneSharedState<NormalSharedState>()
        XCTAssertEqual(sceneStore.storeContainer.mapExistSharedStore.count, 1)
        
        XCTAssertEqual(secondSharedStateWrapper.wrappedValue.name, "")
        let newName = "new"
        normalSharedStateWrapper.wrappedValue.name = newName
        XCTAssertEqual(secondSharedStateWrapper.wrappedValue.name, newName)
    }
    
    func testSceneStateFullSharable() {
        resetDefaultSceneState()
        let sceneStore = SceneSharedState<NormalSharedState>.getSceneStore()
        XCTAssert(sceneStore.storeContainer.mapExistSharedStore.isEmpty)
        XCTAssert(sceneStore.state.subStates.isEmpty)
        
        sharedReducerIsLoad = false
        _ = SceneSharedState<FullSharedState>()
        XCTAssert(sharedReducerIsLoad)
    }
    
    func testSceneSharedStateSharedInSameScene() {
        resetDefaultSceneState()
        let sceneStore = SceneSharedState<NormalSharedState>.getSceneStore()
        XCTAssert(sceneStore.storeContainer.mapExistSharedStore.isEmpty)
        XCTAssert(sceneStore.state.subStates.isEmpty)
        
        let normalSharedStateWrapper = SceneSharedState<NormalSharedState>()
        let secondSharedStateWrapper = SceneSharedState<NormalSharedState>()
        XCTAssertEqual(sceneStore.storeContainer.mapExistSharedStore.count, 1)
        
        XCTAssertEqual(secondSharedStateWrapper.wrappedValue.name, "")
        let newName = "new"
        normalSharedStateWrapper.wrappedValue.name = newName
        XCTAssertEqual(secondSharedStateWrapper.wrappedValue.name, newName)
        XCTAssertEqual((sceneStore.subStates[normalSharedStateWrapper.wrappedValue.stateId] as! NormalSharedState).name, newName)
        XCTAssertEqual((sceneStore.subStates[secondSharedStateWrapper.wrappedValue.stateId] as! NormalSharedState).name, newName)
    }
    
    func testSceneSharedStateUseInView() {
        resetDefaultSceneState()
        let sceneStore = SceneSharedState<NormalSharedState>.getSceneStore()
        XCTAssert(sceneStore.storeContainer.mapExistSharedStore.isEmpty)
        XCTAssert(sceneStore.state.subStates.isEmpty)
        
        let normalSharedStateWrapper = SceneSharedState<NormalSharedState>()
        
        let view = NormalView()
        XCTAssertEqual(normalSharedStateWrapper.wrappedValue.name, "")
        XCTAssertEqual(view.normalSharedState.name, "")
        
        let newName = "newName"
        view.normalSharedState.name = newName
        XCTAssertEqual(view.normalSharedState.name, newName)
        XCTAssertEqual(view.$normalSharedState.name, newName)
        XCTAssertEqual(normalSharedStateWrapper.wrappedValue.name, newName)
    }
    
    func testDuplicateSceneSharedState() {
        resetDefaultSceneState()
        class Oberver: ViewMonitorOberver {
            var duplicateFatalErrorCall = false
            func receiveViewEvent(_ event: ViewEvent) {
                if case .fatalError(let message) = event,
                    message == ("Attach State[DuplicateSharedState] to UpState[SceneState] " +
                                "with stateId[NormalSharedState] failed: " +
                                "exist State[NormalSharedState] with same stateId!") {
                    duplicateFatalErrorCall = true
                }
            }
        }
        let oberver = Oberver()
        let cancellable = ViewMonitor.shared.addObserver(oberver)
        
        _ = SceneSharedState<NormalSharedState>()
        XCTAssert(!oberver.duplicateFatalErrorCall)
        
        _ = SceneSharedState<DuplicateSharedState>()
        XCTAssert(oberver.duplicateFatalErrorCall)
        
        cancellable.cancel()
    }
}

struct NormalSharedState: SceneStateSharable {
    typealias UpState = SceneState
    var name: String = ""
}

struct DuplicateSharedState: SceneStateSharable {
    typealias UpState = SceneState
    var name: String = ""
    
    var stateId: String = "NormalSharedState"
}

enum NormalAction: Action {
    case userClick
}

var sharedReducerIsLoad = false
struct FullSharedState: FullSceneStateSharable {
    typealias UpState = SceneState
    typealias BindAction = NormalAction
    var name: String = ""
    
    static func loadReducers(on store: Store<FullSharedState>) {
        sharedReducerIsLoad = true
    }
}

struct NormalView: View {
    
    @SceneSharedState var normalSharedState: NormalSharedState
    
    var body: some View {
        Text("Hello")
    }
}
