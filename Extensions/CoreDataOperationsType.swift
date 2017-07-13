//
//  CoreDataOperationsType.swift
//  CoreDataExtensions
//
//  Created by YZF on 6/7/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import Foundation
import CoreData

public enum ContextType {
    case mainContext
    case privateContext
}

/// 执行增删改查操作
/// 任何 class 实现该协议，指定 ManageObject(需要实现 ManagedObjectType 协议) 类型后可以直接通过静态方法实现增删改查
public protocol CoreDataOperationsType: class {
    associatedtype ManageObject: ManagedObjectType
    
    static var fetchBatchSize: Int { get }
}


extension CoreDataOperationsType where ManageObject: NSManagedObject {
    
    fileprivate static func getContext(by contextType: ContextType) -> NSManagedObjectContext {
        switch contextType {
        case .mainContext:
            return CoreDataStack.shared.mainManagedObjectContext
        case .privateContext:
            return CoreDataStack.shared.privateManagedObjectContext
        }
    }
    
    public static func save(by contextType: ContextType, dataCount: Int, saveBatchSize: Int = 0,
                            completion: @escaping (_ isSuccess: Bool) -> Void = { _ in },
                            configure: @escaping (_ index: Int, _ entity: ManageObject) -> Void) {
        let context = getContext(by: contextType)
        
        context.perform {
            var num = 0
            for i in 0 ..< dataCount {
                let entity: ManageObject = context.insertNewObject()
                configure(i, entity)
                num += 1
                if (saveBatchSize > 0) && (num % saveBatchSize == 0) {
                    if context.saveOrRollback() {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
            if context.saveOrRollback() {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    /// 查找所有数据，主线程同步执行
    ///
    /// - Returns: 所有数据
    public static func findAll() -> [ManageObject] {
        let request = ManageObject.sortedFetchRequest
        request.returnsObjectsAsFaults = false
        request.fetchBatchSize = fetchBatchSize
        let results: [ManageObject] = getContext(by: .mainContext).fetchManagedObject(by: request)
        return results
    }
    
    
    /// 查找所有数据，主线程异步执行
    ///
    /// - Parameter completion: 查找完后的操作
    public static func asyncFindAll(with completion: @escaping ([ManageObject]) -> Void) {
        let request = ManageObject.sortedFetchRequest
        request.returnsObjectsAsFaults = false
        
        let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: request) {
            if let result = $0.finalResult {
                completion(result as! [ManageObject])
            }
        }
        
        try! getContext(by: .mainContext).execute(asyncRequest)
    }
    
    
    /// 查找所有 NSManagedObjectID， 开销非常低
    /// 获取的对象 ID 后可以通过:
    /// - 谓词 ManageObject IN %@ 或
    /// - 上下文的 object(with objectID: NSManagedObjectID) 方法
    ///
    /// 获取数据，在有些场合非常有用
    ///
    /// - Returns: NSManagedObjectID数组
    public static func findAllID() -> [NSManagedObjectID] {
        let request = ManageObject.defaultFetchRequest
        request.resultType = .managedObjectIDResultType
        request.includesPropertyValues = false //只获取ID不匹配数据
        let results = getContext(by: .mainContext).doFetch(request) as! [NSManagedObjectID]
        return results
    }
    
    /// 分页查找数据
    ///
    /// - Parameters:
    ///   - pageNum: 页码
    ///   - pageSize: 页大小
    /// - Returns: 数据
    public static func find(by pageNum: Int, pageSize: Int) -> [ManageObject] {
        let request = ManageObject.sortedFetchRequest
        request.fetchOffset = (pageNum - 1) * pageSize
        request.fetchLimit = pageSize
        let results: [ManageObject] = getContext(by: .mainContext).fetchManagedObject(by: request)
        return results
    }
    
    
    /// 根据谓词同步查找数据
    public static func find(by predicate: NSPredicate) -> [ManageObject] {
        let request = ManageObject.sortedFetchRequestWithPredicate(predicate)
        request.returnsObjectsAsFaults = false
        request.fetchBatchSize = fetchBatchSize
        
        let results: [ManageObject] = getContext(by: .mainContext).fetchManagedObject(by: request)
        return results
    }
    
    
    /// 根据谓词异步查找数据
    ///
    /// - Parameters:
    ///   - completion: 异步查找回调
    public static func asyncFind(by predicate: NSPredicate, completion: @escaping ([ManageObject]) -> Void) {
        let request = ManageObject.sortedFetchRequestWithPredicate(predicate)
        request.returnsObjectsAsFaults = false
        request.fetchBatchSize = fetchBatchSize
        
        let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: request) {
            if let result = $0.finalResult {
                completion(result as! [ManageObject])
            }
        }
        
        try! getContext(by: .mainContext).execute(asyncRequest)
    }
    
    
    /// 根据谓词查找指定数据进行更新
    ///
    /// - Parameters:
    ///   - dictionary: 更新后的数据
    ///   - type: 并发方式
    public static func update(by contextType: ContextType, predicate: NSPredicate,
                              completion: @escaping (_ isSuccess: Bool) -> Void = { _ in },
                              configure: @escaping (ManageObject) -> Void) {
        let request = ManageObject.sortedFetchRequestWithPredicate(predicate)
        request.returnsObjectsAsFaults = true
        request.fetchBatchSize = fetchBatchSize
        
        let context = getContext(by: contextType)
        
        context.perform {
            let results: [ManageObject] = context.fetchManagedObject(by: request)
            for resulst in results {
                configure(resulst)
            }
            if context.saveOrRollback() {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    public static func update(by contextType: ContextType, manageObjects: [ManageObject],
                              completion: @escaping (_ isSuccess: Bool) -> Void = { _ in },
                              configure: @escaping (ManageObject) -> Void) {
        let context = getContext(by: contextType)
        
        context.perform {
            for object in manageObjects {
                configure(object)
            }
            if context.saveOrRollback() {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    
    /// 根据谓词查找指定数据进行删除
    ///
    /// - Parameters:
    ///   - type: 并发方式
    public static func delete(by contextType: ContextType, predicate: NSPredicate, completion: @escaping (_ isSuccess: Bool) -> Void = { _ in }) {
        let request = ManageObject.sortedFetchRequestWithPredicate(predicate)
        request.returnsObjectsAsFaults = true
        request.fetchBatchSize = fetchBatchSize
        
        let context = getContext(by: contextType)
        context.perform {
            let results: [ManageObject] = context.fetchManagedObject(by: request)
            if context.delete(results) {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    public static func delete(by contextType: ContextType, manageObjects: [ManageObject], completion: @escaping (_ isSuccess: Bool) -> Void = { _ in }) {
        let context = getContext(by: contextType)
        context.perform {
            if context.delete(manageObjects) {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    /// 删除所有实体
    ///
    /// - Parameters:
    ///   - type: 并发方式
    public static func deleteAll(by contextType: ContextType, completion: @escaping (_ isSuccess: Bool) -> Void = { _ in }) {
        let request = ManageObject.defaultFetchRequest
        request.returnsObjectsAsFaults = true
        
        let context = getContext(by: contextType)
        context.perform {
            let results: [ManageObject] = context.fetchManagedObject(by: request)
            if context.delete(results) {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    
    /// 获取表共有多少条数据
    ///
    /// - Returns: 数据条数
    public static func getCount() -> Int {
        let request = ManageObject.defaultFetchRequest
        request.resultType = .countResultType
        let result = getContext(by: .mainContext).doFetch(request)[0] as! Int
        return result
    }
}


extension CoreDataOperationsType where ManageObject: NSManagedObject {
    
    /// 查找上下文中已经注册过的对象中是否存在满足谓词的对象，不存在创建一个
    /// 查找可能之前在上下文中注册过且上下文中注册过的对象不是很多的的时候效率很高
    /// 注意：只适用用查询结果有且只有一个
    ///
    /// - Parameters:
    ///   - predicate: 用于匹配对象的谓词
    ///   - configure: 未找到对象新建对象后的配置项
    /// - Returns: 对象
    public static func findOrCreateInContext(by contextType: ContextType, predicate: NSPredicate?, configure: ((ManageObject) -> ())?) -> ManageObject {
        let moc = getContext(by: contextType)
        guard let pre = predicate, let obj = findOrFetchInContext(moc, matchingPredicate: pre) else {
            let newObject: ManageObject = moc.insertNewObject()
            configure?(newObject)
            return newObject
        }
        return obj
    }
    
    /// 查找上下文中是否存在满足谓词的对象，不存在再查找,适用于查询结果有且只有一个
    private static func findOrFetchInContext(_ moc: NSManagedObjectContext, matchingPredicate predicate: NSPredicate) -> ManageObject? {
        guard let obj = materializedObjectInContext(moc, matchingPredicate: predicate) else {
            return fetchInContext(moc) { request in
                request.predicate = predicate
                request.returnsObjectsAsFaults = false
                request.fetchLimit = 1
                }.first
        }
        return obj
    }
    
    private static func fetchInContext(_ context: NSManagedObjectContext, configurationBlock: (NSFetchRequest<NSFetchRequestResult>) -> () = { _ in }) -> [ManageObject] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManageObject.entityName)
        configurationBlock(request)
        let result: [ManageObject] = context.fetchManagedObject(by: request)
        return result
    }
    
    /// 查找上下文中符合谓词并且已经实体化的对象
    private static func materializedObjectInContext(_ moc: NSManagedObjectContext, matchingPredicate predicate: NSPredicate) -> ManageObject? {
        for obj in moc.registeredObjects where !obj.isFault {
            guard let res = obj as? ManageObject, predicate.evaluate(with: res) else { continue }
            return res
        }
        return nil
    }
    
}

