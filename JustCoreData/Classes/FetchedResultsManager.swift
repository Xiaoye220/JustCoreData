//
//  FetchedResultsControllerManager.swift
//
//  Created by YZF on 21/2/17.
//  Copyright © 2017年 YZF. All rights reserved.
//

import Foundation
import CoreData
import UIKit

private protocol DataProvider: class {
    associatedtype E: NSManagedObject
    func numberOfSections() -> Int
    func numberOfRowsInSection(_ section: Int) -> Int
    func sectionTitle(_ section: Int) -> String?
    func sectionTitles() -> [String]
    func objects() -> [E]
    func objectsAtSection(_ section: Int) -> [E]
    func objectAtIndexPath(_ indexPath: IndexPath) -> E
}


private enum FetchedResultsChange<E: NSManagedObject> {
    case insert(IndexPath)
    case update(IndexPath)
    case move(IndexPath, IndexPath)
    case delete(IndexPath)
    
    case sectionInsert(Int)
    case sectionDelete(Int)
}

public class FetchedResultsManager<E: NSManagedObject & ManagedObjectType>:NSObject, NSFetchedResultsControllerDelegate, DataProvider {
    
    fileprivate let fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>
    fileprivate var updates: [FetchedResultsChange<E>] = []
    fileprivate let tableView: UITableView
    
    
    /// init fetchedResultsController
    ///
    /// - Parameters:
    ///   - fetchRequest: fetchRequest's sortDescriptors can't be nil，and first sortDescriptor's KeyPath should same as sectionName
    ///   - contextType: the context that will hold the fetched objects
    ///   - tableView: tableView
    ///   - sectionName: keypath on resulting objects that returns the section name. This will be used to pre-compute the section information.
    ///   - cacheName: Section info is cached persistently to a private file under this name. Cached sections are checked to see if the time stamp matches the store, but not if you have illegally mutated the readonly fetch request, predicate, or sort descriptor.
    public init(contextType: ContextType, tableView: UITableView, sectionName: String?, cacheName: String?, fetchRequestConfigure: ((NSFetchRequest<NSFetchRequestResult>) -> Void)?) {
        
        let fetchRequest = E.sortedFetchRequest
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequestConfigure?(fetchRequest)
        
        var context: NSManagedObjectContext
        switch contextType {
        case .mainContext:
            context = CoreDataStack.shared.mainManagedObjectContext
        case .privateContext:
            context = CoreDataStack.shared.privateManagedObjectContext
        }

        fetchedResultsController = NSFetchedResultsController.init(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionName, cacheName: cacheName)
        self.tableView = tableView
        super.init()
        fetchedResultsController.delegate = self
    
        do {
            try fetchedResultsController.performFetch()
        } catch {
            let nserror = error as NSError
            fatalError("NSFetchedResultsController error \(nserror), \(nserror.userInfo)")
        }
    }
    
    public func numberOfSections() -> Int {
        guard let num = fetchedResultsController.sections?.count else {return 0}
        return num
    }
    
    public func numberOfRowsInSection(_ section: Int) -> Int {
        guard let sec = fetchedResultsController.sections?[section] else { return 0 }
        return sec.numberOfObjects
    }
    
    public func sectionTitle(_ section: Int) -> String? {
        guard let result = fetchedResultsController.sections?[section] else {return nil}
        return result.indexTitle
    }
    
    public func sectionTitles() -> [String] {
        let results = fetchedResultsController.sectionIndexTitles
        return results
    }
    
    public func objects() -> [E] {
        guard let results = fetchedResultsController.fetchedObjects as? [E] else { fatalError("Unexpected objects") }
        return results
    }
    
    public func objectsAtSection(_ section: Int) -> [E] {
        guard let result = fetchedResultsController.sections?[section] else { return [] }
        return result.objects as! [E]
    }
    
    public func objectAtIndexPath(_ indexPath: IndexPath) -> E {
        guard let result = fetchedResultsController.object(at: indexPath) as? E else { fatalError("Unexpected object at \(indexPath)") }
        return result
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updates = []
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let indexPath = newIndexPath else { fatalError("Index path should be not nil") }
            updates.append(.insert(indexPath))
        case .update:
            guard let indexPath = indexPath else { fatalError("Index path should be not nil") }
            updates.append(.update(indexPath))
        case .move:
            guard let indexPath = indexPath else { fatalError("Index path should be not nil") }
            guard let newIndexPath = newIndexPath else { fatalError("New index path should be not nil") }
            updates.append(.move(indexPath, newIndexPath))
        case .delete:
            guard let indexPath = indexPath else { fatalError("Index path should be not nil") }
            updates.append(.delete(indexPath))
        @unknown default:
            fatalError("NSFetchedResultsChangeType is a unknown value")
        }
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            updates.append(.sectionInsert(sectionIndex))
        case .update:
            break
        case .move:
            break
        case .delete:
            updates.append(.sectionDelete(sectionIndex))
        @unknown default:
            fatalError("NSFetchedResultsChangeType is a unknown value")
        }
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.updateTableView()
        }
    }
    
    private func updateTableView() {
        tableView.beginUpdates()
        for update in updates {
            switch update {
            case .insert(let indexPath):
                tableView.insertRows(at: [indexPath], with: .fade)
            case .update(let indexPath):
                tableView.reloadRows(at: [indexPath], with: .fade)
            case .move(let indexPath, let newIndexPath):
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.insertRows(at: [newIndexPath], with: .fade)
            case .delete(let indexPath):
                tableView.deleteRows(at: [indexPath], with: .fade)
            case .sectionInsert(let sectionIndex):
                tableView.insertSections(IndexSet.init(integer: sectionIndex), with: .fade)
            case .sectionDelete(let sectionIndex):
                tableView.deleteSections(IndexSet.init(integer: sectionIndex), with: .fade)
            }
        }
        tableView.endUpdates()
    }
    
}
