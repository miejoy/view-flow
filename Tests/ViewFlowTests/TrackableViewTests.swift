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

        XCTAssert(((mainBody as? TrackWrapperView<ContentView>) != nil))
        
        let contentWrapperView = mainBody as! TrackWrapperView<ContentView>
        print(type(of: contentWrapperView.body))
        let contentView = contentWrapperView.content
        let contentBody = contentView.body
        XCTAssert(((contentBody as? TrackWrapperView<Text>) != nil))
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

//struct MainView_Preview: PreviewProvider {
//    static var previews: some View {
//        MainView()
//    }
//}

struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

struct MainSceneView: View {
    
    @SceneSharedState var sceneState: SceneState
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
