//
//  CoreDataConcurrencyType.swift
//  CoreDataExtensions
//
//  Created by YZF on 14/11/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import Foundation
import CoreData

public protocol CoreDataConcurrencyType: class {
    
    var concurrencyType: ConcurrencyType { get set }
    
    func context() -> NSManagedObjectContext
    func perform(_ closure: @escaping (NSManagedObjectContext) -> Void)
    
    @discardableResult
    func concurrencyTypeRefresh() -> Self
}

extension CoreDataConcurrencyType {
    public func context() -> NSManagedObjectContext {
        switch self.concurrencyType {
        case .mainQueue_sync, .mainQueue_async:
            return CoreDataStack.shared.mainManagedObjectContext
        case .privateQueue_async:
            return CoreDataStack.shared.privateManagedObjectContext
        }
    }
    
    public func perform(_ closure: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.context()
        switch self.concurrencyType {
        case .mainQueue_sync:
            context.performAndWait { closure(context) }
        case .mainQueue_async, .privateQueue_async:
            context.perform { closure(context) }
        }
    }
    
    public func concurrencyTypeRefresh() -> Self {
        self.concurrencyType = .mainQueue_sync
        return self
    }
    
}

extension CoreDataConcurrencyType {
    @discardableResult
    public func concurrencyType(_ concurrencyType: ConcurrencyType) -> Self {
        self.concurrencyType = concurrencyType
        return self
    }
}

