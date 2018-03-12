//
//  PresentedMasterViewController.swift
//  PullTransitionDemo
//
//  Created by Aleksey Novicov on 12/3/17.
//
// Two things are required for interactive animation dismissal of table view controllers:
//	1. 	The presented view controller must subclass PullToDismissTableViewController.
//  2. 	The presented view controller's transitioningDelegate must be set to a PullTransitionDelegate
//	   	before it is presented.

import UIKit
import CoreData
import PullTransition

class PresentedMasterViewController: PullToDismissTableViewController, NSFetchedResultsControllerDelegate {
	var detailViewController: DetailViewController? = nil
	var managedObjectContext: NSManagedObjectContext? = nil
	
	// MARK: - UITableViewController
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let dismissButton = UIBarButtonItem(title: "Dismiss", style: .plain, target: self, action: #selector(dismiss(_:)))
		navigationItem.leftBarButtonItem = dismissButton

		let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
		navigationItem.rightBarButtonItems = [addButton, editButtonItem]
	}

	@objc func dismiss(_ sender: Any) {
		self.dismiss(animated: true, completion: nil)
	}
	
	@objc func insertNewObject(_ sender: Any) {
		let context = self.fetchedResultsController.managedObjectContext
		let newEvent = Event(context: context)
		     
		newEvent.timestamp = Date()

		do {
		    try context.save()
		} catch {
		    // Replace this implementation with code to handle the error appropriately.
		    // fatalError() causes the application to generate a crash log and terminate.
			// You should not use this function in a shipping application.
		    let nserror = error as NSError
		    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
	}

	// MARK: - Segues

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDetail" {
			
		    if let indexPath = tableView.indexPathForSelectedRow {
		    	let object = fetchedResultsController.object(at: indexPath)
		        let controller = segue.destination as! DetailViewController
		        controller.detailItem = object
		        controller.navigationItem.leftItemsSupplementBackButton = true
		    }
		}
	}

	// MARK: - Table View

	override func numberOfSections(in tableView: UITableView) -> Int {
		return fetchedResultsController.sections?.count ?? 0
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let sectionInfo = fetchedResultsController.sections![section]
		return sectionInfo.numberOfObjects
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		let event = fetchedResultsController.object(at: indexPath)
		configureCell(cell, withEvent: event)
		return cell
	}

	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		// Return false if you do not want the specified item to be editable.
		return true
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
		    let context = fetchedResultsController.managedObjectContext
		    context.delete(fetchedResultsController.object(at: indexPath))
		        
		    do {
		        try context.save()
		    } catch {
		        // Replace this implementation with code to handle the error appropriately.
		        // fatalError() causes the application to generate a crash log and terminate.
				// You should not use this function in a shipping application.
		        let nserror = error as NSError
		        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		    }
		}
	}

	func configureCell(_ cell: UITableViewCell, withEvent event: Event) {
		cell.textLabel!.text = event.timestamp!.description
	}

	// MARK: - Fetched results controller

	var fetchedResultsController: NSFetchedResultsController<Event> {
	    if _fetchedResultsController != nil {
	        return _fetchedResultsController!
	    }
	    
	    let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
	    fetchRequest.fetchBatchSize = 20
	    
	    let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
	    fetchRequest.sortDescriptors = [sortDescriptor]
	    
	    let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
	    aFetchedResultsController.delegate = self
	    _fetchedResultsController = aFetchedResultsController
	    
	    do {
	        try _fetchedResultsController!.performFetch()
	    } catch {
	         // Replace this implementation with code to handle the error appropriately.
	         // fatalError() causes the application to generate a crash log and terminate.
			 // You should not use this function in a shipping application.
	         let nserror = error as NSError
	         fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
	    }
	    
	    return _fetchedResultsController!
	}    
	var _fetchedResultsController: NSFetchedResultsController<Event>? = nil

	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
	    tableView.beginUpdates()
	}

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
	    switch type {
	        case .insert:
	            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
	        case .delete:
	            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
	        default:
	            return
	    }
	}

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
	    switch type {
	        case .insert:
	            tableView.insertRows(at: [newIndexPath!], with: .fade)
	        case .delete:
	            tableView.deleteRows(at: [indexPath!], with: .fade)
	        case .update:
	            configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Event)
	        case .move:
	            configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Event)
	            tableView.moveRow(at: indexPath!, to: newIndexPath!)
	    }
	}

	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
	    tableView.endUpdates()
	}
}

