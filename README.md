# ViewFlow

ViewFlow 是基于 DataFlow 的 View 层数据绑定模块，为 SwiftUI 提供与 DataFlow 相同的数据存储、数据绑定、事件传递等功能。最终实现界面层的数据流与逻辑层数据流使用相同的交互模式。

ViewFlow 是自定义 RSV(Resource & State & View) 设计模式中 State 层的应用模块，同时也是 View 层的基础模块。负责 State 与 View 的直接绑定和交互。

[![Swift](https://github.com/miejoy/view-flow/actions/workflows/test.yml/badge.svg)](https://github.com/miejoy/view-flow/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/miejoy/view-flow/branch/main/graph/badge.svg)](https://codecov.io/gh/miejoy/view-flow)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/swift-6.2-brightgreen.svg)](https://swift.org)

## 依赖

- iOS 14.0+ / macOS 11+
- Xcode 26.0+
- Swift 6.2+

## 简介

### 该模块包含如下内容:

- StorableState 的扩展协议:
  - SceneSharableState: 当前界面场景的可共享状态
  - VoidSceneSharableState: 可以用空参数初始化的当前界面场景可共享状态
  - SceneWithIdSharableState: 用 sceneId 初始化的界面场景可共享状态
  - FullSceneSharableState: 完整的界面场景可共享状态
  - FullSceneWithIdSharableState: 完整的用 sceneId 初始化的界面场景可共享状态
  - StorableViewState: 界面使用的可存储状态
  - FullStorableViewState: 完整的界面使用的可存储状态

- State 的包装器:
  - SharedState: 对全局可共享状态(SharableState)的包装器，包装的 Store 会存在全局静态变量中，如果是 SceneSharableState，包装的 Store 和 State 都会存储在当前 SceneState 中
  - ViewState: 界面状态(StorableViewState)包装器，包装的 State 回直接存储到当前 SceneState 中
  
- 定义必要的 State:
  - SceneState: 场景状态，用户保存当前场景下的各种数据，包括当前场景的所有 SceneSharedState 和 ViewState 以及所有 SceneSharedState 对应的 Store
  - AllSceneState: 所有场景的状态，暂时非公开。当前状态为 App 共享状态，保存 App 中所有存在的 SceneState，直接依附于 AppState，主要作为 SceneState 和 AppState 关联的桥梁

- View 的扩展协议: 
  - TrackableView: 可追踪的界面协议
  - InitializableView: 可初始化的界面协议
  - VoidInitializableView: 可无需参数初始化的界面协议
  - RoutableView: 可路由的界面协议
  - VoidRoutableView: 可无参数路由的界面协议

- 界面路由
  - ViewRoute: 界面路由标识，每个可路由界面都有一个默认的路由标识，其他的库可以用这个来注册和管理路由界面
  - AnyViewRoute: 抹除初始化类型的界面对应路由标识
  - ViewRouteData: 包含数据的界面路由，这个包含了初始化界面需要的所有内容

### 各种 State 对应关系如下：

```mermaid
flowchart TD
subgraph AppState
end
AppState --> SharedState
subgraph SharedState[SharableState]
OtherSharedState
AllSceneState
AllSceneState --> SceneState
subgraph SceneSharedState[SceneSharableState]
SceneState --> OtherSceneSharedState
end
end
SceneState --> ViewState
subgraph ViewState[StorableViewState]
AllViewState
end

```


## 安装

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

在项目中的 Package.swift 文件添加如下依赖:

```swift
dependencies: [
    .package(url: "https://github.com/miejoy/view-flow.git", from: "0.1.0"),
]
```

## 使用

### SceneSharableState 场景共享状态使用

可共享状态可以在所有界面共享使用

1、定义一个可共享状态

```swift
import ViewFlow

struct NormalSharedState : VoidSceneSharableState {
    var name: String = ""
}
```

2、在界面上使用

```swift
import ViewFlow
import SwiftUI

struct NormalSharedView: View {
    
    @SharedState var normalState: NormalSharedState
    
    var body: some View {
        Text(normalState.name)
    }
}
```

### StorableViewState 界面状态使用

使用 ViewState 包装的时候，如果对应 State 继承 InitializableState 可不用初始化，没有则必须初始化

```swift
import ViewFlow
import SwiftUI

// 普通 ViewState
struct NormalState : StorableViewState {    
    var name: String = ""
}

// 可初始化的 ViewState
struct NormalInitState : StorableViewState, InitializableState {    
    var name: String = ""
}

struct NormalSharedView: View {
    
    @ViewState var normalState: NormalState = NormalState()
    @ViewState var initState: NormalInitState
    
    var body: some View {
        VStack {
            Text(normalState.name)
        }
    }
}
```

### SceneState 场景状态使用

场景状态，目前只提供获取当前显示的所有 TrackableView 的列表

```swift
import ViewFlow
import SwiftUI

struct MainSceneView: View {
    
    @SharedState var sceneState: SceneState
    
    var body: some View {
        ZStack(alignment: .top) {
            ContentView()
            Text(sceneState.arrAppearViewPath.first?.description ?? "unknown")
                .zIndex(1)
        }
    }
}
```

### TrackableView 可追踪界面使用

只要继承了 TrackableView 都可以被追踪，在显示的时候会将自己的 ViewPath 传递给当前 SceneState，子界面也可通过 @Environment(\.viewPath) 获取当前父界面的路径

```swift
import ViewFlow
import SwiftUI

struct ContentView: TrackableView {
    // 这里可以获取当前 View 被使用时所在的 ViewPath
    @Environment(\.viewPath) var viewPath
    var content: some View {
        Text("Hello")
    }
}
```

### RoutableView 可追踪界面使用

只要继承了 RoutableView 就是可以路由的界面，继承 VoidRoutableView 就是可以无参数初始化的可路由界面。
RoutableView 都有一个默认的路由标识，即 defaultRoute，其他的库可以用这个来注册和管理路由界面

```swift
import ViewFlow
import SwiftUI

struct ContentRouteView: VoidRoutableView {
    // 这里可以获取当前 View 被使用时所在的 ViewPath
    @Environment(\.viewPath) var viewPath
    var content: some View {
        Text("Hello")
    }
}
```

## 作者

Raymond.huang: raymond0huang@gmail.com

## License

ViewFlow is available under the MIT license. See the LICENSE file for more info.
