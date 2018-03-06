# PullTransition
Simple to use, interactive & interruptible, animated view controller transitions. Includes gesture-driven transitions for out-of-the-box **PullToDismiss**, and  **PullToPop** functionality.

Takes advantage of latest iOS improvements using interruptible UIView animations with `UIViewPropertyAnimator`. Currently in use in production by at least two apps in the App Store: [Glasses](AppStore.com/YodelCode/Glasses) and [Slip](AppStore.com/YodelCode/Slip).

![Language](https://img.shields.io/badge/language-Swift%204-orange.svg)

 

## Usage
(1) Setup `PullTransition`

Include the `PullTransition` project in your own Xcode project or workspace. Be sure to add the `PullTransition.framework` from the Products folder in the Embedded Binaries and Linked Frameworks of your own projects. As an example, see the `PullTransitionDemo` project.

(2) For interactivity, **source view controllers** must implement `PullTransitionPanning`. They are required to have a pan gesture recognizer.

```swift
import PullTransition

class FirstViewController: UIViewController, PullTransitionPanning {
	var panGestureRecognizer: UIPanGestureRecognizer?
}
```

**Destination view controllers** can either implement the `PullTransitionPanning` protocol, or simply subclass `PullToDismissViewController` or `PullToPopViewController`.

```swift
import PullTransition

class MyTableViewController: PullToDismissViewController {
}
```

(3) To create a new view controller transitioning delegate, or navigation controller delegate, use `PullTransitionDelegate(mode: PullTransitionMode)`
where mode can be `.overlay` or `.scroll`. Assign it to either a navigation controller's `delegate`, or a presented view controller's `transitioningDelegate`.

```swift
import PullTransition

class FirstViewController: UIViewController, PullTransitionPanning {
	var panGestureRecognizer: UIPanGestureRecognizer?
	
	lazy var pullTransitionDelegate: PullTransitionDelegate = {
		return  PullTransitionDelegate(mode: .scroll)
	} ()
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "SegueID" {
			segue.destination.transitioningDelegate = pullTransitionDelegate
		}
    }
}
```

(4) `pullTransitionDelegate.animatorIsActive` must be `false` before invoking an animation transition:

```swift
	@IBAction func handlePanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
		latestGestureRecognizerState = panGestureRecognizer.state
		
		switch panGestureRecognizer.state {
		case .began:
			if !self.panTransitionDelegate.animatorIsActive {
				self.performSegue(withIdentifier: "SegueID", sender: self)
			}
			
		default:
			break
		}
	}
```

(5) Table view controllers that have been presented, with or without being embedded in a navigation controller, simply need to subclass `PullToDismissViewController`. No other code required.

(6) Table view controllers that have been pushed onto a navigation controller, simply need to subclass `PullToPopViewController`. No other code required.

## Advanced
`PullTransitionDelegate` can be replaced with your own custom class as long as it implements the `PullTransition` protocol.

`PullTransitionAnimator` can also be replaced with any class that implements the `PullAnimatedTransition` protocol.

However, to master the use of this framework it is recommended to first start using it as is.

## Requirements
- iOS 10.0 or later 
- Xcode 9.0 or later
- Swift 4

## Installation

### CocoaPods

`PullTransition` is not yet available through [CocoaPods](http://cocoapods.org). Coming soon...

### Manually Install
Include the `PullTransition` project in your own Xcode project or workspace. Or download all `*.swift` files from the `PullTransition` folder and put in your project.

## Licence
`PullTransition` is released under the New BSD License.

Copyright (c) 2018, Yodel Code LLC All rights reserved.