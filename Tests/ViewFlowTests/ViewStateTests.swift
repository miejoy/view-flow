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
import XCTViewFlow

final class ViewStateTests: XCTestCase {
    
    func resetDefaultSceneState() {
        let sceneStore = Store<SceneState>.shared
        sceneStore.subStates = [:]
        sceneStore.arrAppearViewPath = []
        sceneStore.storage.storage = [:]
    }
    
    func testViewState() {
        resetDefaultSceneState()
        
        var storage: ViewStateWrapperStorage<NormalViewState>? = nil
        var normalStore: Store<NormalViewState>? = nil
                
        struct NormalView: View {
            @ViewState var normalState = NormalViewState()
            var callback: (ViewStateWrapperStorage<NormalViewState>, Store<NormalViewState>) -> Void
            
            var body: some View {
                callback(_normalState.storage, $normalState)
                return Text(normalState.name)
            }
        }
        
        let normalView = NormalView { storage = $0; normalStore = $1 }
        let host = ViewTest.host(normalView)
        
        XCTAssertNotNil(storage)
        XCTAssertTrue(storage?.isReady ?? false)
        XCTAssertNotNil(normalStore)
                
        var changeCall = false
        let cancellable = storage?.objectWillChange.sink {
            changeCall = true
        }
        
        XCTAssertFalse(changeCall)
        let newName = "newName"
        normalStore?.name = newName
        XCTAssertTrue(changeCall)
        XCTAssertEqual(storage?.store.name, newName)
        
        ViewTest.releaseHost(host)
        cancellable?.cancel()
    }
    
    func testViewStateRefreshInView() {
        var storage: ViewStateWrapperStorage<NormalViewState>? = nil
        var normalStore: Store<NormalViewState>? = nil
                
        struct NormalView: View {
            @ViewState var normalState = NormalViewState()
            var callback: (ViewStateWrapperStorage<NormalViewState>, Store<NormalViewState>) -> Void
            
            var body: some View {
                callback(_normalState.storage, $normalState)
                return Text(normalState.name)
            }
        }
        
        var secondRefreshCall = false
        let normalView = NormalView {
            if let oldStorage = storage, let oldStore = normalStore {
                XCTAssertTrue(oldStorage === $0)
                XCTAssertTrue(oldStore === $1)
                secondRefreshCall = true
            } else {
                storage = $0; normalStore = $1
            }
        }
        let host = ViewTest.host(normalView)
        
        var changeCall = false
        let cancellable = storage?.objectWillChange.sink {
            changeCall = true
        }
        
        normalStore?.name = "123"
        XCTAssertTrue(changeCall)
        ViewTest.refreshHost(host)

        XCTAssertTrue(secondRefreshCall)

        ViewTest.releaseHost(host)
        cancellable?.cancel()
    }
    
    func testReducerViewState() {
        struct ReducerView: View {
            @ViewState var reducerState = ReducerViewState()
            
            var body: some View {
                Text(reducerState.name)
            }
        }
                
        reducerStateReducerCall = false
        let reducerView = ReducerView()
        let host = ViewTest.host(reducerView)
        XCTAssert(reducerStateReducerCall)
        
        ViewTest.releaseHost(host)
    }
    
    func testFullViewState() {
        var storage: ViewStateWrapperStorage<FullViewState>? = nil
        var fullStore: Store<FullViewState>? = nil
                
        struct FullView: View {
            @ViewState var fullState = FullViewState()
            var callback: (ViewStateWrapperStorage<FullViewState>, Store<FullViewState>) -> Void
            
            var body: some View {
                callback(_fullState.storage, $fullState)
                return ZStack {
                    Text(fullState.name)
                    Button("Random Text") {
                        $fullState.send(action: .changeContent(String(Int.random(in: 100...999))))
                    }
                }
                .onAppear {
                    XCTAssertEqual(fullState.name, "")
                    $fullState.send(action: .changeContent("newName"))
                }
            }
        }
        
        reducerStateReducerCall = false
        var secondRefreshCall = false
        let fullView = FullView() {
            if let oldStorage = storage, let oldStore = fullStore {
                XCTAssertTrue(oldStorage === $0)
                XCTAssertTrue(oldStore === $1)
                secondRefreshCall = true
            } else {
                storage = $0; fullStore = $1
            }
        }
        let host = ViewTest.host(fullView)
        XCTAssertTrue(reducerStateReducerCall)
        
        XCTAssertTrue(secondRefreshCall)
        
        XCTAssertEqual(fullStore?.name, "newName")
        
        ViewTest.releaseHost(host)
    }
    
    func testInitViewState() {
        struct InitView: View {
            @ViewState var initState: InitViewState = .init()
            var callback: (Store<InitViewState>) -> Void
            
            var body: some View {
                callback($initState)
                return Text(initState.name)
                    .onAppear {
                        XCTAssertEqual(initState.name, "")
                        initState.name = "newName"
                    }
            }
        }
        
        var initStore: Store<InitViewState>? = nil
        let initView = InitView { store in
            if initStore == nil {
                initStore = store
                XCTAssertEqual(initStore?.name, "")
            }
        }
        let host = ViewTest.host(initView)
        
        XCTAssertEqual(initStore?.name, "newName")
        
        ViewTest.releaseHost(host)
    }
    
    func testInitReducerViewState() {
        struct InitView: View {
            @ViewState var initState: InitReducerViewState = .init()
            
            var body: some View {
                Text(initState.name)
            }
        }
        
        initStateReducerCall = false
        let initView = InitView()
        let host = ViewTest.host(initView)
        
        XCTAssert(initStateReducerCall)
        ViewTest.releaseHost(host)
    }
    
    func testViewStateLifeCircly() {
        resetDefaultSceneState()
        let sceneStore = Store<SceneState>.shared
        
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
            var callback: (ViewStateWrapperStorage<FullViewState>) -> Void
            
            var body: some View {
                callback(_normalState.storage)
                return VStack {
                    Text(normalState.name)
                    Button("Random Text") {
                        $normalState.send(action: .changeContent(String(Int.random(in: 100...999))))
                    }
                }
                .onAppear {
                    $normalState.send(action: .changeContent("content"))
                }
            }
        }
        
        XCTAssert(!oberver.addViewCall)
        XCTAssert(!oberver.updateViewCall)
        XCTAssert(!oberver.removeViewCall)
        XCTAssert(sceneStore.viewStateContainer.mapViewState.isEmpty)
        
        var normalStateWrapper: ViewStateWrapperStorage<FullViewState>? = nil
        
        var normalView: NormalView? = NormalView { wrapper in
            if let oldWrapper = normalStateWrapper {
                XCTAssert(oldWrapper === wrapper)
            } else {
                normalStateWrapper = wrapper
                XCTAssert(oberver.addViewCall)
                XCTAssert(!oberver.updateViewCall)
                XCTAssert(!oberver.removeViewCall)
            }
        }
        
        autoreleasepool {
            let host = ViewTest.host(normalView!.environment(\.recordViewState, true))
            
            let viewStateId = ViewStateContainer.ViewStateId(viewPath: .init(), stateId: normalStateWrapper!.store.stateId)

            XCTAssert(sceneStore.viewStateContainer.mapViewState[viewStateId] != nil)
            XCTAssertEqual((sceneStore.viewStateContainer.mapViewState[viewStateId] as! FullViewState).name, "content")

            XCTAssert(oberver.addViewCall)
            XCTAssert(oberver.updateViewCall)
            XCTAssert(!oberver.removeViewCall)
            
            ViewTest.releaseHost(host)
            normalView = nil
            normalStateWrapper = nil
        }
        
        XCTAssert(oberver.addViewCall)
        XCTAssert(oberver.updateViewCall)
        // macOS VC 释放存在问题
        #if os(iOS) || os(tvOS)
        XCTAssert(oberver.removeViewCall)
        XCTAssert(sceneStore.viewStateContainer.mapViewState.isEmpty)
        #endif
        
        cancellable.cancel()
    }
    
    // macOS VC 释放存在问题
    #if os(iOS) || os(tvOS)
    func testDuplicateViewState() {
        resetDefaultSceneState()
        let sceneStore = Store<SceneState>.shared
        struct NormalView: View {
            @ViewState var normalState = NormalViewState()
            var callback: (ViewStateWrapperStorage<NormalViewState>) -> Void
            
            var body: some View {
                callback(_normalState.storage)
                return Text(normalState.name)
            }
        }
        // 添加 A，添加 B: 重复添加
        // 移除 B，更新 A: 不存在
        // 移除 A: 不存在
        ViewMonitor.shared.arrObservers = []
        class Oberver: ViewMonitorOberver {
            var addErrorCall = false
            var updateErrorCall = false
            var removeErrorCall = false
            func receiveViewEvent(_ event: ViewEvent) {
                if case .fatalError(let message) = event {
                    switch message {
                    case "Add view state[NormalViewState] to scene[main] failed: exist same state":
                        addErrorCall = true
                    case "Update view state[NormalViewState] on scene[main] failed: state not exist":
                        updateErrorCall = true
                    case "Remove view state[NormalViewState] on scene[main] failed: state not exist":
                        removeErrorCall = true
                    default:
                        break
                    }
                }
            }
        }
        let oberver = Oberver()
        let cancellable = ViewMonitor.shared.addObserver(oberver)
        
        autoreleasepool {
            var firstWrapper: ViewStateWrapperStorage<NormalViewState>? = nil
            var firstView: NormalView? = NormalView { wrapper in
                firstWrapper = wrapper
            }
            let host1 = ViewTest.host(firstView!.environment(\.recordViewState, true))
            XCTAssertEqual(sceneStore.viewStateContainer.mapViewState.keys.first!.description, "->\(firstWrapper!.store.stateId)")
            XCTAssert(!oberver.addErrorCall)
            XCTAssert(!oberver.updateErrorCall)
            XCTAssert(!oberver.removeErrorCall)
            
            autoreleasepool {
                var secondView: NormalView? = NormalView { _ in }
                let host2 = ViewTest.host(secondView!.environment(\.recordViewState, true))
                XCTAssert(oberver.addErrorCall)
                XCTAssert(!oberver.updateErrorCall)
                XCTAssert(!oberver.removeErrorCall)
                secondView = nil
                ViewTest.releaseHost(host2)
            }
            firstWrapper?.store.name = "new"
            XCTAssert(oberver.addErrorCall)
            XCTAssert(oberver.updateErrorCall)
            XCTAssert(!oberver.removeErrorCall)
            
            
            firstView = nil
            ViewTest.releaseHost(host1)
        }
        XCTAssert(oberver.addErrorCall)
        XCTAssert(oberver.updateErrorCall)
        XCTAssert(oberver.removeErrorCall)
        
        cancellable.cancel()
    }
    #endif
}


struct NormalViewState: StorableViewState {
    var name: String = ""
}

var reducerStateReducerCall = false
struct ReducerViewState: StorableViewState, ReducerLoadableState {
    var name: String = ""
    
    static func loadReducers(on store: Store<ReducerViewState>) {
        reducerStateReducerCall = true
    }
}

enum NormalViewAction: Action {
    case changeContent(String)
}

var fullViewStateReducerCall = false
struct FullViewState: FullStorableViewState {
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

struct InitViewState: StorableViewState, InitializableState {
    var name: String = ""
}

var initStateReducerCall = false
struct InitReducerViewState: StorableViewState, ReducerLoadableState, InitializableState {
    var name: String = ""
    
    static func loadReducers(on store: Store<InitReducerViewState>) {
        initStateReducerCall = true
    }
}
