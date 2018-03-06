//
//  PullToPopViewController.swift
//  PullTransition
//
//  Created by Aleksey Novicov on 1/17/18.
//  Copyright © 2018 Aleksey Novicov. All rights reserved.
//

import UIKit

public extension UITableViewController {
	
	@objc func pullNavigationDelegate() -> PullTransition? {
		return self.navigationController?.delegate as? PullTransition
	}
	
	@objc func hasBeenPopped(completion: (() -> Swift.Void)? = nil) -> Bool {
		let statusBarHeight 		= UIApplication.shared.statusBarFrame.size.height
		var navbarHeight: CGFloat 	= 0.0
		var hasBeenPopped			= false
		
		if let navController = self.navigationController {
			navbarHeight = navController.navigationBar.frame.size.height
		}
		
		let contentOffset = -tableView.contentOffset.y - (statusBarHeight + navbarHeight)
		let velocity = tableView.panGestureRecognizer.velocity(in: tableView.superview)

		if contentOffset > pullThreshold() && velocity.y > 0 && !isMovingFromParentViewController {
			
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
					let startPosition = CGPoint(x: 0, y: -(statusBarHeight + navbarHeight))
					
					delegate.animatedTransition?.startPosition = startPosition
					delegate.animatedTransition?.offsetError = contentOffset

					hasBeenPopped = true
				}
			}
		}
		return hasBeenPopped
	}
}

open class PullToPopViewController: UITableViewController, PullTransitionPanning {
	// Needed to ensure view controller is not repeatedly dismissed while interactive transition is in progress
	var isTransitioning = false
	var interactiveTransitionEnabled = false
	
	var pullTransitionDelegate: UINavigationControllerDelegate?
	
	// MARK: - PullTransitionPanning
	
	public var panGestureRecognizer: UIPanGestureRecognizer? {
		get {
			// Random problems have been observed with iOS 10. Works better if not interactive.
			if #available(iOS 11, *) {
				
				if interactiveTransitionEnabled {
					return self.tableView.panGestureRecognizer
				}
			}
			return nil
		}
	}
	
	// MARK: - UITableViewController
	
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
	
	// MARK: - Virtual functions
	
	func willPullToPop() {}

 }
