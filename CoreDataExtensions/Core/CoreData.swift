//
//  CoreDataType.swift
//  CoreDataExtensions
//
//  Created by YZF on 14/11/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import Foundation
import CoreData

final public class CoreData<E: NSManagedObject & ManagedObjectType>: CoreDataType {
    
    typealias ManagedObject = E
    
    var concurrencyType: ConcurrencyType = .mainQueue_sync
    
    var fetchRequest: NSFetchRequest<NSFetchRequestResult>?

    var saveDataCount: Int = 1
    var saveBatchSize: Int = Int.max
    
    var configure: ((Int, E) -> Void)?
    var completion: ((Bool, [Any]?) -> Void)?
    
    var entities: [E] = []
    
}

extension CoreData {
    
    @discardableResult
    public func save() -> Self {
        self.perform { context in
            var entityCount = 0
            for i in 0 ..< self.saveDataCount {
                guard let configure = self.configure else { break }
                let entity: ManagedObject = context.insertNewObject()
                configure(i, entity)
                entityCount += 1
                if entityCount % self.saveBatchSize == 0 {
                    let success = context.saveOrRollback()
                    self.completion?(success, nil)
                }
            }
            let success = context.saveOrRollback()
            self.completion?(success, nil)
            
            self.refresh()
        }
        return self
    }
    
    
    @discardableResult
    public func delete() -> Self {
        self.perform { context in
            if let request = self.fetchRequest {
                let results: [ManagedObject] = context.fetchManagedObject(by: request)
                context.delete(results)
            }
            context.delete(self.entities)
            
            let success = context.saveOrRollback()
            self.completion?(success, nil)
            
            self.refresh()
        }
        return self
    }
    
    @discardableResult
    public func update() -> Self {
        self.perform { context in
            if let request = self.fetchRequest {
                let results: [ManagedObject] = context.fetchManagedObject(by: request)
                for (index, r) in results.enumerated() {
                    guard let configure = self.configure else { break }
                    configure(index, r)
                }
            }
            
            for (index, r) in self.entities.enumerated() {
                guard let configure = self.configure else { break }
                configure(index, r)
            }
            
            let success = context.saveOrRollback()
            self.completion?(success, nil)
            
            self.refresh()
        }
        return self
    }
    
    @discardableResult
    public func read() -> Self {
        self.perform { context in
            guard let request = self.fetchRequest else { fatalError("fetchRequest can not be nil") }
            
            let results: [Any] = context.doFetch(request)
            self.completion?(true, results)
            
            self.refresh()
        }
        return self
    }
    
}









