//
//  PullToDismissTransition.swift
//  PullToDismissTransition
//
//  Created by Ben Guild on 2018/06/14.
//  Copyright © 2018年 Ben Guild. All rights reserved.
//

import UIKit

protocol PullToDismissTransitionDelegate: class {
    func canBeginPullToDismiss(on dismissingViewController: UIViewController) -> Bool

    func beginPullToDismiss(on dismissingViewController: UIViewController)
    func didCompletePullToDismissAttempt(on dismissingViewController: UIViewController, finished: Bool)
}
extension PullToDismissTransitionDelegate {
    func canBeginPullToDismiss(on dismissingViewController: UIViewController) -> Bool {
        return true
    }

    func beginPullToDismiss(on dismissingViewController: UIViewController) {}
    func didCompletePullToDismissAttempt(on dismissingViewController: UIViewController, finished: Bool) {}
}

class PullToDismissTransition: UIPercentDrivenInteractiveTransition {
    private static let dimmingPeakAlpha: CGFloat = 0.87
    private static let minimumTranslationYForDismiss: CGFloat = 87
    private static let transitionDurationDrag: TimeInterval = 0.87
    private static let transitionDurationInstant: TimeInterval = 0.3
    private static let transitionReEnableTimeoutAfterScroll: TimeInterval = 0.72
    private static let translationThreshold: CGFloat = 0.5
    private static let velocityBeginThreshold: CGFloat = 10
    private static let velocityFinishThreshold: CGFloat = 1280

    let viewController: UIViewController

    weak var delegate: PullToDismissTransitionDelegate?
    private var didRequestScrollViewBounceDisable = false

    private weak var dimmingView: UIView?
    private var transitionIsActiveFromTranslationPoint: CGPoint?

    private weak var monitoredScrollView: UIScrollView?
    private var recentScrollIsBlockingTransition = false
    private var scrollInitiateCount: Int = 0

    private var mostRecentActiveGestureTranslation: CGPoint?

    deinit {
        monitoredScrollView?.removeObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset))
    }

    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
    }

    func additionalPanGestureRecognizerForTrigger() -> UIPanGestureRecognizer {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        panGestureRecognizer.delegate = self

        return panGestureRecognizer
    }

    func monitorActiveScrollView(scrollView: UIScrollView) {
        if let monitoredScrollView = monitoredScrollView {
            monitoredScrollView.removeObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset))
        }

        monitoredScrollView = scrollView
        scrollView.addObserver(
            self,
            forKeyPath: #keyPath(UIScrollView.contentOffset),
            options: [.initial, .new],
            context: nil
        )
    }

    override func observeValue(
        forKeyPath keyPath: String?, of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let monitoredScrollView = monitoredScrollView else { return }
        guard (object as? UIScrollView) === monitoredScrollView else { return }

        let shouldScrollViewBounceBeDisabled = (mostRecentActiveGestureTranslation?.y ?? 0) > 0
        guard shouldScrollViewBounceBeDisabled != didRequestScrollViewBounceDisable else { return }

        didRequestScrollViewBounceDisable = shouldScrollViewBounceBeDisabled

        if monitoredScrollView.bounces != !shouldScrollViewBounceBeDisabled {
            monitoredScrollView.bounces = !shouldScrollViewBounceBeDisabled
        }

        guard monitoredScrollView.contentOffset.y > monitoredScrollView.bounds.size.height else { return }

        recentScrollIsBlockingTransition = true
        scrollInitiateCount += 1

        let localCopyOfScrollInitiateCount = scrollInitiateCount

        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + PullToDismissTransition.transitionReEnableTimeoutAfterScroll
        ) { [weak self] in
            guard self?.scrollInitiateCount == localCopyOfScrollInitiateCount  else { return }
            self?.recentScrollIsBlockingTransition = false
        }
    }

    @objc private func didPan(sender: Any?) {
        guard let panGestureRecognizer = sender as? UIPanGestureRecognizer else { return }
        guard let viewForPan = panGestureRecognizer.view else { return }

        let translation = panGestureRecognizer.translation(in: viewForPan)
        let velocity = panGestureRecognizer.velocity(in: viewForPan)

        if panGestureRecognizer.state == .began || panGestureRecognizer.state == .changed {
            mostRecentActiveGestureTranslation = translation

            if let transitionIsActiveFromTranslationPoint = transitionIsActiveFromTranslationPoint {
                update(min(1, max(
                    0,
                    (translation.y - transitionIsActiveFromTranslationPoint.y) / max(1, viewForPan.bounds.size.height)
                )))
            } else if
                    !recentScrollIsBlockingTransition,
                    velocity.y > PullToDismissTransition.velocityBeginThreshold &&
                    velocity.y > fabs(velocity.x) &&
                    delegate?.canBeginPullToDismiss(on: viewController) ?? true {
                transitionIsActiveFromTranslationPoint = translation
                delegate?.beginPullToDismiss(on: viewController)
            }
        } else if panGestureRecognizer.state == .cancelled {
            cancel()

            if transitionIsActiveFromTranslationPoint != nil {
                delegate?.didCompletePullToDismissAttempt(on: viewController, finished: false)
            }
        } else if panGestureRecognizer.state == .ended {
            mostRecentActiveGestureTranslation = nil

            let finished = (
                    percentComplete >= PullToDismissTransition.translationThreshold &&
                    velocity.y == 0
                ) ||
                (
                    velocity.y >= PullToDismissTransition.velocityFinishThreshold &&
                    translation.y >= PullToDismissTransition.minimumTranslationYForDismiss
                )

            if finished {
                finish()
            } else {
                cancel()
            }

            if transitionIsActiveFromTranslationPoint != nil {
                transitionIsActiveFromTranslationPoint = nil
                delegate?.didCompletePullToDismissAttempt(on: viewController, finished: finished)
            }
        }
    }
}

extension PullToDismissTransition: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}

extension PullToDismissTransition: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return (
            transitionIsActiveFromTranslationPoint != nil
            ?
            PullToDismissTransition.transitionDurationDrag
            :
            PullToDismissTransition.transitionDurationInstant
        )
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVc = transitionContext.viewController(
            forKey: UITransitionContextViewControllerKey.from
        ) else { return }

        if dimmingView == nil {
            let dimmingView = UIView()
            dimmingView.alpha = PullToDismissTransition.dimmingPeakAlpha
            dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            dimmingView.backgroundColor = .black
            dimmingView.frame = transitionContext.containerView.bounds

            self.dimmingView = dimmingView
            transitionContext.containerView.insertSubview(dimmingView, belowSubview: fromVc.view)
        }

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveEaseInOut,
            animations: { [weak self] in
                fromVc.view.frame = UIScreen.main.bounds.offsetBy(dx: 0, dy: UIScreen.main.bounds.height)
                self?.dimmingView?.alpha = 0
            }, completion: { [weak self] _ in
                if transitionContext.transitionWasCancelled {
                    self?.dimmingView?.removeFromSuperview()
                    self?.dimmingView = nil
                }

                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}
