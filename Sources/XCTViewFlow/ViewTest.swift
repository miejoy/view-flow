//
//  ViewTest.swift
//  
//
//  Created by 黄磊 on 2023/3/19.
//

#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

@MainActor
public class ViewTest {
    
    #if os(macOS)
    public static var window: NSWindow = {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.titled, .resizable, .miniaturizable, .closable],
            backing: .buffered,
            defer: false)
        window.contentViewController = RootViewController()
        window.makeKeyAndOrderFront(window)
        window.layoutIfNeeded()
        return window
    }()
    
    public static func host<V: View>(_ view: V, size: CGSize? = nil) -> NSHostingController<V> {
        let parentVC = window.contentViewController!
        let hosting = NSHostingController(rootView: view)
        let size = size ?? parentVC.view.bounds.size
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.view.frame = parentVC.view.bounds
        parentVC.addChild(hosting)
        parentVC.view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: parentVC.view.leadingAnchor),
            hosting.view.topAnchor.constraint(equalTo: parentVC.view.topAnchor),
            hosting.view.widthAnchor.constraint(equalToConstant: size.width).priority(.defaultHigh),
            hosting.view.heightAnchor.constraint(equalToConstant: size.height).priority(.defaultHigh)
        ])
        window.layoutIfNeeded()
        return hosting
    }
    
    public static func refreshHost<V: View>(_ hosting: NSHostingController<V>) {
        hosting.view.needsLayout = true
        window.layoutIfNeeded()
    }
    
    public static func releaseHost<V: View>(_ hosting: NSHostingController<V>) {
        hosting.view.removeFromSuperview()
        hosting.removeFromParent()
    }
    
    #elseif os(iOS) || os(tvOS)
    public static var window: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.rootViewController?.view.translatesAutoresizingMaskIntoConstraints = false
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        return window
    }()
        
    public static func host<V: View>(_ view: V, size: CGSize? = nil) -> UIHostingController<V> {
        let parentVC = window.rootViewController!
        let hosting = UIHostingController(rootView: view)
        let size = size ?? parentVC.view.bounds.size
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.view.frame = parentVC.view.bounds
        hosting.willMove(toParent: parentVC)
        parentVC.addChild(hosting)
        parentVC.view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: parentVC.view.leadingAnchor),
            hosting.view.topAnchor.constraint(equalTo: parentVC.view.topAnchor),
            hosting.view.widthAnchor.constraint(equalToConstant: size.width).priority(.defaultHigh),
            hosting.view.heightAnchor.constraint(equalToConstant: size.height).priority(.defaultHigh)
        ])
        hosting.didMove(toParent: parentVC)
        window.layoutIfNeeded()
        return hosting
    }
    
    public static func refreshHost<V: View>(_ hosting: UIHostingController<V>) {
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }
    
    public static func releaseHost<V: View>(_ hosting: UIHostingController<V>) {
        hosting.willMove(toParent: nil)
        hosting.view.removeFromSuperview()
        hosting.removeFromParent()
        hosting.didMove(toParent: nil)
    }
    #endif
}

#if !os(watchOS)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
private extension NSLayoutConstraint {
    #if os(macOS)
    func priority(_ value: NSLayoutConstraint.Priority) -> NSLayoutConstraint {
        priority = value
        return self
    }
    #else
    func priority(_ value: UILayoutPriority) -> NSLayoutConstraint {
        priority = value
        return self
    }
    #endif
}
#endif

#if os(macOS)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
private class RootViewController: NSViewController {

    override func loadView() {
        view = NSView()
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

#endif
