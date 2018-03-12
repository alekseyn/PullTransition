//
//  PullToDismissViewController.swift
//  PullTransition
//
//  Created by Aleksey Novicov on 1/9/18.
//  Copyright © 2018 Aleksey Novicov. All rights reserved.
//

import Foundation

extension UIViewController {
	// The amount of travel beyond the pullTriggerThreshold
	@objc open func pullTravelThreshold() -> CGFloat {
		return 0.0
	}
	
	// Typically override only using PullToDismissViewVontroller or PullToPopViewController
	@objc open func pullTriggerThreshold() -> CGFloat {
		let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
		
		if let navController = self.navigationController {
			return navController.navigationBar.frame.size.height + statusBarHeight
		}
		return 0.0
	}
	
	@objc func pullTransitioningDelegate() -> PullTransition? {
		var delegate = self.transitioningDelegate as? PullTransition
		
		if 	delegate == nil {
			delegate = self.navigationController?.transitioningDelegate as? PullTransition
		}
		return delegate
	}
	
	@objc public func hasBeenDismissed(tableView: UITableView, completion: (() -> Swift.Void)? = nil) -> Bool {
		var hasBeenDismissed = false
		
		let contentOffset = -tableView.contentOffset.y - pullTriggerThreshold()
		let velocity = tableView.panGestureRecognizer.velocity(in: tableView.superview)

		if contentOffset > pullTravelThreshold() && velocity.y > 0 && !isBeingDismissed {
			
			// Don't interfere with the inertial deceleration. The tableview is not decelerating
			// when the user is panning with their finger.
			if !tableView.isDecelerating {
				
				if let delegate = pullTransitioningDelegate(), !delegate.animatorIsActive {
					
					// Stop scrolling
					tableView.setContentOffset(tableView.contentOffset, animated: false)
					
					dismiss(animated: true, completion: { [weak self] in
						// Reset original content offset
						if let trigger = self?.pullTriggerThreshold() {
							let originalOffset = CGPoint(x: 0, y: -trigger)
							tableView.setContentOffset(originalOffset, animated: true)
						}
						
						completion?()
					})
					
					delegate.animatedTransition?.startPosition	= CGPoint(x: 0, y: -pullTriggerThreshold())
					delegate.animatedTransition?.offsetError 	= contentOffset
					
					hasBeenDismissed = true
				}
			}
		}
		return hasBeenDismissed
	}
}

// MARK: -

public extension UITableViewController {
	@objc func hasBeenDismissed(completion: (() -> Swift.Void)? = nil) -> Bool {
		return hasBeenDismissed(tableView: tableView, completion: completion)
	}
}

// MARK: -

protocol PullToDismiss {
	var isTransitioning: Bool { get set }						// Ensures view controller is not repeatedly dismissed while in progress
	var interactiveTransitionEnabled: Bool { get set }			// Transitions might also be non-interactive
	var tableView: UITableView! { get set }						// Scroll view offset is used to trigger pull to dismiss
	
	func scrollViewDidScroll(_ scrollView: UIScrollView)		// UIScrollViewDelegate function that is required
}

// MARK: -

open class PullToDismissTableViewController: UITableViewController, PullTransitionPanning, PullToDismiss {
	
	// PullTransitionPanning
	
	public var panGestureRecognizer: UIPanGestureRecognizer? {
		get {
			// Random problems have been observed with iOS 10. Works better if not interactive.
			if #available(iOS 11, *) {
				
				if interactiveTransitionEnabled {
					return tableView.panGestureRecognizer
				}
			}
			return nil
		}
	}

	// PullToDismiss
	
	var isTransitioning = false
	var interactiveTransitionEnabled = false

	override open func scrollViewDidScroll(_ scrollView: UIScrollView) {
		// This pattern is recommended when using PullTransitions and dismissing a UITableViewController
		if !isTransitioning {
			interactiveTransitionEnabled = true
			
			isTransitioning = self.hasBeenDismissed(completion: { [weak self] in
				self?.isTransitioning = false
				self?.interactiveTransitionEnabled = false
			})
			
			// Execute children-defined code
			if isTransitioning {
				self.willPullToDismiss()
			}
			
			interactiveTransitionEnabled = isTransitioning
		}
	}
	
	// Virtual functions
	
	open func willPullToDismiss() {}
}

// MARK: -
// PullToDismissViewController is useful instances where a UITableView is used without a UITableViewController

open class PullToDismissViewController: UIViewController, PullTransitionPanning, PullToDismiss {
	
	override open func pullTriggerThreshold() -> CGFloat {
		return 0.0
	}
	
	// PullTransitionPanning
	
	public var panGestureRecognizer: UIPanGestureRecognizer? {
		get {
			// Random problems have been observed with iOS 10. Works better if not interactive.
			if #available(iOS 11, *) {
				
				if interactiveTransitionEnabled {
					return tableView.panGestureRecognizer
				}
			}
			return nil
		}
	}
	
	// PullToDismiss
	
	var isTransitioning = false
	var interactiveTransitionEnabled = false
	@IBOutlet public var tableView: UITableView!

	open func scrollViewDidScroll(_ scrollView: UIScrollView) {
		// This pattern is recommended when using PullTransitions and dismissing a UIViewController with a UITableView
		if !isTransitioning {
			interactiveTransitionEnabled = true
			
			if let tableView = scrollView as? UITableView {
				isTransitioning = hasBeenDismissed(tableView: tableView, completion: { [weak self] in
					self?.isTransitioning = false
					self?.interactiveTransitionEnabled = false
				})
			}
			
			// Execute children-defined code
			if isTransitioning {
				self.willPullToDismiss()
			}
			
			interactiveTransitionEnabled = isTransitioning
		}
	}
	
	// Virtual functions
	
	open func willPullToDismiss() {}
}

