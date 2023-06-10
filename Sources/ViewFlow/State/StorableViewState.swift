//
//  StorableViewState.swift
//  
//
//  Created by 黄磊 on 2023/6/10.
//  可存储的界面状态

import DataFlow

/// 可存储的界面状态
public protocol StorableViewState: AttachableState where UpState == SceneState {}
public protocol FullStorableViewState: StorableViewState, ReducerLoadableState, ActionBindable {}
