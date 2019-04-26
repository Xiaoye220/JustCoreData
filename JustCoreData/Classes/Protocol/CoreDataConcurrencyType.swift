//
//  CoreDataConcurrencyType.swift
//  CoreDataExtensions
//
//  Created by YZF on 14/11/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import Foundation
import CoreData

public enum ConcurrencyType {
    /// private can only be Async
    case `private`
    case mainSync
    case mainAsync
}

public protocol CoreDataConcurrencyType: class {
    
    /// concurrencyType, default is mainSync
    var concurrencyType: ConcurrencyType { get set }
    
    /// get NSManagedObjectContext about concurrencyType
    func context() -> NSManagedObjectContext
    
    /// `performs` or `performAndWait` on the specified context’s queue about concurrencyType
    func perform(_ closure: @escaping (NSManagedObjectContext) -> Void)
    
    @discardableResult
    func concurrencyTypeRefresh() -> Self
}

extension CoreDataConcurrencyType {
    public func context() -> NSManagedObjectContext {
        switch self.concurrencyType {
        case .mainSync, .mainAsync:
            return CoreDataStack.shared.mainManagedObjectContext
        case .private:
            return CoreDataStack.shared.privateManagedObjectContext
        }
    }
    
    public func perform(_ closure: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.context()
        switch self.concurrencyType {
        case .mainSync:
            context.performAndWait { closure(context) }
        case .mainAsync, .private:
            context.perform { closure(context) }
        }
    }
    
    public func concurrencyTypeRefresh() -> Self {
        self.concurrencyType = .mainSync
        return self
    }
    
}

extension CoreDataConcurrencyType {
    
    /// concurrencyType, default is mainSync
    @discardableResult
    public func concurrencyType(_ concurrencyType: ConcurrencyType) -> Self {
        self.concurrencyType = concurrencyType
        return self
    }
}

