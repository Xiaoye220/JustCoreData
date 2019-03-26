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
    
    public init() {}
    
    public typealias ManagedObject = E
    
    public var concurrencyType: ConcurrencyType = .mainQueue_sync
    
    public var fetchRequest: NSFetchRequest<NSFetchRequestResult>?

    public var saveDataCount: Int = 1
    public var saveBatchSize: Int = Int.max
    
    public var configure: ((Int, E) -> Void)?
    public var completion: ((Bool, [Any]?) -> Void)?
    
    public var entities: [E] = []
    
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
            let request = self.fetchRequest ?? ManagedObject.sortedFetchRequest
            
            let results: [Any] = context.doFetch(request)
            self.completion?(true, results)
            
            self.refresh()
        }
        return self
    }
    
}









