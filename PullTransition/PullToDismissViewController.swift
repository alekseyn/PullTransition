//
//  PullToDismissViewController.swift
//  PullTransition
//
//  Created by Aleksey Novicov on 1/9/18.
//  Copyright © 2018 Aleksey Novicov. All rights reserved.
//

import Foundation

public extension UITableViewController {

	@objc func pullThreshold() -> CGFloat {
		return 0.0
	}
	
	@objc func pullTransitioningDelegate() -> PullTransition? {
		var delegate = self.transitioningDelegate as? PullTransition
		
		if 	delegate == nil {
			delegate = self.navigationController?.transitioningDelegate as? PullTransition
		}
		return delegate
	}
	
	@objc func hasBeenDismissed(completion: (() -> Swift.Void)? = nil) -> Bool {
		let statusBarHeight 		= UIApplication.shared.statusBarFrame.size.height
		var navbarHeight: CGFloat 	= 0.0
		var hasBeenDismissed		= false
		
		if let navController = self.navigationController {
			navbarHeight = navController.navigationBar.frame.size.height
		}

		let contentOffset = -tableView.contentOffset.y - (statusBarHeight + navbarHeight)
		let velocity = tableView.panGestureRecognizer.velocity(in: tableView.superview)

		if contentOffset > pullThreshold() && velocity.y > 0 && !isBeingDismissed {
			
			// Don't interfere with the inertial deceleration. The tableview is not decelerating
			// when the user is panning with their finger.
			if !tableView.isDecelerating {
				
				if let delegate = pullTransitioningDelegate(), !delegate.animatorIsActive {
					
					// Stop scrolling
					tableView.setContentOffset(tableView.contentOffset, animated: false)
					
					dismiss(animated: true, completion: { [weak self] in
						// Reset original content offset
						let originalOffset = CGPoint(x: 0, y: -(statusBarHeight + navbarHeight))
						self?.tableView.setContentOffset(originalOffset, animated: true)
						
						completion?()
					})
					
					delegate.animatedTransition?.startPosition	= CGPoint(x: 0, y: -(statusBarHeight + navbarHeight))
					delegate.animatedTransition?.offsetError 	= contentOffset
					
					hasBeenDismissed = true
				}
			}
		}
		return hasBeenDismissed
	}
}


open class PullToDismissViewController: UITableViewController, PullTransitionPanning {
	// Needed to ensure view controller is not repeatedly dismissed while interactive transition is in progress
	var isTransitioning = false
	var interactiveTransitionEnabled = false
	
	// MARK: - PullTransitionPanning
	
	public var onDismiss: (() -> Swift.Void)?
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
	
	// MARK: - Virtual functions
	
	open func willPullToDismiss() {}
}
