//
//  PullToDismissTransition.swift
//  PullToDismissTransition
//
//  Created by Ben Guild on 2018/06/14.
//  Copyright © 2018年 Ben Guild. All rights reserved.
//

import UIKit

public protocol PullToDismissTransitionDelegate: class {
    func canBeginPullToDismiss(on dismissingViewController: UIViewController) -> Bool

    func didBeginPullToDismissAttempt(on dismissingViewController: UIViewController)
    func didCompletePullToDismissAttempt(on dismissingViewController: UIViewController, willDismiss: Bool)
    func didFinishTransition(for dismissingViewController: UIViewController, didDismiss: Bool)
}

extension PullToDismissTransitionDelegate {
    public func canBeginPullToDismiss(on dismissingViewController: UIViewController) -> Bool {
        return true
    }

    public func didBeginPullToDismissAttempt(on dismissingViewController: UIViewController) {}
    public func didCompletePullToDismissAttempt(on dismissingViewController: UIViewController, willDismiss: Bool) {}
    public func didFinishTransition(for dismissingViewController: UIViewController, didDismiss: Bool) {}
}

public enum PullToDismissTransitionType {
    case slideStatic
    case slideDynamic
    case scale
}

public class PullToDismissTransition: UIPercentDrivenInteractiveTransition {
    private struct Const {
        static let dimmingAlphaTransitionFinishDropDelay: TimeInterval = 0.24
        static let dimmingPeakAlpha: CGFloat = 0.87

        static let minimumTranslationYForDismiss: CGFloat = 87
        static let translationThreshold: CGFloat = 0.35

        static let scalingViewCornerRadius: CGFloat = 12
        static let scalingViewCornerRadiusToggleDuration: TimeInterval = 0.15
        static let scalingPeakScaleDivider: CGFloat = 5

        static let touchStillWithoutPanEndDelay: TimeInterval = 0.15

        static let transitionDurationDragSlide: TimeInterval = 0.87
        static let transitionDurationDragScale: TimeInterval = 0.35
        static let transitionReEnableTimeoutAfterScroll: TimeInterval = 0.72

        static let velocityBeginThreshold: CGFloat = 10
        static let velocityFinishThreshold: CGFloat = 1280
    }

    public let transitionType: PullToDismissTransitionType
    public let animationOptions: UIView.AnimationOptions
    private(set) weak var viewController: UIViewController?

    private(set) weak var monitoredScrollView: UIScrollView?
    public var permitWhenNotAtRootViewController = false

    public weak var delegate: PullToDismissTransitionDelegate?

    public var isDimmingEnabled = true

    private weak var dimmingView: UIView?
    private weak var scalingView: UIView?
    private var transitionIsActiveFromTranslationPoint: CGPoint?

    private var didRequestScrollViewBounceDisable = false
    private var monitoredScrollViewDoesBounce = false
    private var recentScrollIsBlockingTransition = false
    private var scrollInitiateCount: Int = 0
    private var scrollViewObservation: NSKeyValueObservation?
    private var touchBeginOrPanIncrement: Int = 0
    private var transitionHasEndedAndPanIsInactive = false

    private var currentTouchIsStillAndActive = false
    private var mostRecentActiveGestureTranslation: CGPoint?

    @objc dynamic public private(set) var transitionProgress: CGFloat = 0

    public var transitionDelegateObservation: NSKeyValueObservation?

    deinit {
        scrollViewObservation?.invalidate()
        transitionDelegateObservation?.invalidate()
    }

    public init(
        viewController: UIViewController,
        animationOptions: UIView.AnimationOptions = [.curveLinear],
        transitionType: PullToDismissTransitionType = .slideStatic
    ) {
        self.animationOptions = animationOptions
        self.transitionType = transitionType
        self.viewController = viewController

        super.init()
    }

    public func additionalGestureRecognizerForTrigger() -> UIGestureRecognizer {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        panGestureRecognizer.delegate = self

        return panGestureRecognizer
    }

    private func updateBounceLockoutState() {
        guard let monitoredScrollView = monitoredScrollView else { return }
        guard monitoredScrollViewDoesBounce else { return }

        var doesTranslateY = false

        switch transitionType {
        case .slideStatic, .slideDynamic:
            doesTranslateY = true
        case .scale:
            doesTranslateY = false
        }

        let shouldScrollViewBounceBeDisabled =
            currentTouchIsStillAndActive ||
            ((mostRecentActiveGestureTranslation?.y ?? 0) > 0) ||
            (doesTranslateY && transitionHasEndedAndPanIsInactive && monitoredScrollView.contentOffset.y <= 0)

        guard shouldScrollViewBounceBeDisabled != didRequestScrollViewBounceDisable else { return }
        didRequestScrollViewBounceDisable = shouldScrollViewBounceBeDisabled

        guard monitoredScrollView.bounces != !shouldScrollViewBounceBeDisabled else { return }
        monitoredScrollView.bounces = !shouldScrollViewBounceBeDisabled
    }

    public func monitorActiveScrollView(scrollView: UIScrollView) {
        if let monitoredScrollView = monitoredScrollView, monitoredScrollViewDoesBounce {
            monitoredScrollView.bounces = true
        }

        scrollViewObservation?.invalidate()

        monitoredScrollView = scrollView

        didRequestScrollViewBounceDisable = false
        monitoredScrollViewDoesBounce = scrollView.bounces
        recentScrollIsBlockingTransition = false

        scrollViewObservation = scrollView.observe(
            \UIScrollView.contentOffset,
            options: [.initial, .new]
        ) { [weak self] scrollView, _ in
            self?.updateBounceLockoutState()

            guard scrollView.contentOffset.y > scrollView.bounds.size.height else { return }

            self?.recentScrollIsBlockingTransition = true
            self?.scrollInitiateCount += 1

            let localCopyOfScrollInitiateCount = self?.scrollInitiateCount

            DispatchQueue.main.asyncAfter(
                deadline: DispatchTime.now() + Const.transitionReEnableTimeoutAfterScroll
            ) {
                guard self?.monitoredScrollView === scrollView else { return }
                guard self?.scrollInitiateCount == localCopyOfScrollInitiateCount else { return }

                self?.recentScrollIsBlockingTransition = false
            }
        }
    }

    private func isAtRootViewController() -> Bool {
        guard let navigationController = (viewController as? UINavigationController)
            ?? viewController?.navigationController else { return true }

        return (navigationController.viewControllers.count <= 1)
    }

    private func canBeginPullToDismiss(
        velocity: CGPoint = .zero,
        on viewController: UIViewController
    ) -> Bool {
        return !recentScrollIsBlockingTransition &&
            velocity.y > Const.velocityBeginThreshold &&
            velocity.y > abs(velocity.x) &&
            (permitWhenNotAtRootViewController || isAtRootViewController()) &&
            (monitoredScrollView?.contentOffset.y ?? 0) <= 0 &&
            (delegate?.canBeginPullToDismiss(on: viewController) ?? true)
    }

    private func stopPullToDismiss(on viewController: UIViewController, finished: Bool) {
        if finished {
            finish()
        } else {
            cancel()
        }

        guard transitionIsActiveFromTranslationPoint != nil else { return }
        transitionIsActiveFromTranslationPoint = nil

        delegate?.didCompletePullToDismissAttempt(on: viewController, willDismiss: finished)
    }

    private func handlePan(from panGestureRecognizer: UIPanGestureRecognizer, on view: UIView) {
        guard let viewController = viewController else { return }

        let translation = panGestureRecognizer.translation(in: view)
        let velocity = panGestureRecognizer.velocity(in: view)

        currentTouchIsStillAndActive = false
        touchBeginOrPanIncrement += 1

        switch panGestureRecognizer.state {
        case .began, .changed:
            mostRecentActiveGestureTranslation = translation
            transitionHasEndedAndPanIsInactive = false

            if let transitionIsActiveFromTranslationPoint = transitionIsActiveFromTranslationPoint {
                let progress = min(1, max(
                    0,
                    (translation.y - transitionIsActiveFromTranslationPoint.y) / max(1, view.bounds.size.height)
                ))

                if progress == 0 {
                    stopPullToDismiss(on: viewController, finished: false)
                    break
                }

                transitionProgress = progress
                update(progress)
            } else if canBeginPullToDismiss(velocity: velocity, on: viewController) {
                transitionIsActiveFromTranslationPoint = translation

                if let monitoredScrollView = monitoredScrollView, monitoredScrollView.isScrollEnabled {
                    monitoredScrollView.contentOffset = CGPoint(
                        x: monitoredScrollView.contentOffset.x - monitoredScrollView.contentInset.left,
                        y: -monitoredScrollView.contentInset.top
                    )
                }

                viewController.dismiss(animated: true) { [weak self] in
                    let didDismiss = (viewController.presentingViewController == nil)

                    if didDismiss {
                        self?.transitionDelegateObservation?.invalidate()
                    }

                    self?.delegate?.didFinishTransition(for: viewController, didDismiss: didDismiss)
                }

                delegate?.didBeginPullToDismissAttempt(on: viewController)
            }
        case .cancelled, .ended:
            if transitionIsActiveFromTranslationPoint != nil {
                transitionHasEndedAndPanIsInactive = true
            }

            mostRecentActiveGestureTranslation = nil

            stopPullToDismiss(on: viewController, finished: panGestureRecognizer.state != .cancelled && (
                (percentComplete >= Const.translationThreshold && velocity.y >= 0) ||
                    (
                        velocity.y >= Const.velocityFinishThreshold &&
                            translation.y >= Const.minimumTranslationYForDismiss
                    )
            ))
        default:
            break
        }

        updateBounceLockoutState()
    }

    @objc private func didPan(sender: Any?) {
        guard let panGestureRecognizer = sender as? UIPanGestureRecognizer else { return }
        guard let view = panGestureRecognizer.view else { return }

        handlePan(from: panGestureRecognizer, on: view)
    }
}

extension PullToDismissTransition: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        touchBeginOrPanIncrement += 1
        currentTouchIsStillAndActive = true

        let localCopyOfTouchBeginOrPanIncrement = touchBeginOrPanIncrement

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Const.touchStillWithoutPanEndDelay) {
            guard self.touchBeginOrPanIncrement == localCopyOfTouchBeginOrPanIncrement else { return }

            self.currentTouchIsStillAndActive = false
            self.updateBounceLockoutState()
        }

        updateBounceLockoutState()
        return true
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}

extension PullToDismissTransition: UIViewControllerAnimatedTransitioning {
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        switch transitionType {
        case .slideStatic, .slideDynamic:
            return Const.transitionDurationDragSlide
        case .scale:
            return Const.transitionDurationDragScale
        }
    }

    private func setupTransitionViewsIfNecessary(
        using transitionContext: UIViewControllerContextTransitioning,
        in viewController: UIViewController
    ) {
        if isDimmingEnabled && dimmingView == nil {
            let dimmingView = UIView()
            dimmingView.alpha = Const.dimmingPeakAlpha
            dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            dimmingView.frame = transitionContext.containerView.bounds

            let color: UIColor

            switch transitionType {
            case .slideStatic, .slideDynamic:
                color = .black
            case .scale:
                color = .white
            }

            dimmingView.backgroundColor = color

            self.dimmingView = dimmingView
            transitionContext.containerView.insertSubview(dimmingView, belowSubview: viewController.view)
        }

        if transitionType != .slideDynamic && scalingView == nil,
            let scalingView = viewController.view.resizableSnapshotView(
                from: viewController.view.bounds,
                afterScreenUpdates: true,
                withCapInsets: .zero
            ) {
            scalingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            scalingView.frame = transitionContext.containerView.bounds
            scalingView.transform = .identity

            self.scalingView = scalingView
            transitionContext.containerView.insertSubview(scalingView, aboveSubview: viewController.view)

            viewController.view.isHidden = true

            var shouldRoundCorners = false

            switch transitionType {
            case .slideStatic, .slideDynamic:
                break
            case .scale:
                shouldRoundCorners = true
            }

            if #available(iOS 10.0, *) {
                if shouldRoundCorners {
                    scalingView.layer.masksToBounds = true

                    UIViewPropertyAnimator(
                        duration: Const.scalingViewCornerRadiusToggleDuration,
                        curve: .easeIn
                    ) {
                        scalingView.layer.cornerRadius = Const.scalingViewCornerRadius
                    }.startAnimation()
                }
            }
        }
    }

    private func tearDownTransitionViewsAsNecessary(
        using transitionContext: UIViewControllerContextTransitioning,
        for viewController: UIViewController,
        completionHandler: (() -> Void)? = nil
    ) {
        if transitionContext.transitionWasCancelled, let scalingView = scalingView {
            if #available(iOS 10.0, *) {
                if scalingView.layer.cornerRadius > 0 {
                    viewController.view.layer.cornerRadius = scalingView.layer.cornerRadius
                    viewController.view.layer.masksToBounds = true

                    UIViewPropertyAnimator(
                        duration: Const.scalingViewCornerRadiusToggleDuration,
                        curve: .easeIn
                    ) {
                        viewController.view.layer.cornerRadius = 0
                    }.startAnimation()
                }
            }

            viewController.view.isHidden = false

            scalingView.removeFromSuperview()
            self.scalingView = nil
        }

        let completeBlock: (Bool) -> Void = { [weak self] finished -> Void in
            if finished {
                self?.dimmingView?.removeFromSuperview()
                self?.dimmingView = nil
            }

            completionHandler?()
        }

        if dimmingView != nil {
            var holdDimmingView = false

            switch transitionType {
            case .slideStatic, .slideDynamic:
                holdDimmingView = false
            case .scale:
                holdDimmingView = !transitionContext.transitionWasCancelled
            }

            if holdDimmingView {
                UIView.animate(
                    withDuration: Const.dimmingAlphaTransitionFinishDropDelay,
                    animations: { [weak self] in
                        self?.dimmingView?.alpha = transitionContext.transitionWasCancelled ? 1 : 0
                    },
                    completion: completeBlock
                )

                return
            }
        }

        completeBlock(true)
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVc = transitionContext.viewController(
            forKey: UITransitionContextViewControllerKey.from
        ) else { return }

        setupTransitionViewsIfNecessary(using: transitionContext, in: fromVc)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: animationOptions,
            animations: { [weak self] in
                guard let strongSelf = self else { return }

                switch strongSelf.transitionType {
                case .slideStatic, .slideDynamic:
                    guard let slideView = (
                        strongSelf.transitionType == .slideDynamic
                            ?
                            fromVc.view
                            :
                            strongSelf.scalingView
                    ) else { break }

                    slideView.frame = slideView.frame.offsetBy(
                        dx: 0,
                        dy: slideView.window?.bounds.height ?? 0
                    )

                    strongSelf.dimmingView?.alpha = 0
                case .scale:
                    guard let scalingView = strongSelf.scalingView else { break }
                    scalingView.alpha = 0
                    scalingView.frame = scalingView.frame.insetBy(
                        dx: scalingView.frame.width / Const.scalingPeakScaleDivider,
                        dy: scalingView.frame.height / Const.scalingPeakScaleDivider
                    )
                }
            },
            completion: { [weak self] _ in
                self?.tearDownTransitionViewsAsNecessary(
                    using: transitionContext,
                    for: fromVc,
                    completionHandler: {
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                    }
                )
            }
        )
    }
}
