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
import XCTViewFlow

final class SceneSharedStateTests: XCTestCase {
    
    func resetDefaultSceneState() {
        let sceneStore = Store<SceneState>.shared
        sceneStore.subStates = [:]
        sceneStore.arrAppearViewPath = []
        sceneStore.viewStateContainer.mapViewState = [:]
        sceneStore.storage.storage = [:]
    }
    
    func testSceneSharedState() {
        resetDefaultSceneState()
        let sceneStore = Store<SceneState>.shared
        XCTAssert(sceneStore.sharedStoreContainer.mapExistSharedStore.isEmpty)
        XCTAssert(sceneStore.state.subStates.isEmpty)
        
        let normalSharedStateWrapper = SharedState<NormalSharedState>()
        normalSharedStateWrapper.storage.configStoreIfNeed(.main)
        XCTAssertEqual(sceneStore.sharedStoreContainer.mapExistSharedStore.count, 1)
        XCTAssert(sceneStore.state.subStates[normalSharedStateWrapper.wrappedValue.stateId] != nil)
        
        let secondSharedStateWrapper = SharedState<NormalSharedState>()
        secondSharedStateWrapper.storage.configStoreIfNeed(.main)
        XCTAssertEqual(sceneStore.sharedStoreContainer.mapExistSharedStore.count, 1)
        
        XCTAssertEqual(secondSharedStateWrapper.wrappedValue.name, "")
        let newName = "new"
        normalSharedStateWrapper.wrappedValue.name = newName
        XCTAssertEqual(secondSharedStateWrapper.wrappedValue.name, newName)
    }
    
    func testSceneStateFullSharable() {
        resetDefaultSceneState()
        let sceneStore = Store<SceneState>.shared
        XCTAssert(sceneStore.sharedStoreContainer.mapExistSharedStore.isEmpty)
        XCTAssert(sceneStore.state.subStates.isEmpty)
        
        sharedReducerIsLoad = false
        SharedState<FullSharedState>().storage.configStoreIfNeed(.main)
        XCTAssert(sharedReducerIsLoad)
    }
    
    func testSceneSharedStateSharedInSameScene() {
        resetDefaultSceneState()
        let sceneStore = Store<SceneState>.shared
        XCTAssert(sceneStore.sharedStoreContainer.mapExistSharedStore.isEmpty)
        XCTAssert(sceneStore.state.subStates.isEmpty)
        
        let normalSharedStateWrapper = SharedState<NormalSharedState>()
        let secondSharedStateWrapper = SharedState<NormalSharedState>()
        normalSharedStateWrapper.storage.configStoreIfNeed(.main)
        secondSharedStateWrapper.storage.configStoreIfNeed(.main)
        XCTAssertEqual(sceneStore.sharedStoreContainer.mapExistSharedStore.count, 1)
        
        XCTAssertEqual(secondSharedStateWrapper.wrappedValue.name, "")
        let newName = "new"
        normalSharedStateWrapper.wrappedValue.name = newName
        XCTAssertEqual(secondSharedStateWrapper.wrappedValue.name, newName)
        XCTAssertEqual((sceneStore.subStates[normalSharedStateWrapper.wrappedValue.stateId] as! NormalSharedState).name, newName)
        XCTAssertEqual((sceneStore.subStates[secondSharedStateWrapper.wrappedValue.stateId] as! NormalSharedState).name, newName)
    }
    
    func testSceneSharedStateUseInView() {
        resetDefaultSceneState()
        let sceneStore = Store<SceneState>.shared
        XCTAssert(sceneStore.sharedStoreContainer.mapExistSharedStore.isEmpty)
        XCTAssert(sceneStore.state.subStates.isEmpty)
        let normalSharedStateWrapper = SharedState<NormalSharedState>()
        normalSharedStateWrapper.storage.configStoreIfNeed(.main)
        let view = NormalView()
        
        // 另一个场景的 view，主要验证他们互不影响
        let otherSceneId = SceneId.custom("Other")
        let otherSceneStore = Store<SceneState>.shared(on: otherSceneId)
        otherSceneStore.sharedStoreContainer.mapExistSharedStore.removeAll()
        otherSceneStore.state.subStates.removeAll()
        let otherView = NormalView()
        let otherSharedStateWrapper = otherView.sceneSharedStateWrapper()
        let otherSceneView = otherView.environment(\.sceneId, .custom("Other"))
        
        let host = ViewTest.host(view)
        let otherHost = ViewTest.host(otherSceneView)
        
        XCTAssertEqual(otherSceneStore.sharedStoreContainer.mapExistSharedStore.count, 1)
        XCTAssertEqual(otherSceneStore.state.subStates.count, 1)
        let otherSharedStore = otherSceneStore.sharedStoreContainer.mapExistSharedStore[ObjectIdentifier(NormalSharedState.self)]!.value as! Store<NormalSharedState>
        
        XCTAssertEqual(normalSharedStateWrapper.wrappedValue.name, "")
        XCTAssertEqual(view.normalSharedState.name, "")
        XCTAssertEqual(otherSharedStateWrapper.wrappedValue.name, "")
        XCTAssertEqual(otherSharedStore.name, "")

        let newName = "newName"
        view.normalSharedState.name = newName
        XCTAssertEqual(view.normalSharedState.name, newName)
        XCTAssertEqual(view.$normalSharedState.name, newName)
        XCTAssertEqual(otherSharedStateWrapper.wrappedValue.name, "")
        XCTAssertEqual(otherSharedStore.name, "")
        
        let otherNewName = "otherNewName"
        otherSharedStateWrapper.wrappedValue.name = otherNewName
        XCTAssertEqual(view.normalSharedState.name, newName)
        XCTAssertEqual(view.$normalSharedState.name, newName)
        XCTAssertEqual(otherSharedStateWrapper.wrappedValue.name, otherNewName)
        XCTAssertEqual(otherSharedStore.name, otherNewName)
        
        ViewTest.releaseHost(host)
        ViewTest.releaseHost(otherHost)
    }
    
    func testSceneSharedStateUseInViewWithRefresh() {
        resetDefaultSceneState()
        let sceneStore = Store<SceneState>.shared
        XCTAssert(sceneStore.sharedStoreContainer.mapExistSharedStore.isEmpty)
        XCTAssert(sceneStore.state.subStates.isEmpty)
        var normalSharedStateWrapper : SharedState<NormalSharedState>? = nil
        var newWrapper : SharedState<NormalSharedState>? = nil

        var secondInitCall = false
        let view = RefreshContainSharedView {
            if let oldWrapper = normalSharedStateWrapper {
                secondInitCall = true
                XCTAssertTrue(oldWrapper.storage !== $0.storage)
                newWrapper = $0
            } else {
                normalSharedStateWrapper = $0
            }
        }
        let containStateWrapper = view.stateWrapper()
        
        let host = ViewTest.host(view)
        
        // 确定共享状态已被添加
        XCTAssertNotNil(normalSharedStateWrapper)
        XCTAssertEqual(sceneStore.sharedStoreContainer.mapExistSharedStore.count, 2)
        XCTAssertEqual(sceneStore.state.subStates.count, 2)
    
        // 保存在 sceneState 中的 store，和 view 中的 store 是一致的
        let normalSharedStore = sceneStore.state.getSharedStore(of: NormalSharedState.self)
        XCTAssertTrue(normalSharedStore === normalSharedStateWrapper!.storage.store)
    
        // 默认值是空
        XCTAssertEqual(normalSharedStateWrapper?.wrappedValue.name, "")
       
        // 在外层界面刷新时，确保 store 还是原来的 store
        refreshShagedGetCall = false

        // 确保直接调用不会刷新
        ViewTest.refreshHost(host)
        XCTAssertEqual(refreshShagedGetCall, false)
        
        // 开始变更后刷新
        containStateWrapper.wrappedValue.refreshTrigger.toggle()
        ViewTest.refreshHost(host)
        
        // 确认 RefreshNormalView 重新创建
        XCTAssertEqual(refreshShagedGetCall, true)
        XCTAssertEqual(secondInitCall, true)
        
        // 重建后 store 还是同一个
        XCTAssertTrue(normalSharedStateWrapper!.storage.store === newWrapper!.storage.store)
        
        ViewTest.releaseHost(host)
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
        
        SharedState<NormalSharedState>().storage.configStoreIfNeed(.main)
        XCTAssert(!oberver.duplicateFatalErrorCall)
        
        SharedState<DuplicateSharedState>().storage.configStoreIfNeed(.main)
        XCTAssert(oberver.duplicateFatalErrorCall)
        
        cancellable.cancel()
    }
    
    func testSaveSceneIdSharedState() {
        resetDefaultSceneState()
        
        struct SaveSceneIdView: View {
            
            @SharedState var state: SaveSceneSharedStata
            var callback: (SharedStoreStorage<SaveSceneSharedStata>) -> Void
            
            var body: some View {
                callback(_state.storage)
                return Text("text")
            }
        }
        
        let sceneId: SceneId = .custom("TestSaveScene")
        var stateWrapper: SharedStoreStorage<SaveSceneSharedStata>? = nil
        
        let view = SaveSceneIdView {
            stateWrapper = $0
        }.environment(\.sceneId, sceneId)
        
        let host = ViewTest.host(view)
        
        XCTAssertNotNil(stateWrapper)
        XCTAssertEqual(stateWrapper?.store?.state.sceneId, sceneId)
        
        ViewTest.refreshHost(host)
    }
}

struct NormalSharedState: VoidSceneSharableState {
    var name: String = ""
}

struct DuplicateSharedState: VoidSceneSharableState {
    var name: String = ""
    
    var stateId: String = "NormalSharedState"
}

enum NormalAction: Action {
    case userClick
}

var sharedReducerIsLoad = false
struct FullSharedState: FullSceneSharableState {
    typealias BindAction = NormalAction
    var name: String = ""
    
    static func loadReducers(on store: Store<FullSharedState>) {
        sharedReducerIsLoad = true
    }
}

struct NormalView: View {
    
    @SharedState var normalSharedState: NormalSharedState
    
    var body: some View {
        Text("Hello")
    }
    
    func sceneSharedStateWrapper() -> SharedState<NormalSharedState> {
        _normalSharedState
    }
}

struct RefreshNormalSharedView: View {
    
    @SharedState var normalSharedState: NormalSharedState
    
    var block: (SharedState<NormalSharedState>) -> Void
    
    init(block: @escaping (SharedState<NormalSharedState>) -> Void) {
        self.block = block
        self.block(_normalSharedState)
    }
    
    var body: some View {
        return Text(normalSharedState.name)
    }

    func sceneSharedStateWrapper() -> SharedState<NormalSharedState> {
        _normalSharedState
    }
}


var refreshShagedGetCall = false
struct RefreshContainSharedView: View {
    
    @SharedState var state: ContainSharedState
    var block: (SharedState<NormalSharedState>) -> Void
    
    var body: some View {
        refreshShagedGetCall = true
        return ZStack {
            RefreshNormalSharedView(block: block)
        }
    }
    
    func stateWrapper() -> SharedState<ContainSharedState> {
        _state
    }
}

struct ContainSharedState: VoidSceneSharableState {
    var refreshTrigger: Bool = false
}

struct SaveSceneSharedStata: SceneSharableState {
    
    let sceneId: SceneId
    
    init() {
        self.init(sceneId: .main)
    }
    
    init(sceneId: SceneId) {
        self.sceneId = sceneId
    }
}
