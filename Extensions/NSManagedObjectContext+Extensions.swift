//
//  CoreDataExtension.swift
//
//  Created by YZF on 2016/12/9.
//  Copyright © 2016年 YZF. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    public func insertNewObject<A: NSManagedObject>() -> A where A: ManagedObjectType {
        guard let obj = NSEntityDescription.insertNewObject(forEntityName: A.entityName, into: self) as? A else { fatalError("Wrong object type") }
        return obj
    }
    
    @discardableResult
    public func saveOrRollback() -> Bool {
        do {
            try save()
            return true
        } catch {
            rollback()
            return false
        }
    }
    
    public func fetchManagedObject<A: NSManagedObject>(by request:NSFetchRequest<NSFetchRequestResult>) -> [A] where A: ManagedObjectType {
        guard let result = try! self.fetch(request) as? [A] else { fatalError("Fetched objects have wrong type") }
        return result
    }
    
    public func doFetch(_ request:NSFetchRequest<NSFetchRequestResult>) -> [Any] {
        do {
            let array = try self.fetch(request)
            return array
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    @discardableResult
    public func delete<A: NSManagedObject>(_ entitys: [A]) -> Bool where A: ManagedObjectType {
        for entity in entitys {
            self.delete(entity)
        }
        return saveOrRollback()
    }
    

}
