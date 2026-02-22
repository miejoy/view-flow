//
//  SceneSharedStateTests.swift
//  
//
//  Created by 黄磊 on 2022/6/11.
//

import XCTest
import SwiftUI
@testable import DataFlow
@testable import ViewFlow
import XCTViewFlow

@MainActor
final class SceneSharedStateTests: XCTestCase {
    
    static var semaphore = DispatchSemaphore(value: 1)
    
    func resetDefaultSceneState() {
        let sceneStore = Store<SceneState>.shared
        sceneStore.subStates = [:]
        sceneStore.arrAppearViewPath = []
        sceneStore.viewStateContainer.mapViewState = [:]
        sceneStore.sharedStoreContainer.mapExistSharedStore = [:]
        sceneStore.mapCancellable.removeAll()
    }
    
    func testSceneSharedState() {
        resetDefaultSceneState()
        let sceneId: SceneId = .custom(#function)
        let sceneStore = Store<SceneState>.shared(on: sceneId)
        XCTAssert(sceneStore.sharedStoreContainer.mapExistSharedStore.isEmpty)
        XCTAssert(sceneStore.state.subStates.isEmpty)
        
        let normalSharedStateWrapper = SharedState<NormalSharedState>()
        normalSharedStateWrapper.storage.configStoreIfNeed(sceneId)
        XCTAssertEqual(sceneStore.sharedStoreContainer.mapExistSharedStore.count, 1)
        XCTAssert(sceneStore.state.subStates[normalSharedStateWrapper.wrappedValue.stateId] != nil)
        
        let secondSharedStateWrapper = SharedState<NormalSharedState>()
        secondSharedStateWrapper.storage.configStoreIfNeed(sceneId)
        XCTAssertEqual(sceneStore.sharedStoreContainer.mapExistSharedStore.count, 1)
        
        XCTAssertEqual(secondSharedStateWrapper.wrappedValue.name, "")
        let newName = "new"
        normalSharedStateWrapper.wrappedValue.name = newName
        XCTAssertEqual(secondSharedStateWrapper.wrappedValue.name, newName)
    }
    
    func testStateSharedStore() {
        
        resetDefaultSceneState()
        let sceneStore = SceneState.sharedStore
        XCTAssert(sceneStore.state.subStates.isEmpty)
        
        let oneSharedStore = OneSharedState.sharedStore
        XCTAssert(sceneStore.state.subStates[oneSharedStore.stateId] != nil)
        
        let secondSharedStateWrapper = OneSharedState.sharedStore(on: .main)
        
        XCTAssertEqual(secondSharedStateWrapper.name, "")
        let newName = "new" + #function
        oneSharedStore.name = newName
        XCTAssertEqual(secondSharedStateWrapper.name, newName)
    }
    
    func testSceneStateFullSharable() {
        resetDefaultSceneState()
        let sceneId: SceneId = .custom(#function)
        let sceneStore = SceneState.sharedStore(on: sceneId)
        XCTAssert(sceneStore.sharedStoreContainer.mapExistSharedStore.isEmpty)
        XCTAssert(sceneStore.state.subStates.isEmpty)
        
        sharedReducerIsLoad = false
        SharedState<FullSharedState>().storage.configStoreIfNeed(sceneId)
        XCTAssert(sharedReducerIsLoad)
    }
    
    func testSceneSharedStateSharedInSameScene() {
        resetDefaultSceneState()
        let sceneId: SceneId = .custom(#function)
        let sceneStore = SceneState.sharedStore(on: sceneId)
        XCTAssert(sceneStore.sharedStoreContainer.mapExistSharedStore.isEmpty)
        XCTAssert(sceneStore.state.subStates.isEmpty)
        
        let normalSharedStateWrapper = SharedState<NormalSharedState>()
        let secondSharedStateWrapper = SharedState<NormalSharedState>()
        normalSharedStateWrapper.storage.configStoreIfNeed(sceneId)
        secondSharedStateWrapper.storage.configStoreIfNeed(sceneId)
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
        let sceneId: SceneId = .custom(#function)
        let sceneStore = SceneState.sharedStore(on: sceneId)
        XCTAssert(sceneStore.sharedStoreContainer.mapExistSharedStore.isEmpty)
        XCTAssert(sceneStore.state.subStates.isEmpty)
        let normalSharedStateWrapper = SharedState<NormalSharedState>()
        normalSharedStateWrapper.storage.configStoreIfNeed(sceneId)
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
        let otherSharedStore = otherSceneStore.sharedStoreContainer.mapExistSharedStore[ObjectIdentifier(NormalSharedState.self)]!.store as! Store<NormalSharedState>
        
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
        let sceneId: SceneId = .custom(#function)
        let sceneStore = SceneState.sharedStore(on: sceneId)
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
        
        let host = ViewTest.host(view.environment(\.sceneId, sceneId))
        
        // 确定共享状态已被添加
        XCTAssertNotNil(normalSharedStateWrapper)
        XCTAssertEqual(sceneStore.sharedStoreContainer.mapExistSharedStore.count, 2)
        XCTAssertEqual(sceneStore.state.subStates.count, 2)
    
        // 保存在 sceneState 中的 store，和 view 中的 store 是一致的
        let normalSharedStore = sceneStore.getSharedStore(of: NormalSharedState.self)
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
        final class Oberver: ViewMonitorObserver, @unchecked Sendable {
            var duplicateFatalErrorCall = false
            func receiveViewEvent(_ event: ViewEvent) {
                if case .fatalError(let message) = event,
                    message == ("Attach SceneSharableState[DuplicateSharedState] to UpState[SceneState] " +
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
    
    func testSaveSceneIdSharedStateOnMain() {
        XCTAssertEqual(SaveSceneSharedStata().sceneId, .main)
        XCTAssertEqual(SaveSceneSharedStata.sharedStore.sceneId, .main)
    }
    
    func testCreateSceneSharedStoreOnMultiThread() {
        resetDefaultSceneState()
        s_mapSharedStore.removeAll()
        
        var expectations: [XCTestExpectation] = []
        nonisolated(unsafe) var count: Int = 0
        
        (0..<5).forEach { _ in
            let expectation = expectation(description: "This should complete")
            expectations.append(expectation)
            DispatchQueue.global().async {
                if (s_mapSharedStore[ObjectIdentifier(AllSceneState.self)] == nil) {
                    sleep(1)
                    
                    _ = Store<MultiThreadSharedState>.shared
                    
                    XCTAssertNotNil(s_mapSharedStore[ObjectIdentifier(AllSceneState.self)])
                    let arrSceneStore = s_mapSharedStore[ObjectIdentifier(AllSceneState.self)] as! Store<AllSceneState>
                    let sceneStore = arrSceneStore[.allSceneStorage].sceneIdToStoreMap[.main]!
                    let multiStreadStore = sceneStore.sharedStoreContainer.mapExistSharedStore[ObjectIdentifier(MultiThreadSharedState.self)]
                    XCTAssertNotNil(multiStreadStore)
                    XCTAssertEqual(s_mapSharedStore.count, 2)
                    XCTAssertEqual(arrSceneStore[.allSceneStorage].sceneIdToStoreMap.count, 1)
                    XCTAssertEqual(sceneStore.sharedStoreContainer.mapExistSharedStore.count, 1)
                    count += 1
                }
                expectation.fulfill()
            }
        }
        
        XCTAssertNil(s_mapSharedStore[ObjectIdentifier(AllSceneState.self)])
        
        wait(for: expectations, timeout: 5)
        
        XCTAssertNotNil(s_mapSharedStore[ObjectIdentifier(AllSceneState.self)])
        XCTAssertTrue(count >= 2) // 至少触发两次
    }
    
    func testCreateSceneSharedStoreOnOtherSceneSharedStoreCreation() {
        s_mapSharedStore.removeAll()
        
        _ = Store<MultiThreadNestSharedState>.shared
        
        
        XCTAssertNotNil(s_mapSharedStore[ObjectIdentifier(AllSceneState.self)])
        XCTAssertEqual(s_mapSharedStore.count, 2)
        
        let allSceneStore = Store<AllSceneState>.shared
        let mainSceneStore = allSceneStore[.allSceneStorage].sceneIdToStoreMap[.main]!
        
        XCTAssertNotNil(mainSceneStore.sharedStoreContainer.mapExistSharedStore[ObjectIdentifier(MultiThreadNestSharedState.self)])
        XCTAssertNotNil(mainSceneStore.sharedStoreContainer.mapExistSharedStore[ObjectIdentifier(MultiThreadSubSharedState.self)])
        
        XCTAssertEqual(mainSceneStore.sharedStoreContainer.mapExistSharedStore.count, 2)
    }
}

struct NormalSharedState: VoidSceneSharableState {
    var name: String = ""
}

// 只有一个地方使用，其他地方不要使用
struct OneSharedState: VoidSceneSharableState {
    var name: String = ""
}

struct DuplicateSharedState: VoidSceneSharableState {
    var name: String = ""
    
    var stateId: String = "NormalSharedState"
}

enum NormalAction: Action {
    case userClick
}

@MainActor
var sharedReducerIsLoad = false
struct FullSharedState: FullSceneSharableState {
    typealias BindAction = NormalAction
    var name: String = ""
    
    @MainActor
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


@MainActor
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

struct SaveSceneSharedStata: SceneWithIdSharableState {
    
    let sceneId: SceneId
    
    init(sceneId: SceneId) {
        self.sceneId = sceneId
    }
}


struct MultiThreadSharedState: VoidSceneSharableState {
    
    var name: String = ""
}

struct MultiThreadNestSharedState : VoidSceneSharableState {
    var name: String = ""
    
    init() {
        self.name = ""
        MainActor.assumeIsolated {
            _ = Store<MultiThreadSubSharedState>.shared
        }
    }
}

struct MultiThreadSubSharedState : VoidSceneSharableState {
    var name: String = ""
}

extension SceneState {
    @MainActor
    static func sharedStore(_ method:  String = #function) -> Store<SceneState> {
        SceneState.sharedStore(on: .custom(method))
    }
}
