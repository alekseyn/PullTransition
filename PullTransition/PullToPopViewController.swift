//
//  PullToPopViewController.swift
//  PullTransition
//
//  Created by Aleksey Novicov on 1/17/18.
//  Copyright © 2018 Aleksey Novicov. All rights reserved.
//

import UIKit

public extension UIViewController {
	@objc func pullNavigationDelegate() -> PullTransition? {
		return self.navigationController?.delegate as? PullTransition
	}
	
	// The amount of travel beyond the pullTriggerThreshold
	@objc func pullTravelThreshold() -> CGFloat {
		return 0.0
	}

	// Typically override only using PullToDismissViewVontroller or PullToPopViewController
	@objc func pullTriggerThreshold() -> CGFloat {
		let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
		
		if let navController = self.navigationController {
			return navController.navigationBar.frame.size.height + statusBarHeight
		}
		return 0.0
	}
	
	@objc public func hasBeenPopped(tableView: UITableView, completion: (() -> Swift.Void)? = nil) -> Bool {
		var hasBeenPopped = false
		
		let contentOffset = -tableView.contentOffset.y - pullTriggerThreshold()
		let velocity = tableView.panGestureRecognizer.velocity(in: tableView.superview)

		if contentOffset > pullTravelThreshold() && velocity.y > 0 && !isMovingFromParentViewController {
			
			// Don't interfere with the inertial deceleration. The tableview is not decelerating
			// when the user is panning with their finger.
			if !tableView.isDecelerating {
				if 	let delegate = pullNavigationDelegate(), !delegate.animatorIsActive {
					self.navigationController?.popViewController(animated: true)
					
					// Can only set the transition completion AFTER popViewController is called.
					// "animatedTransition" object must be set up first!
					delegate.animatedTransition?.transitionCompletion = completion
					
					// The startPosition is from where the animation was expected to begin. However, it may have actually
					// started later given the slight delay in reported contentOffset positions. Setting the startPosition
					// will trigger an additional animation to reset the view to it's original position.
					let startPosition = CGPoint(x: 0, y: -pullTriggerThreshold())
					
					delegate.animatedTransition?.startPosition = startPosition
					delegate.animatedTransition?.offsetError = contentOffset

					hasBeenPopped = true
				}
			}
		}
		return hasBeenPopped
	}
}

// MARK: -

public extension UITableViewController {
	@objc func hasBeenPopped(completion: (() -> Swift.Void)? = nil) -> Bool {
		return hasBeenPopped(tableView: tableView, completion: completion)
	}
}

// MARK: -

protocol PullToPop {
	var isTransitioning: Bool { get set }						// Ensures view controller is not repeatedly popped while in progress
	var interactiveTransitionEnabled: Bool { get set }			// Transitions might also be non-interactive
	var tableView: UITableView! { get set }						// Scroll view offset is used to trigger pull to pop
	
	func scrollViewDidScroll(_ scrollView: UIScrollView)		// UIScrollViewDelegate function that is required
}

// MARK: -

open class PullToPopTableViewController: UITableViewController, PullTransitionPanning, PullToPop {
	var pullTransitionDelegate: UINavigationControllerDelegate?
	
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
	
	// UITableViewController
	
	override open func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Save the PullTransition delegate in case the navigation controller delegate is changed from underneath us.
		if (self.navigationController?.delegate as? PullTransition) != nil {
			pullTransitionDelegate = self.navigationController?.delegate
		}
		else {
			if pullTransitionDelegate != nil {
				self.navigationController?.delegate = pullTransitionDelegate
			}
		}
	}
	
	// PullToPop
	
	var isTransitioning = false
	var interactiveTransitionEnabled = false

	override open func scrollViewDidScroll(_ scrollView: UIScrollView) {
		// This pattern is recommended when using PullTransitions and popping a UITableViewController
		if !isTransitioning {
			interactiveTransitionEnabled = true
			
			isTransitioning = self.hasBeenPopped(completion: { [weak self] in
				self?.isTransitioning = false
				self?.interactiveTransitionEnabled = false
			})
			
			// Execute children-defined code
			if isTransitioning {
				self.willPullToPop()
			}
			
			interactiveTransitionEnabled = isTransitioning
		}
	}
	
	// Virtual functions
	
	func willPullToPop() {}
 }

// MARK: -
// PullToPopViewController is useful instances where a UITableView is used without a UITableViewController

open class PullToPopViewController: UIViewController, PullTransitionPanning, PullToPop {
	var pullTransitionDelegate: UINavigationControllerDelegate?
	
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
	
	// UIViewController
	
	override open func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Save the PullTransition delegate in case the navigation controller delegate is changed from underneath us.
		if (self.navigationController?.delegate as? PullTransition) != nil {
			pullTransitionDelegate = self.navigationController?.delegate
		}
		else {
			if pullTransitionDelegate != nil {
				self.navigationController?.delegate = pullTransitionDelegate
			}
		}
	}
	
	// PullToPop

	var isTransitioning = false
	var interactiveTransitionEnabled = false
	@IBOutlet public var tableView: UITableView!
	
	open func scrollViewDidScroll(_ scrollView: UIScrollView) {
		// This pattern is recommended when using PullTransitions and popping a UITableViewController
		if !isTransitioning {
			interactiveTransitionEnabled = true
			
			if let tableView = scrollView as? UITableView {
				isTransitioning = hasBeenPopped(tableView: tableView, completion: { [weak self] in
					self?.isTransitioning = false
					self?.interactiveTransitionEnabled = false
				})
			}
			
			// Execute children-defined code
			if isTransitioning {
				self.willPullToPop()
			}
			
			interactiveTransitionEnabled = isTransitioning
		}
	}
	
	// Virtual functions
	
	func willPullToPop() {}
}

