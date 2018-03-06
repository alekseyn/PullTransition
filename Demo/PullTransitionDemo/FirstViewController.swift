//
//  FirstViewController.swift
//  PullTransitionDemo
//
//  Created by Aleksey Novicov on 12/4/17.
//
// For interactive animation transitions three things are required:
// 	1. An instance of a PullTransitionDelegate
//	2. The presenting view controller must implement PullTransitionPanning protocol
//	3. Ensure PullTransitionDelegate.animatorIsActive is false before presenting a new view controller

import UIKit
import PullTransition

class FirstViewController: UIViewController, PullTransitionPanning {
	
	@IBOutlet weak var scrollSwitch: UISwitch!
	@IBOutlet weak var overlaySwitch: UISwitch!
	@IBOutlet weak var pushSwitch: UISwitch!
	
	lazy var pullTransitionDelegate: PullTransitionDelegate = {
		var mode: PullTransitionMode = .scroll
		
		if scrollSwitch.isOn {
			mode = .scroll
		}
		else if overlaySwitch.isOn {
			mode = .overlay
		}
		else {
			// If no switches are one, set the default switch ON
			scrollSwitch.isOn = true
		}
		
		return  PullTransitionDelegate(mode: mode)
	} ()

	// MARK: - PullTransitionPanning
	
	@IBOutlet weak var panGestureRecognizer: UIPanGestureRecognizer?
	var latestGestureRecognizerState: UIGestureRecognizerState = .possible

	// MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		segue.destination.transitioningDelegate = pullTransitionDelegate
		
		if segue.identifier == "present-demo" {
			if let vc = segue.destination as? SecondViewController {
				vc.mode = pullTransitionDelegate.mode
				vc.usePush 		= pushSwitch.isOn
			}
		}
		if segue.identifier == "push-demo" {
			if let nav = segue.destination as? UINavigationController,
			   let vc = nav.topViewController as? SecondViewController {
				vc.mode = pullTransitionDelegate.mode
				vc.usePush 		= pushSwitch.isOn
			}
		}
    }

	@IBAction func updateMode(_ sender: Any) {
		var mode: PullTransitionMode = .scroll

		if let selectedSwitch = sender as? UISwitch {
			if selectedSwitch === scrollSwitch {
				if selectedSwitch.isOn {
					mode = .scroll
					overlaySwitch.setOn(false, animated: true)
				}
			}
			else  if selectedSwitch === overlaySwitch {
				if selectedSwitch.isOn {
					mode = .overlay
					scrollSwitch.setOn(false, animated: true)
				}
			}
			
			if !overlaySwitch.isOn && !scrollSwitch.isOn {
				scrollSwitch.setOn(true, animated: true)
			}
		}
		pullTransitionDelegate = PullTransitionDelegate(mode: mode)
	}
	
	@IBAction func handlePanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
		// Save the state. Needed to detect interactive transition animations that are invoked
		// after the pan gesture recognizer has ended.
		latestGestureRecognizerState = panGestureRecognizer.state
		
		switch panGestureRecognizer.state {
			
		case .began:
			if !self.pullTransitionDelegate.animatorIsActive {
				if pushSwitch.isOn {
					self.performSegue(withIdentifier: "push-demo", sender: self)
				}
				else {
					self.performSegue(withIdentifier: "present-demo", sender: self)
				}
			}
			
		default:
			break
		}
	}
}

// MARK: - UIGestureRecognizerDelegate

extension FirstViewController: UIGestureRecognizerDelegate {
	
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
			let translation = panGestureRecognizer.translation(in: panGestureRecognizer.view)
			return abs(translation.y) > abs(translation.x)
		}
		return false
	}
}
