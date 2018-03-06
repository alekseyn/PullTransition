//
//  PullTransitionDelegate.swift
//  PullTransition
//
//  Created by Aleksey Novicov on 12/17/17.
//

import UIKit


@objc public enum PullTransitionMode: UInt {
	case overlay
	case scroll
}

// A view controller that is the source of view controller transition must adopt the
// PullTransitionPanning protocol in order for that transition to be
// interactive and interruptible. In some cases the transition will still not be
// interruptible due to a UINavigationBar bug in iOS 11.2 (or earlier and perhaps later).

@objc public protocol PullTransitionPanning {
	// The transitioning view controller must provide a pan gesture recognizer for interactivity
	var panGestureRecognizer: UIPanGestureRecognizer? { get }
}

// Any custom UIViewControllerTransitioningDelegate or UINavigationControllerDelegate that makes use
// of the rest of the PullTransition framework must implement this protocol. But the easiest
// way to get started is just to use PullTransitionDelegate as it is.

@objc public protocol PullTransition {
	var animatedTransition: PullAnimatedTransition? { get }
}

extension PullTransition {
	public var animatorIsActive: Bool {
		if let state = animatedTransition?.transitionAnimator?.state {
			return state == .active
		}
		return false
	}
}

// MARK: -

public class PullTransitionDelegate: NSObject, PullTransition {
	public var animatedTransition: PullAnimatedTransition?
	
	private var interactiveTransition: PullInteractiveTransition?
	private var panGestureRecognizer: UIPanGestureRecognizer?
	private let defaultMode = PullTransitionMode.scroll
	
	// MARK: - Initialization
	
	public var mode: PullTransitionMode

	@objc public init(mode: PullTransitionMode) {
		self.mode = mode
		super.init()
	}
	
	public override init() {
		self.mode = defaultMode
		super.init()
	}
	
	public func usePanGestureRecognizer(fromViewController viewController: UIViewController) {
		// Clear any prior pan gesture recognizers
		panGestureRecognizer = nil
		
		if let pullTransitionPanning = viewController as? PullTransitionPanning,
			let gestureRecognizer = pullTransitionPanning.panGestureRecognizer {
			
			panGestureRecognizer = gestureRecognizer
		}
	}
	
	public func pullInteractionController(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		// Release any existing interactiveTransition
		interactiveTransition = nil
		
		// If there is no gesture recognizer then the animated transition will not be interactive
		guard 	let gestureRecognizer = panGestureRecognizer,
				let pullAnimator = animator as? PullAnimatedTransition
		else {
			return nil
		}
		
		// Save a reference to make sure it is retained
		interactiveTransition = PullInteractiveTransition.init(animator: pullAnimator,
																	panGestureRecognizer: gestureRecognizer)
		
		return interactiveTransition
	}
	
	@objc public func isActive() -> Bool {
		return self.animatorIsActive
	}
}

// MARK: - UIViewControllerTransitioningDelegate

extension PullTransitionDelegate: UIViewControllerTransitioningDelegate {
	
	public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		var presentingVC = presenting
		
		if let navigationController = presenting as? UINavigationController {
			presentingVC = navigationController.topViewController!
		}

		// Save pan gesture recognizer for use by interaction controller
		usePanGestureRecognizer(fromViewController: presentingVC)
		
		animatedTransition = PullTransitionAnimator(mode: self.mode, operation: .present)
		return animatedTransition
	}
	
	public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return pullInteractionController(using: animator)
	}
	
	public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		var presentedVC = dismissed

		if let navigationController = dismissed as? UINavigationController {
			presentedVC = navigationController.topViewController!
		}

		// Save pan gesture recognizer for use by interaction controller
		usePanGestureRecognizer(fromViewController: presentedVC)
		
		// Reuse animatedTransition, but update animation direction
		if let transition = animatedTransition {
			transition.operation = .dismiss
		}
		else {
			self.animatedTransition = PullTransitionAnimator(mode: self.mode, operation: .dismiss)
		}

		return animatedTransition
	}

	public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return pullInteractionController(using:animator)
	}
}

// MARK: - UINavigationControllerDelegate

extension PullTransitionDelegate: UINavigationControllerDelegate {
	
	public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		
		// Save pan gesture recognizer for use by interaction controller
		usePanGestureRecognizer(fromViewController: fromVC)

		if operation == .push {
			animatedTransition = PullTransitionAnimator(mode: self.mode, operation: .push)
		}
		else {
			// Reuse animatedTransition, but update animation direction
			if let transition = animatedTransition {
				transition.operation = .pop
			}
			else {
				// This might be necessary if the push was not animated, as may be the case when the navigation stack is initially set on launch.
				animatedTransition = PullTransitionAnimator(mode: self.mode, operation: .pop)
			}
		}
		return animatedTransition
	}
	
	public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return pullInteractionController(using:animationController)
	}
}
