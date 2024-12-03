//
//  TrackableViewTests.swift
//  
//
//  Created by 黄磊 on 2022/6/12.
//

import XCTest
import SwiftUI
import DataFlow
@testable import ViewFlow

final class TrackableViewTests: XCTestCase {
    
    // 暂时无法测试，后期可能用 ViewInspector 测试
    func testViewAppear() {
        let mainView = MainView()
        let mainBody = mainView.body
        
        let bodyStr = String(describing: mainBody)
        
        XCTAssert(bodyStr.contains("TrackWrapperView"))
        XCTAssert(bodyStr.contains("ContentView"))
    }
}

struct MainView: TrackableView {
    @Environment(\.viewPath) var viewPath
    var content: some View {
        ContentView()
    }
}

struct ContentView: TrackableView {
    @Environment(\.viewPath) var viewPath
    var content: some View {
        Text("Hello")
    }
}


struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

struct MainSceneView: View {
    
    @SharedState var sceneState: SceneState
    // 使用这种方式获取的 store，在 state 更新是不会有通知，因为 Environment 只会影响他的下一级 View 更新
    // @Environment(\.sceneStore) var sceneStore
    
    var body: some View {
        ZStack(alignment: .top) {
            ContentView()
            Text(sceneState.arrAppearViewPath.first?.description ?? "unknown")
                .zIndex(1)
        }
    }
}
