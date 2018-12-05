# PullToDismissTransition

**NOTE:** This is beta! Pull-requests are welcome.

Uses **`UIPercentDrivenInteractiveTransition`** and **`UIViewControllerAnimatedTransitioning`** to quickly implement nice “pull-to-dismiss” interactions on modal view controller(s). — Also handles `UIScrollView` bounce toggling dynamically when necessary. 

[![Version](https://img.shields.io/cocoapods/v/PullToDismissTransition.svg?style=flat)](http://cocoapods.org/pods/PullToDismissTransition)
[![License](https://img.shields.io/cocoapods/l/PullToDismissTransition.svg?style=flat)](http://cocoapods.org/pods/PullToDismissTransition)
[![Platform](https://img.shields.io/cocoapods/p/PullToDismissTransition.svg?style=flat)](http://cocoapods.org/pods/PullToDismissTransition)

## Bundled transition types

There are 3 bundled transition types:
- **`slideStatic`** = **Default,** to slide away vertically with a panning gesture.
- **`slideDynamic`** = Same as `slideStatic`, but does not screenshot the view controller.
- **`scale`** = Scales down the view before eventually fading it out and fading in the view underneath.

All transition types are configured to provide minimal interference with the vertical "bouncing" of a `UIScrollView`.

## Demo

Example of the “slide” transition reversing against a **`UIScrollView`** in a single, fluid gesture:

![Example of the “slide” transition reversing against a `UIScrollView` in a single, fluid gesture](https://raw.github.com/benguild/PullToDismissTransition/master/demo.gif "Example of the “slide” transition reversing against a `UIScrollView` in a single, fluid gesture")

## Installation

`PullToDismissTransition` is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "PullToDismissTransition"
```

## Instructions

When presenting your modal view controller, be sure to set the presentation context, or the transitions will not appear over other view controllers below:

```swift
var viewController = MyAwesomeViewController()
viewController.isPullToDismissEnabled = true

viewController.modalPresentationCapturesStatusBarAppearance = true
viewController.modalPresentationStyle = .overFullScreen

self.present(viewController, animated: true)
```

The simplest implementation is through adopting the **`PullToDismissable`** protocol on your view controller(s):

```swift
import PullToDismissTransition
import UIKit

class MyAwesomeViewController: UIViewController, PullToDismissable {
    private(set) lazy var pullToDismissTransition: PullToDismissTransition = {
        let pullToDismissTransition = PullToDismissTransition(
            viewController: self,
            transitionType: .slideStatic
        )

        ////
        // NOTE: Optional, unless you implement any of the delegate methods:
        pullToDismissTransition.delegate = self

        return pullToDismissTransition
    }()

    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        setupPullToDismiss()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupPullToDismiss()

        ////
        // NOTE: Optional, unless you've navigated to a scroll-view within a navigation
        //  flow (but the same context), and therefore must toggle monitoring to it:

        pullToDismissTransition.monitorActiveScrollView(scrollView: scrollView)
    }
}

extension MyAwesomeViewController: UIViewControllerTransitioningDelegate {
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
```

*... Ta-da!*

Use the **`setPullToDismissEnabled()`** method to revert back to the default transition(s) in iOS, such as when you're dismissing via a button press. You can also call this method within `viewDidLoad()` to enable if you didn't set **"isPullToDismissEnabled"** at time of initialization.

## `PullToDismissTransitionDelegate` methods

To gain additional control, optionally implement the delegate of `PullToDismissTransition`:

```swift
extension MyAwesomeViewController: PullToDismissTransitionDelegate {
    func canBeginPullToDismiss(on dismissingViewController: UIViewController) -> Bool {
        // Return "false" to disable the transition during certain events, such as a horizontal
        //  page-swipe.

        return true
    }

    func didBeginPullToDismissAttempt(on dismissingViewController: UIViewController) {
        guard dismissingViewController === self else { return }

        // Handle events when the transition becomes active, such as adjusting or disabling certain GUI.
    }

    func didCompletePullToDismissAttempt(on dismissingViewController: UIViewController, willDismiss: Bool) {
        guard dismissingViewController === self else { return }

        // Called when the attempt is cancelled or completed.

        // Handle events when the transition becomes active, such as reverting adjusted or re-enabling
        //  certain GUI.
    }

    func didFinishTransition(for dismissingViewController: UIViewController, didDismiss: Bool) {
        guard dismissingViewController === self else { return }

        // Called after the transition completes.
    }
}
```

None of these methods are required in your implementation, but are available in case you need them.

## `UIScrollView` compatibility

**`PullToDismissTransition`** is designed to work with `UIScrollView`, and provide minimal interference with any vertical bouncing. However, when changing between view controllers within the same context (such as when navigating within view controllers in `UINavigationController`), you need to keep the transition up-to-date with whichever scroll view is actively displayed on-screen:

```swift
pullToDismissTransition.monitorActiveScrollView(scrollView: myAwesomeScrollView)
```

Calling this method will replace any existing observation, and should also be used for other scroll view descendants such as `UITableView`, `UICollectionView`, etc.

## `UINavigationController` compatibility with `PullToDismissable` protocol

The **`PullToDismissable`** protocol is designed for use on the **child** view-controller(s) of a `UINavigationController`, as views within the navigation flow may have scrolling/bouncing behaviors that require monitoring via the transition's `monitorActiveScrollView(scrollView: UIScrollView)` method.

## Alternatively, implementing `PullToDismissTransition` directly

While the `PullToDismissable` protocol is provided for your convenience and to reduce code complexity in re-use, it is also fine to implement `PullToDismissTransition` yourself directly by referencing this protocol's code for the transition's integration.

## Author

Ben Guild, hello@benguild.com

## License

`PullToDismissTransition` is available under the MIT license. See the LICENSE file for more info.
