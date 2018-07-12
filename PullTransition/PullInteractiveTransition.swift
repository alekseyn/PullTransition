//
//  PullInteractiveTransition.swift
//  PullTransition
//
//  Created by Aleksey Novicov on 12/24/17.
//
// PullInteractiveTransition is designed to be used with
// presentation as well as navigation transition delegates.

import UIKit

public class PullInteractiveTransition: NSObject {
	private let kCompletionThreshold: CGFloat	= 0.20
	private let kVelocityThreshold: CGFloat 	= 500
	private let kVelocityScalar: CGFloat 		= 0.005
	private let kFlickMagnitude: CGFloat		= 1200		// 1200 pts/sec

	private weak var transitionContext: UIViewControllerContextTransitioning?
	private var updateCount: Int = 0

	// MARK: - Initialization
	
	let operation: PullTransitionOperation
	let animator: PullAnimatedTransition
	let panGestureRecognizer: UIPanGestureRecognizer
	var interruptionGestureRecognizer: UIPanGestureRecognizer?

	@objc public init(animator: PullAnimatedTransition, panGestureRecognizer panGesture: UIPanGestureRecognizer) {
		self.operation 				= animator.operation
		self.animator				= animator
		self.panGestureRecognizer 	= panGesture
		
		super.init()
	}

	deinit {
		self.panGestureRecognizer.removeTarget(self, action: nil)
		self.interruptionGestureRecognizer?.removeTarget(self, action: nil)
	}
	
	// MARK: - Gesture Recognizer and Interaction
	
	@objc func handleInteraction(_ gestureRecognizer: UIPanGestureRecognizer) {
		if let interruptibleAnimator = animator.transitionAnimator {

			switch gestureRecognizer.state {
				case .began:
					updateCount = 0
					
					// Remove ourselves from further event handling
					gestureRecognizer.removeTarget(self, action: #selector(handleInteraction(_:)))

				case .changed:
					updateCount += 1
					
					// Ask the gesture recognizer for it's translation
					let translation = gestureRecognizer.translation(in: transitionContext?.containerView)
					
					// Calculate the percent complete
					let percentComplete = interruptibleAnimator.fractionComplete + progressStepFor(translation: translation)
					
					// Update the transition animator's fractionCompete to scrub it's animations
					interruptibleAnimator.fractionComplete = min(percentComplete, 1.0)

					// Inform the transition context of the updated percent complete
					transitionContext?.updateInteractiveTransition(interruptibleAnimator.fractionComplete)
					
					// Reset the gestures translation
					gestureRecognizer.setTranslation(CGPoint.zero, in: transitionContext?.containerView)

				case .ended:
					// End the interactive phase of the transition
					endInteraction(gestureRecognizer)
				
					// Allow interruptions but this time using our own panGestureRecognizer. This may appear unnecessary but it overcomes
					// an unexpected system issue with the handling of source and destination view controllers that are navigation contollers.
					
					if interruptionGestureRecognizer == nil {
						// Remove pan original gesture recognizer from further event handling
						panGestureRecognizer.removeTarget(self, action: #selector(handleInteraction(_:)))
						
						// Add back in another gesture recognizer, but this time grounded in the container view
						interruptionGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleInteraction(_:)))
						transitionContext?.containerView.addGestureRecognizer(interruptionGestureRecognizer!)
						
						// Reset the gesture translation
						interruptionGestureRecognizer?.setTranslation(CGPoint.zero, in: transitionContext?.containerView)
						
						// In order to receive touch events we must disable user interaction in toViewController and fromViewController.
						if let fromView = transitionContext?.view(forKey: .from) {
							fromView.isUserInteractionEnabled = false
						}
						if let toView = transitionContext?.view(forKey: .to) {
							toView.isUserInteractionEnabled = false
						}
					}
				
				default:
					break
			}
		}
	}
	
	private func progressStepFor(translation: CGPoint) -> CGFloat {
		let travel = (operation.isForward) ? -translation.y : translation.y
		return travel / transitionContext!.containerView.bounds.midY
	}
	
	private func endInteraction(_ gestureRecognizer: UIPanGestureRecognizer) {
		// Ensure the context is currently interactive
		guard (transitionContext?.isInteractive)! else {
			assertionFailure("Invalid transition context state! Transition context state must be interactive while handling gesture recognition.")
			return
		}
		
		let completionPosition = self.completionPosition(gestureRecognizer)
		let velocity = gestureRecognizer.velocity(in: transitionContext?.containerView).vector
		
		// Switch to the animation phase of the transition to either the start or finsh position
		animate(toPosition: completionPosition, withVelocity: velocity)

		// Inform the transition context of whether we are finishing or cancelling the transition
		if completionPosition == .end {
			transitionContext?.finishInteractiveTransition()
		}
		else {
			transitionContext?.cancelInteractiveTransition()
		}
	}
	
	private func completionPosition(_ gestureRecognizer: UIPanGestureRecognizer) -> UIViewAnimatingPosition {
		// The UINavigationController transitioning delegate behaves poorly when there
		// have only been two or less gesture events. To minimize 'flashes' of the
		// navigation bar, we automatically finish an interactive transition.
		if updateCount <= 2 { return .end }
		
		let velocity 	= gestureRecognizer.velocity(in: transitionContext?.containerView).vector
		let isFlick 	= (velocity.magnitude > kFlickMagnitude)
		let isFlickDown	= isFlick && (velocity.dy > 0.0)
		let isFlickUp 	= isFlick && (velocity.dy < 0.0)
		
		if let interruptibleAnimator = animator.transitionAnimator {

			if (isFlickUp) {
				return (operation.isForward) ? .end : .start
			}
			else if (isFlickDown) {
				return (operation.isForward) ? .start : .end
			}
			else if interruptibleAnimator.fractionComplete > kCompletionThreshold {
				// Complete transition based on location threshold regardless of velocity
				return .end
			}
		}
		return .start
	}
	
	private func animate(toPosition: UIViewAnimatingPosition, withVelocity velocity: CGVector) {
		if let propertyAnimator = animator.transitionAnimator {
			
			// Reverse the transition animator if we are returning to the start position
			propertyAnimator.isReversed = (toPosition == .start)
			
			// Set default values as if animation completes at end position
			var fractionComplete	= propertyAnimator.fractionComplete
			let velocityVector 		= velocity.scaled(by: kVelocityScalar)
			let timing 				= UISpringTimingParameters(dampingRatio: 1.0, initialVelocity: velocityVector)

			if propertyAnimator.isReversed {
				// Slow down the return animation if it has momentum away from the start postion
				let slowdown = (operation.isForward) ? (velocity.dy < kVelocityThreshold) : (velocity.dy > -kVelocityThreshold)
				fractionComplete = (slowdown) ? 0.5 : propertyAnimator.fractionComplete
			}
			
			// We get a better feeling of inertia if there is a reasonable amount of time to see the animation
			if (fractionComplete > (1.0 - kCompletionThreshold)) {
				fractionComplete = (1.0 - kCompletionThreshold)
			}

			// Very quick gestures may end immediately after starting (ie, we never see the .changed state),
			// leaving the propertyAnimator in the inactive state. If this is the case, we need to activate
			// it simply by setting the fractionComplete
			if propertyAnimator.state == .inactive {
				propertyAnimator.fractionComplete = fractionComplete;
			}
			
			// Now we can animate to the finish position using the remainder time
			propertyAnimator.continueAnimation(withTimingParameters: timing, durationFactor: (1.0 - fractionComplete))
			
			// Optionally, perform any other visual resets if animation has been reversed
			if propertyAnimator.isReversed {
				if let context = transitionContext {
					animator.resetTransition?(using: context)
				}
			}
		}
	}
}

// MARK: -

extension PullInteractiveTransition: UIViewControllerInteractiveTransitioning {
	
	public func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
		// Save off transition context. We'll need it later
		self.transitionContext = transitionContext
		
		// Now is the optimal time to create an interruptible UIViewPropertyAnimator
		_ = animator.interruptibleAnimator!(using: transitionContext)

		// Sometimes the call to startInteractiveTransition is delayed until AFTER the first swipe of the
		// pan gesture recognizer had ENDED. This can occur when the swipe is extremely short. When this
		// occurs, kickstart the interactive transition by immediately animating the transition.
		
		if panGestureRecognizer.alreadyEnded() {
			animator.animateTransition(using: transitionContext)
		}
		else {
			// Start processing pan gesture recognizer events
			panGestureRecognizer.addTarget(self, action: #selector(handleInteraction(_:)))
			
			// Reset the gesture translation
			panGestureRecognizer.setTranslation(CGPoint.zero, in: transitionContext.containerView)
		}
	}
}

// MARK: -

extension UIPanGestureRecognizer {
	
	func alreadyEnded() -> Bool {
		var alreadyEnded = true
		
		switch self.state {
		
		case .began:
			alreadyEnded = false
		case .changed:
			alreadyEnded = false
		default:
			alreadyEnded = true
		}
	return alreadyEnded
	}
}
