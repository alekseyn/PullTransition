//
//  DetailViewController.swift
//  PullTransitionDemo
//
//  Created by Aleksey Novicov on 1/9/18.
//  Copyright © 2018 Aleksey Novicov. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

	@IBOutlet weak var detailDescriptionLabel: UILabel!

	func configureView() {
		// Update the user interface for the detail item.
		if let detail = detailItem {
		    if let label = detailDescriptionLabel {
		        label.text = detail.timestamp!.description
		    }
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		configureView()
	}

	var detailItem: Event? {
		didSet {
		    // Update the view.
		    configureView()
		}
	}
}

