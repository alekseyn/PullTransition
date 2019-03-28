//
//  SecondViewController.swift
//  PullTransitionDemo
//
//  Created by Aleksey Novicov on 12/23/17.
//
// For interactive animation transitions three things are required:
// 	1. 	An instance of a PullTransitionDelegate
//	2. 	The presenting view controller must implement PullTransitionPanning protocol
//	3. 	Ensure PullTransitionDelegate.animatorIsActive is false before presenting or pushing
//	  	a new view controller.

import UIKit
import PullTransition

class SecondViewController: UIViewController, PullTransitionPanning {
	
	var usePush = false								// true if we use push/pop instead of present/dismiss
	var busyDismissing = false
	var mode = PullTransitionMode.scroll

	let appDelegate = {
		return UIApplication.shared.delegate as! AppDelegate
	} ()

	lazy var pullTransitionDelegate: PullTransitionDelegate = {
		return PullTransitionDelegate(mode: mode)
	} ()

	// MARK: - PullTransitionPanning
	
	@IBOutlet weak var panGestureRecognizer: UIPanGestureRecognizer?
	var latestGestureRecognizerState: UIGestureRecognizer.State = .possible
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "present-master",
			let nav = segue.destination as? UINavigationController,
			let masterViewController = nav.topViewController as? PresentedMasterViewController {
			
			// Set the transitioningDelegate to invoke interactive custom animation transitions
			nav.transitioningDelegate = pullTransitionDelegate
			
			// Initialize managedObjectContext
			masterViewController.managedObjectContext = appDelegate.persistentContainer.viewContext
		}
		if segue.identifier == "push-master" {
			// Set the navigationController delegate to invoke interactive custom animation transitions
			self.navigationController?.delegate = pullTransitionDelegate
		
			// Initialize managedObjectContext
			if let vc = segue.destination as? PushedMasterViewController {
				vc.managedObjectContext = appDelegate.persistentContainer.viewContext
			}
		}
	}
	
	@IBAction func handlePanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
		// Save the state. Needed to detect interactive transition animations that are invoked
		// after the pan gesture recognizer has ended.
		latestGestureRecognizerState = panGestureRecognizer.state
		
		switch panGestureRecognizer.state {
			
		case .began:
			if !self.pullTransitionDelegate.animatorIsActive && !busyDismissing {
				
				if panGestureRecognizer.velocity(in: panGestureRecognizer.view).vector.dy > 0 {
					busyDismissing = true
					self.dismiss(animated: true, completion: {self.busyDismissing = false} )
				}
				else {
					if usePush {
						self.performSegue(withIdentifier: "push-master", sender: self)
					}
					else {
						self.performSegue(withIdentifier: "present-master", sender: self)
					}
				}
			}
			
		default:
			break
		}
	}
}

// MARK: - UIGestureRecognizerDelegate

extension SecondViewController: UIGestureRecognizerDelegate {
	
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
			let translation = panGestureRecognizer.translation(in: panGestureRecognizer.view)
			return (abs(translation.y) > abs(translation.x))
		}
		return false
	}
}

