//
//  FetchedResultsControllerManager.swift
//  文言诗词
//
//  Created by 叶增峰 on 21/2/17.
//  Copyright © 2017年 叶增峰. All rights reserved.
//

import Foundation
import CoreData
import UIKit

private protocol DataProvider: class {
    associatedtype Entity: NSManagedObject
    func sections() -> [NSFetchedResultsSectionInfo]?
    func sectionIndexTitles() -> [String]
    func fetchedObjects() -> [Entity]
    func objectsAtSection(_ section: Int) -> [Entity]
    func objectAtIndexPath(_ indexPath: IndexPath) -> Entity
    func numberOfItemsInSection(_ section: Int) -> Int
    func numberOfSections() -> Int
}


/// 定义所有更新的枚举，附带关联值用于更新UI
private enum FetchedResultsChange<Entity: NSManagedObject> {
    case insert(IndexPath)
    case update(IndexPath)
    case move(IndexPath, IndexPath)
    case delete(IndexPath)
    
    case sectionInsert(Int)
    case sectionDelete(Int)
}

class FetchedResultsManager<Entity: NSManagedObject>:NSObject, NSFetchedResultsControllerDelegate, DataProvider {
    
    fileprivate let fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>
    fileprivate var updates: [FetchedResultsChange<Entity>] = []
    fileprivate let tableView: UITableView
    
    
    /// 初始化 fetchedResultsController
    ///
    /// - Parameters:
    ///   - fetchRequest: fetchRequest必须有NSSortDescriptor，并且第一个 sortDescriptor 的 KeyPath 必须和 sectionName 一致
    ///   - contextType: 上下文
    ///   - tableView: tableView
    ///   - sectionName: 划分 section 的属性名(KeyPath)
    public init(fetchRequest: NSFetchRequest<NSFetchRequestResult>, contextType: ContextType, tableView: UITableView, sectionName: String?) {
        fetchRequest.returnsObjectsAsFaults = false
        
        var context: NSManagedObjectContext
        switch contextType {
        case .mainContext:
            context = CoreDataStack.shared.mainManagedObjectContext
        case .privateContext:
            context = CoreDataStack.shared.privateManagedObjectContext
        }
        //fetchRequest的第一个sortDescriptor必须和 sectionName 一致
        fetchedResultsController = NSFetchedResultsController.init(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionName, cacheName: nil)
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
    
    public func sections() -> [NSFetchedResultsSectionInfo]? {
        guard let results = fetchedResultsController.sections else { return [] }
        return results
    }
    public func sectionIndexTitle(_ section: Int) -> String? {
        guard let result = fetchedResultsController.sections?[section] else {return nil}
        return result.indexTitle
    }
    public func sectionIndexTitles() -> [String] {
        let results = fetchedResultsController.sectionIndexTitles
        return results
    }
    
    public func fetchedObjects() -> [Entity] {
        guard let results = fetchedResultsController.fetchedObjects as? [Entity] else { fatalError("Unexpected objects") }
        return results
    }
    
    public func objectsAtSection(_ section: Int) -> [Entity] {
        guard let result = fetchedResultsController.sections?[section] else { return [] }
        return result.objects as! [Entity]
    }
    
    public func objectAtIndexPath(_ indexPath: IndexPath) -> Entity {
        guard let result = fetchedResultsController.object(at: indexPath) as? Entity else { fatalError("Unexpected object at \(indexPath)") }
        return result
    }
    
    public func numberOfItemsInSection(_ section: Int) -> Int {
        guard let sec = fetchedResultsController.sections?[section] else { return 0 }
        return sec.numberOfObjects
    }
    
    public func numberOfSections() -> Int {
        guard let num = fetchedResultsController.sections?.count else {return 0}
        return num
    }
    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updates = []
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
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
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            updates.append(.sectionInsert(sectionIndex))
        case .update:
            break
        case .move:
            break
        case .delete:
            updates.append(.sectionDelete(sectionIndex))
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateTableView()
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
