//
//  StoreUtilsTests.swift
//  
//
//  Created by 黄磊 on 2022/6/12.
//

import XCTest
import SwiftUI
import DataFlow
@testable import ViewFlow

final class StoreUtilsTests: XCTestCase {
    
    func testBindingState() {
        let normalStore = Store<NormalViewState>.box(.init())
        let bindingValue = normalStore.binding(of: \.name)
        
        XCTAssertEqual(bindingValue.wrappedValue, "")
        
        let newName = "newName"
        bindingValue.wrappedValue = newName
        XCTAssertEqual(bindingValue.wrappedValue, newName)
        XCTAssertEqual(normalStore.name, newName)
        
        let secondName = "secondName"
        normalStore.name = secondName
        XCTAssertEqual(bindingValue.wrappedValue, secondName)
    }
    
    
    func testBindingStateWithAction() {
        let normalStore = Store<NormalViewState>.box(.init())
        var actionCall = false
        normalStore.register { (state, action: NormalViewAction) in
            actionCall = true
            switch action {
            case .changeContent(let str):
                state.name = str
            }
        }
        let newName = "newName"
        let bindingValue = normalStore.binding(of: \.name) { (newValue, _) in
            return NormalViewAction.changeContent(newName)
        }
        
        XCTAssert(!actionCall)
        
        bindingValue.wrappedValue = newName
        XCTAssertEqual(bindingValue.wrappedValue, newName)
        XCTAssertEqual(normalStore.name, newName)
        XCTAssert(actionCall)
    }
    
    func testBindingStateWithActionOnly() {
        let normalStore = Store<NormalViewState>.box(.init())
        var actionCall = false
        normalStore.register { (state, action: NormalViewAction) in
            actionCall = true
            switch action {
            case .changeContent(let str):
                state.name = str
            }
        }
        let newName = "newName"
        let bindingValue = normalStore.binding(of: \.name, NormalViewAction.changeContent)
        
        XCTAssert(!actionCall)
        
        bindingValue.wrappedValue = newName
        XCTAssertEqual(bindingValue.wrappedValue, newName)
        XCTAssertEqual(normalStore.name, newName)
        XCTAssert(actionCall)
    }
    
    func testBindingStateWithDefaultAction() {
        let normalStore = Store<FullViewState>.box(.init())
        var actionCall = false
        normalStore.registerDefault { (state, action) in
            actionCall = true
            switch action {
            case .changeContent(let str):
                state.name = str
            }
        }
        let newName = "newName"
        let bindingValue = normalStore.bindingDefault(of: \.name) { (newValue, _) in
            return .changeContent(newName)
        }
        
        XCTAssert(!actionCall)
        
        bindingValue.wrappedValue = newName
        XCTAssertEqual(bindingValue.wrappedValue, newName)
        XCTAssertEqual(normalStore.name, newName)
        XCTAssert(actionCall)
    }
    
    func testBindingStateWithDefaultActionOnly() {
        let normalStore = Store<FullViewState>.box(.init())
        var actionCall = false
        normalStore.registerDefault { (state, action) in
            actionCall = true
            switch action {
            case .changeContent(let str):
                state.name = str
            }
        }
        let newName = "newName"
        let bindingValue = normalStore.bindingDefault(of: \.name, NormalViewAction.changeContent)
        
        XCTAssert(!actionCall)
        
        bindingValue.wrappedValue = newName
        XCTAssertEqual(bindingValue.wrappedValue, newName)
        XCTAssertEqual(normalStore.name, newName)
        XCTAssert(actionCall)
    }
}

