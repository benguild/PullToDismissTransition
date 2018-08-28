//
//  ProtocolExampleViewController.swift
//  PullToDismissTransition-Example
//
//  Created by Ben Guild on 2018/08/28.
//

import UIKit

class ProtocolExampleViewController: UIViewController, PullToDismissable {
    lazy var pullToDismissTransition: PullToDismissTransition = PullToDismissTransition(viewController: self)

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        setupPullToDismiss()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupPullToDismiss()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green

        let label = UILabel(frame: view.frame.insetBy(dx: 16, dy: 16))
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.numberOfLines = 0
        label.text = "Drag downward on this screen to dismiss! ↓"
        label.textAlignment = .center

        view.addSubview(label)
    }
}

extension ProtocolExampleViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            guard isPullToDismissEnabled else { return nil }
            return pullToDismissTransition
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning? {
            guard isPullToDismissEnabled else { return nil }
            return pullToDismissTransition
    }
}
