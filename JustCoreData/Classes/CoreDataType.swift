//
//  CoreDataType.swift
//  CoreDataExtensions
//
//  Created by YZF on 15/11/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import Foundation
import CoreData

public protocol CoreDataType: CoreDataConcurrencyType, CoreDataFetchRequestType where ManagedObject: NSManagedObject {
    
    /// The number of data needed to save, default is 1
    var saveDataCount: Int { get set }
    
    /// The number of data should be saved each time, defaut is Int.max
    /// The larger the value, the greater the memory and CPU consumed, but it's more efficient
    var saveBatchSize: Int { get set }
    
    /// Configure the NSManageObject. It is necessary when saving and updating
    var configure: ((_ index: Int, _ entity: ManagedObject) -> Void)? { get set }
    
    /// Resultes will be nil when saving, updating and deleting
    /// Resultes are the result of reading
    var completion: ((_ success: Bool, _ resultes: [Any]?) -> Void)? { get set }
    
    /// Entity objects that need deal directly
    var entities: [ManagedObject] { get set }
    
    @discardableResult
    func save() -> Self
    
    @discardableResult
    func delete() -> Self
    
    @discardableResult
    func update() -> Self
    
    @discardableResult
    func read() -> Self
    
    
    /// Initialize all attributes
    @discardableResult
    func refresh() -> Self
    
    @discardableResult
    func coreDataTypeRefresh() -> Self
}

extension CoreDataType {
    
    @discardableResult
    public func refresh() -> Self {
        self.concurrencyTypeRefresh()
        self.fetchRequestRefresh()
        self.coreDataTypeRefresh()
        return self
    }
    
    @discardableResult
    public func coreDataTypeRefresh() -> Self {
        self.saveDataCount = 1
        self.saveBatchSize = Int.max
        self.configure = nil
        self.completion = nil
        self.entities = []
        return self
    }
}

extension CoreDataType {
    
    @discardableResult
    public func saveDataCount(_ saveDataCount: Int) -> Self {
        self.saveDataCount = saveDataCount
        return self
    }
    
    @discardableResult
    public func saveBatchSize(_ saveBatchSize: Int) -> Self {
        self.saveBatchSize = saveBatchSize
        return self
    }
    
    @discardableResult
    public func configure(_ configure: ((_ index: Int, _ entity: ManagedObject) -> Void)?) -> Self {
        self.configure = configure
        return self
    }
    
    @discardableResult
    public func completion(_  completion: ((_ success: Bool, _ resultes: [Any]?) -> Void)?) -> Self {
        self.completion = completion
        return self
    }
    
    @discardableResult
    public func entities(_ entities: [ManagedObject]) -> Self {
        self.entities = entities
        return self
    }
    
}


