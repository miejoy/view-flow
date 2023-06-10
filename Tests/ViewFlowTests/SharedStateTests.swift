//
//  SharedStateTests.swift
//  
//
//  Created by 黄磊 on 2023/6/4.
//

import XCTest
import SwiftUI
@testable import DataFlow
@testable import ViewFlow

class SharedStateTests: XCTestCase {
    func testNormalSharedView() {
        
        s_mapSharedStore.removeAll()
        let view = NormalSharedView()
        XCTAssertEqual(view.normalState.name, "")
        XCTAssertEqual(Store<TextSharedState>.shared.name, "")
        
        _ = view.body
        let content = "content"
        view.normalState.name = content
        XCTAssertEqual(view.normalState.name, content)
        XCTAssertEqual(Store<TextSharedState>.shared.name, content)
    }
    
    func testShareStore() {
        s_mapSharedStore.removeAll()
        let view = SharedStateTestView()
        XCTAssertEqual(view.testState.content, "")
        XCTAssertEqual(Store<TestState>.shared.content, "")
        
        _ = view.body
        let content = "content"
        view.$testState.send(action: .changeContent(content))
        XCTAssertEqual(view.testState.content, content)
        XCTAssertEqual(Store<TestState>.shared.content, content)
    }
}

enum TestAction: Action {
    case changeContent(String)
}

struct TestState: SharableState, ReducerLoadableState, ActionBindable {
    typealias BindAction = TestAction
    
    var content: String = ""
    
    static func loadReducers(on store: Store<TestState>) {
        store.register { (state, action: TestAction) in
            switch action {
            case .changeContent(let string):
                state.content = string
            }
        }
    }
}

struct TextSharedState : SharableState {
    var name: String = ""
}

struct SharedStateTestView: View {
    
    @SharedState var testState: TestState
    
    var body: some View {
        VStack {
            Text(testState.content)
            Button("Random Text") {
                $testState.send(action: .changeContent(String(Int.random(in: 100...999))))
            }
        }
    }
}

struct NormalSharedView: View {
    
    @SharedState var normalState: TextSharedState
    
    var body: some View {
        VStack {
            Text(normalState.name)
            Button("Button") {
                normalState.name = String(Int.random(in: 100...999))
            }
        }
    }
}
