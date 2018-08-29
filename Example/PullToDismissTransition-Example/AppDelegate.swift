//
//  AppDelegate.swift
//  PullToDismissTransition-Example
//
//  Created by Ben Guild on 2018/08/28.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .white

        let stackView = UIStackView(frame: viewController.view.frame)
        stackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        stackView.axis = .vertical
        stackView.distribution = .fillEqually

        let nonProtocolExampleButton = UIButton()
        nonProtocolExampleButton.addTarget(self, action: #selector(nonProtocolExampleTapped), for: .touchUpInside)
        nonProtocolExampleButton.setTitle("Non-protocol example… ☆", for: .normal)
        nonProtocolExampleButton.setTitleColor(viewController.view.tintColor, for: .normal)
        nonProtocolExampleButton.setTitleColor(.gray, for: .highlighted)

        let protocolExampleButton = UIButton()
        protocolExampleButton.addTarget(self, action: #selector(pullToDismissableExampleTapped), for: .touchUpInside)
        protocolExampleButton.setTitle("`PullToDismissable` protocol… ★", for: .normal)
        protocolExampleButton.setTitleColor(viewController.view.tintColor, for: .normal)
        protocolExampleButton.setTitleColor(.gray, for: .highlighted)

        let scrollViewExampleButton = UIButton()
        scrollViewExampleButton.addTarget(self, action: #selector(scrollViewExampleTapped), for: .touchUpInside)
        scrollViewExampleButton.setTitle("`UIScrollView` example… ☆", for: .normal)
        scrollViewExampleButton.setTitleColor(viewController.view.tintColor, for: .normal)
        scrollViewExampleButton.setTitleColor(.gray, for: .highlighted)

        stackView.addArrangedSubview(protocolExampleButton)
        stackView.addArrangedSubview(nonProtocolExampleButton)
        stackView.addArrangedSubview(scrollViewExampleButton)

        viewController.view.addSubview(stackView)

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = viewController

        window?.makeKeyAndVisible()
        return true
    }

    private func presentExample(viewController: UIViewController) {
        viewController.modalPresentationCapturesStatusBarAppearance = true
        viewController.modalPresentationStyle = .overFullScreen

        window?.rootViewController?.present(viewController, animated: true, completion: nil)
    }

    @objc private func nonProtocolExampleTapped(_ sender: AnyObject) {
        presentExample(viewController: NonProtocolExampleViewController())
    }

    @objc private func pullToDismissableExampleTapped(_ sender: AnyObject) {
        var viewController = ProtocolExampleViewController()
        viewController.isPullToDismissEnabled = true

        presentExample(viewController: viewController)
    }

    @objc private func scrollViewExampleTapped(_ sender: AnyObject) {
        var viewController = ScrollViewExampleViewController()
        viewController.isPullToDismissEnabled = true

        presentExample(viewController: viewController)
    }
}
