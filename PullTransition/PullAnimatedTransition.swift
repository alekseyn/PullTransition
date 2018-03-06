//
//  PullAnimatedTransition.swift
//  PullTransition
//
//  Created by Aleksey Novicov on 12/25/17.
//


import UIKit

@objc public enum PullTransitionOperation: UInt {
	case present
	case dismiss
	case push
	case pop
	
	var isForward: Bool {
		return (self == .present) || (self == .push)
	}
	
	var isModal: Bool {
		return (self == .present) || (self == .dismiss)
	}
}

@objc public protocol PullAnimatedTransition: UIViewControllerAnimatedTransitioning {
	// These variables simply need to be instantiated
	var operation: PullTransitionOperation { get set }
	var transitionAnimator: UIViewPropertyAnimator? { get }
	var transitionCompletion: (() -> Swift.Void)? { get set }
	var startPosition: CGPoint { get set }
	var offsetError: CGFloat { get set }

	// Depending on the speed of the interactive gesture that initiates an animation transition,
	// an offset error may be introduced. In other words, the reported starting position of the gesture
	// may actually beyond the actual visual appearance of the start of the animation. resetTransition()
	// provides an opportunity for this to be corrected if an animation is ever reversed.
	@objc optional func resetTransition(using transitionContext: UIViewControllerContextTransitioning) -> ()
}

// PullTransitionAnimator may be replaced with a completely different implementation
// as long as it conforms to the PullAnimatedTransition protocol.

public class PullTransitionAnimator: NSObject, PullAnimatedTransition {
	public var transitionAnimator: UIViewPropertyAnimator?
	public var transitionCompletion: (() -> Void)?
	public var startPosition: CGPoint = .zero
	public var offsetError: CGFloat = 0.0

	// There are problems generating this snapshot when the view controller is dismissed,
	// so save the snapshot generated when view controller is presented.
	var reverseScrollSnapshot: UIView?
	
	// Snapshots are not captured properly if afterUpdates is true and the transition
	// is non-interactive. If we know ahead of time that the transition is non-interactive, then
	// snapshots can be correctly captured by setting afterUpdates to false.
	var interactive = true
	
	// MARK: - Class methods
	
	class func animationDuration() -> TimeInterval {
		return 0.6
	}
	
	// MARK: - Initialization
	
	public var mode: PullTransitionMode
	public var operation: PullTransitionOperation
	
	public init(mode: PullTransitionMode, operation: PullTransitionOperation) {
		self.mode 		= mode
		self.operation 	= operation
		
		super.init()
	}
	
	func propertyAnimatorForContext(_ context: UIViewControllerContextTransitioning, interactive: Bool) -> UIViewPropertyAnimator {
		guard 	let fromVC	 		= context.viewController(forKey: .from),
				let toView	 		= context.view(forKey: .to),
				let fromView		= context.view(forKey: .from)
		else {
			return UIViewPropertyAnimator(duration: self.transitionDuration(using: context), dampingRatio: 1.0, animations: nil)
		}
		
		// The toView is always on top when animating in forward direction
		if operation.isForward {
			context.containerView.insertSubview(toView, aboveSubview: fromView)
		}
		else {
			context.containerView.insertSubview(toView, belowSubview: fromView)
		}
		
		var startFrame = fromView.frame
		startFrame.origin.y += (operation.isForward) ? startFrame.size.height : -startFrame.size.height
		
		var toSnapshot = toView.snapshotView(afterScreenUpdates: true)
		toSnapshot?.isUserInteractionEnabled = false
		
		// In rare cases toView is not properly or fully snapshotted. So use
		// toView rather than it's snapshot. But in all other cases use toSnapshot
		let embedded = (fromVC.navigationController != nil)

		if mode == .scroll {
			if operation.isForward {
				// The snapshot generated at time of reverse animation is incorrectly offset when using
				// auto-layout. Not sure why. Instead, save the snapshot view during forward animation.
				reverseScrollSnapshot = fromView.snapshotView(afterScreenUpdates: false)
				reverseScrollSnapshot?.isUserInteractionEnabled = false
			}
			else {
				// Use the previously saved snapshot
				toSnapshot = reverseScrollSnapshot;
			}
			
			toView.frame = startFrame
			toSnapshot?.frame = startFrame

			if toSnapshot != nil {
				context.containerView.insertSubview(toSnapshot!, belowSubview: fromView)
			}
		}
		else { // .overlay

			if (operation.isForward) {
				toView.frame = startFrame
				toSnapshot?.frame = startFrame

				if toSnapshot != nil {
					context.containerView.insertSubview(toSnapshot!, aboveSubview: toView)
				}
			}
		}
		
		// Hide the toView to prevent ocassional flashing of toView.
		// But cannot be hidden if in .overlay mode.
		toView.isHidden = (mode == .scroll)

		let duration	= PullTransitionAnimator.animationDuration()
		let timing 		= UISpringTimingParameters(dampingRatio: 1.0)
		
		let propertyAnimator = UIViewPropertyAnimator(duration: duration, timingParameters: timing)
		
		propertyAnimator.addAnimations {
			var endFrame = fromView.frame
			
			// Animate toView and toSnapshot into place together, even though one of them is hidden
			toSnapshot?.frame = endFrame
			toView.frame = endFrame
			
			endFrame.origin.y += (self.operation.isForward) ? -fromView.frame.height : fromView.frame.height

			// Animate fromView into place
			if self.mode == .scroll {
				// Hide the toView (toSnapshot) until the animation is finished
				toView.isHidden 	 = !embedded
				toSnapshot?.isHidden = embedded
				
				fromView.frame = endFrame
			}
			else {
				if self.operation.isForward {
					// Hide the toView (toSnapshot) until the animation is finished
					toView.isHidden 	 = !embedded
					toSnapshot?.isHidden = embedded
				}
				else {
					fromView.frame = endFrame
				}
			}
		}
		
		propertyAnimator.addCompletion { (position) in
			// Inform the transition context of whether we are finishing or cancelling the transition
			let completed = (position == .end)
			
			if !completed {
				toView.removeFromSuperview()
			}
			
			toView.isHidden = false
			fromView.isHidden = false
			
			// isUserInteractionEnabled can be set to false by PullInteractiveTransition
			toView.isUserInteractionEnabled = true
			fromView.isUserInteractionEnabled = true
			
			toSnapshot?.removeFromSuperview()
			context.completeTransition(completed)
		}
		return propertyAnimator
	}
	
	public func resetTransition(using transitionContext: UIViewControllerContextTransitioning) {
		if startPosition != .zero || offsetError != 0.0 {
			
			// Need to capture value of startPosition for addCompletion() closure
			let contentOffset = startPosition
			
			let contentOffsetWithError = CGPoint(x: startPosition.x, y: startPosition.y - offsetError)
			
			// If this is as a result of PullToDismiss, then need to check for view controllers that might be wrapped in a UINavigationController.
			let navigationController = transitionContext.viewController(forKey: .from) as? UINavigationController
			var scrollView = navigationController?.topViewController?.view as? UIScrollView
			
			if scrollView == nil {
				if let fromViewController = transitionContext.viewController(forKey: .from) as? UITableViewController {
					scrollView = fromViewController.tableView
				}
			}
			
			// Set scrollView to it's starting position when animation transition was triggered
			scrollView?.setContentOffset(contentOffsetWithError, animated: false)
			
			// Set scrollView to it's resting starting position (ie, with error)
			transitionAnimator?.addCompletion({ (position) in
				if position == .start {
					scrollView?.setContentOffset(contentOffset, animated: true)
				}
			})

			startPosition = .zero
			offsetError = 0.0
		}
	}
}

// MARK: - UIViewControllerAnimatedTransitioning

extension PullTransitionAnimator: UIViewControllerAnimatedTransitioning {
	
	public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return PullTransitionAnimator.animationDuration()
	}
	
	public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		interactive = false
		self.interruptibleAnimator(using: transitionContext).startAnimation()
	}
	
	public func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
		// A UIViewPropertyAnimator (transitionAnimator) is used for this transition. It must live the lifetime of the transitionContext.
		if transitionAnimator == nil {
			transitionAnimator = propertyAnimatorForContext(transitionContext, interactive: interactive)
		}
		return transitionAnimator!
	}
	
	public func animationEnded(_ transitionCompleted: Bool) {
		transitionCompletion?()
		transitionAnimator = nil
		
		interactive = true
	}
}

