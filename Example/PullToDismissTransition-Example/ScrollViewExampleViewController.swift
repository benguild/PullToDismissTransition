//
//  ScrollViewExampleViewController.swift
//  PullToDismissTransition-Example
//
//  Created by Ben Guild on 2018/08/29.
//

import UIKit

class ScrollViewExampleViewController: UIViewController, PullToDismissable {
    struct Const {
        static let inset: CGFloat = 16
    }

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

    override func loadView() {
        let scrollView = UIScrollView(frame: UIScreen.main.bounds)
        scrollView.alwaysBounceVertical = true

        view = scrollView
        pullToDismissTransition.monitorActiveScrollView(scrollView: scrollView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .orange

        for labelIndex in 0...2 {
            let label = UILabel(frame: view.frame.insetBy(
                dx: Const.inset,
                dy: Const.inset
            ).offsetBy(
                dx: 0,
                dy: view.frame.height * CGFloat(labelIndex))
            )
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            label.numberOfLines = 0
            label.text = "Drag downward on this screen to dismiss! ↓"
            label.textAlignment = .center

            view.addSubview(label)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        (view as? UIScrollView)?.contentSize = CGSize(
            width: view.bounds.width,
            height: view.subviews.reduce(CGFloat(0), { return max($1.frame.maxY + Const.inset, $0) }
        ))
    }
}

extension ScrollViewExampleViewController: UIViewControllerTransitioningDelegate {
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
