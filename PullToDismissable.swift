//
//  PullToDismissable.swift
//  PullToDismissable
//
//  Created by Ben Guild on 2018/06/20.
//  Copyright © 2018年 Ben Guild. All rights reserved.
//

import UIKit

public protocol PullToDismissable where Self: UIViewController {
    var eligibleViewControllersForPullToDismiss: [UIViewController] { get }
    var isPullToDismissEnabled: Bool { get set }

    var pullToDismissTransition: PullToDismissTransition { get }

    func setupPullToDismiss()
    func setPullToDismissEnabled(_ isEnabled: Bool)
}

extension PullToDismissable where Self: UIViewController, Self: UIViewControllerTransitioningDelegate {
    public var eligibleViewControllersForPullToDismiss: [UIViewController] {
        var viewControllers = [UIViewController]()

        if let navigationController = navigationController {
            viewControllers.append(navigationController)
        }

        viewControllers.append(self)

        return viewControllers
    }

    public var isPullToDismissEnabled: Bool {
        get {
            return isPullToDismissEnabled(on: eligibleViewControllersForPullToDismiss)
        }
        set {
            guard newValue != isPullToDismissEnabled else { return }
            setPullToDismissEnabled(newValue)
        }
    }

    private func isPullToDismissEnabled(on eligibleViewControllers: [UIViewController]) -> Bool {
        return eligibleViewControllers.contains(where: { (viewController) -> Bool in
            viewController.transitioningDelegate === self
        })
    }

    private func tearDownPullToDismiss(on viewController: UIViewController) {
        if viewController.transitioningDelegate === self {
            viewController.transitioningDelegate = nil
        }

        guard viewController.isViewLoaded else { return }

        viewController.view.gestureRecognizers?.forEach {
            guard $0.delegate === pullToDismissTransition else { return }
            viewController.view.removeGestureRecognizer($0)
        }
    }

    private func propagateChanges(to eligibleViewControllers: [UIViewController], isEnabled: Bool) {
        pullToDismissTransition.transitionDelegateObservation?.invalidate()

        eligibleViewControllers.reversed().forEach { viewController in
            if !isEnabled || eligibleViewControllers.first !== viewController {
                tearDownPullToDismiss(on: viewController)
            } else {
                viewController.transitioningDelegate = self

                pullToDismissTransition.transitionDelegateObservation = viewController.observe(
                    \UIViewController.transitioningDelegate,
                    options: [.new]
                ) { [weak self] _, _ in
                    self?.setupPullToDismiss()
                }

                guard viewController.isViewLoaded else { return }

                guard !(viewController.view.gestureRecognizers?.contains(
                    where: { (gestureRecognizer) -> Bool in
                        gestureRecognizer.delegate === pullToDismissTransition
                    }
                ) ?? false) else { return }

                viewController.view.addGestureRecognizer(
                    pullToDismissTransition.additionalGestureRecognizerForTrigger()
                )
            }
        }
    }

    public func setupPullToDismiss() {
        let eligibleViewControllers = eligibleViewControllersForPullToDismiss

        propagateChanges(
            to: eligibleViewControllers,
            isEnabled: isPullToDismissEnabled(on: eligibleViewControllers)
        )
    }

    public func setPullToDismissEnabled(_ isEnabled: Bool) {
        propagateChanges(to: eligibleViewControllersForPullToDismiss, isEnabled: isEnabled)
    }
}
