//
//  ViewStateTests.swift
//  
//
//  Created by 黄磊 on 2022/6/12.
//

import XCTest
import SwiftUI
import DataFlow
@testable import ViewFlow

final class ViewStateTests: XCTestCase {
    
    func resetDefaultSceneState() {
        let sceneStore = SceneSharedState<Never>.getSceneStore()
        sceneStore.subStates = [:]
        sceneStore.arrAppearViewPath = []
        sceneStore.storage.storage = [:]
    }
    
    func testViewState() {
        resetDefaultSceneState()
        struct NormalView: View {
            @ViewState var normalState = NormalViewState()
            
            var body: some View {
                Text(normalState.name)
            }
        }
        
        let normalView = NormalView()
        var changeCall = false
        let cancellable = normalView.$normalState.objectWillChange.sink {
            changeCall = true
        }
        
        XCTAssert(!changeCall)
        
        let newName = "newName"
        normalView.normalState.name = newName
        XCTAssert(changeCall)
        XCTAssertEqual(normalView.$normalState.name, newName)
        
        cancellable.cancel()
    }
    
    func testReducerViewState() {
        struct ReducerView: View {
            @ViewState var reducerState = ReducerViewState()
            
            var body: some View {
                Text(reducerState.name)
            }
        }
        
        reducerStateReducerCall = false
        _ = ReducerView()
        XCTAssert(reducerStateReducerCall)
    }
    
    func testFullViewState() {
        struct FullView: View {
            @ViewState var fullState = FullViewState()
            
            var body: some View {
                Text(fullState.name)
                Button("Random Text") {
                    $fullState.send(action: .changeContent(String(Int.random(in: 100...999))))
                }
            }
        }
        
        reducerStateReducerCall = false
        let fullView = FullView()
        XCTAssert(reducerStateReducerCall)
        
        let content = String(Int.random(in: 100...999))
        fullView.$fullState.send(action: .changeContent(content))
        XCTAssertEqual(fullView.$fullState.name, content)
    }
    
    func testInitViewState() {
        struct InitView: View {
            @ViewState var initState: InitViewState
            
            var body: some View {
                Text(initState.name)
            }
        }
        
        let initView = InitView()
        XCTAssertEqual(initView.initState.name, "")
        
        let newName = "newName"
        initView.initState.name = newName
        XCTAssertEqual(initView.$initState.name, newName)
    }
    
    func testInitReducerViewState() {
        struct InitView: View {
            @ViewState var initState: InitReducerViewState
            
            var body: some View {
                Text(initState.name)
            }
        }
        
        initStateReducerCall = false
        _ = InitView()
        XCTAssert(initStateReducerCall)
    }
    
    func testViewStateLifeCircly() {
        resetDefaultSceneState()
        let sceneStore = SceneSharedState<Never>.getSceneStore()
        
        ViewMonitor.shared.arrObservers = []
        class Oberver: ViewMonitorOberver {
            var addViewCall = false
            var updateViewCall = false
            var removeViewCall = false
            func receiveViewEvent(_ event: ViewEvent) {
                switch event {
                case .addViewState:
                    addViewCall = true
                case .updateViewState:
                    updateViewCall = true
                case .removeViewState:
                    removeViewCall = true
                default:
                    break
                }
            }
        }
        let oberver = Oberver()
        let cancellable = ViewMonitor.shared.addObserver(oberver)
                
        struct NormalView: View {
            @Environment(\.viewPath) var viewPath
            @ViewState var normalState = FullViewState()
            
            var body: some View {
                Text(normalState.name)
                Button("Random Text") {
                    $normalState.send(action: .changeContent(String(Int.random(in: 100...999))))
                }
            }
        }
        
        XCTAssert(!oberver.addViewCall)
        XCTAssert(!oberver.updateViewCall)
        XCTAssert(!oberver.removeViewCall)
        XCTAssert(sceneStore.viewStateContainer.mapViewState.isEmpty)
        
        var normalView: NormalView? = NormalView()
        XCTAssert(oberver.addViewCall)
        XCTAssert(!oberver.updateViewCall)
        XCTAssert(!oberver.removeViewCall)
        let viewStateId = ViewStateContainer.ViewStateId(viewPath: normalView!.viewPath, stateId: normalView!.normalState.stateId)
        XCTAssert(sceneStore.viewStateContainer.mapViewState[viewStateId] != nil)
        XCTAssertEqual((sceneStore.viewStateContainer.mapViewState[viewStateId] as! FullViewState).name, "")
        
        let content = String(Int.random(in: 100...999))
        normalView?.$normalState.send(action: .changeContent(content))
        XCTAssert(oberver.addViewCall)
        XCTAssert(oberver.updateViewCall)
        XCTAssert(!oberver.removeViewCall)
        XCTAssertEqual((sceneStore.viewStateContainer.mapViewState[viewStateId] as! FullViewState).name, content)
        
        normalView = nil
        XCTAssert(oberver.addViewCall)
        XCTAssert(oberver.updateViewCall)
        XCTAssert(oberver.removeViewCall)
        XCTAssert(sceneStore.viewStateContainer.mapViewState.isEmpty)
        
        cancellable.cancel()
    }
    
    func testDuplicateViewState() {
        resetDefaultSceneState()
        let sceneStore = SceneSharedState<Never>.getSceneStore()
        struct NormalView: View {
            @ViewState var normalState = NormalViewState()
            
            var body: some View {
                Text(normalState.name)
            }
        }
        // 添加 A，添加 B: 重复添加
        // 移除 A，更新 B: 不存在
        // 移除 B: 不存在
        ViewMonitor.shared.arrObservers = []
        class Oberver: ViewMonitorOberver {
            var addErrorCall = false
            var updateErrorCall = false
            var removeErrorCall = false
            func receiveViewEvent(_ event: ViewEvent) {
                if case .fatalError(let message) = event {
                    switch message {
                    case "Add view state[NormalViewState] to scene[Main] failed: exist same state":
                        addErrorCall = true
                    case "Update view state[NormalViewState] on scene[Main] failed: state not exist":
                        updateErrorCall = true
                    case "Remove view state[NormalViewState] on scene[Main] failed: state not exist":
                        removeErrorCall = true
                    default:
                        break
                    }
                }
            }
        }
        let oberver = Oberver()
        let cancellable = ViewMonitor.shared.addObserver(oberver)
        
        var firstView: NormalView? = NormalView()
        XCTAssertEqual(sceneStore.viewStateContainer.mapViewState.keys.first!.description, "->\(firstView!.normalState.stateId)")
        XCTAssert(!oberver.addErrorCall)
        XCTAssert(!oberver.updateErrorCall)
        XCTAssert(!oberver.removeErrorCall)
        
        var secondView: NormalView? = NormalView()
        XCTAssert(oberver.addErrorCall)
        XCTAssert(!oberver.updateErrorCall)
        XCTAssert(!oberver.removeErrorCall)
        
        firstView = nil
        secondView?.normalState.name = "new"
        XCTAssert(oberver.addErrorCall)
        XCTAssert(oberver.updateErrorCall)
        XCTAssert(!oberver.removeErrorCall)
        
        secondView = nil
        XCTAssert(oberver.addErrorCall)
        XCTAssert(oberver.updateErrorCall)
        XCTAssert(oberver.removeErrorCall)
        
        cancellable.cancel()
    }
}


struct NormalViewState: ViewStateStorable {
    var name: String = ""
}

var reducerStateReducerCall = false
struct ReducerViewState: ViewStateStorable, StateReducerLoadable {
    var name: String = ""
    
    static func loadReducers(on store: Store<ReducerViewState>) {
        reducerStateReducerCall = true
    }
}

enum NormalViewAction: Action {
    case changeContent(String)
}

var fullViewStateReducerCall = false
struct FullViewState: FullViewStateStorable {
    typealias BindAction = NormalViewAction
    
    var name: String = ""
    
    static func loadReducers(on store: Store<FullViewState>) {
        reducerStateReducerCall = true
        store.registerDefault { state, action in
            switch action {
            case .changeContent(let content):
                state.name = content
            }
        }
    }
}

struct InitViewState: ViewStateStorable, StateInitable {
    var name: String = ""
}

var initStateReducerCall = false
struct InitReducerViewState: ViewStateStorable, StateReducerLoadable, StateInitable {
    var name: String = ""
    
    static func loadReducers(on store: Store<InitReducerViewState>) {
        initStateReducerCall = true
    }
}
