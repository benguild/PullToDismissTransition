//
//  NonProtocolExampleViewController.swift
//  PullToDismissTransition-Example
//
//  Created by Ben Guild on 2018/08/28.
//

import UIKit

class NonProtocolExampleViewController: UIViewController {
    private lazy var pullToDismissTransition = PullToDismissTransition(
        viewController: self,
        transitionType: .scale
    )

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        transitioningDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red

        view.addGestureRecognizer(
            pullToDismissTransition.additionalGestureRecognizerForTrigger()
        )

        let label = UILabel(frame: view.frame.insetBy(dx: 16, dy: 16))
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.numberOfLines = 0
        label.text = "Drag downward on this screen to dismiss! ↓"
        label.textAlignment = .center

        view.addSubview(label)
    }
}

extension NonProtocolExampleViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            return pullToDismissTransition
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning? {
            return pullToDismissTransition
    }
}
