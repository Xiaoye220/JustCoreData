//
//  ManagedObjectType.swift
//
//  Created by YZF on 2016/12/14.
//  Copyright © 2016年 YZF. All rights reserved.
//

import Foundation
import CoreData

public protocol ManagedObjectType: class  {
    
    static var entityName: String { get }
    static var defaultSortDescriptors: [NSSortDescriptor] { get }
    
    func updateFromDictionary(dict: [String: Any])
    
}


/// 构建通用的 request 用于查询
extension ManagedObjectType {
    
    /// default fetchReuest
    public static var defaultFetchRequest: NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        return request
    }
    
    
    /// fetchReuest with defaultSortDescriptors
    public static var sortedFetchRequest: NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.sortDescriptors = defaultSortDescriptors
        return request
    }
    
    
    /// fetchReuest with NSPredicate
    public static func fetchRequestWithPredicate(format predicateFormat: String, args: CVarArg...) -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = withVaList(args) { NSPredicate(format: predicateFormat, arguments: $0) }
        return request
    }
    
    public static func fetchRequestWithPredicate(_ predicate: NSPredicate) -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = predicate
        return request
    }
    
    /// fetchReuest with defaultSortDescriptors & NSPredicate
    public static func sortedFetchRequestWithPredicate(format predicateFormat: String, args: CVarArg...) -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.sortDescriptors = defaultSortDescriptors
        request.predicate = withVaList(args) { NSPredicate(format: predicateFormat, arguments: $0) }
        return request
    }
    
    public static func sortedFetchRequestWithPredicate(_ predicate: NSPredicate) -> NSFetchRequest<NSFetchRequestResult>  {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.sortDescriptors = defaultSortDescriptors
        request.predicate = predicate
        return request
    }
    
}


/// 使用 dict 更新属性
extension ManagedObjectType where Self: NSManagedObject {
    
    public func updateFromDictionary(dict: [String: Any]) {
        for (name, _) in self.entity.attributesByName {
            if let value = dict[name] {
                setValue(value, forKey: name)
            }
        }
        for (name, relationship) in self.entity.relationshipsByName {
            if let destinationEntity = relationship.destinationEntity {
                if !relationship.isToMany {
                    if let relativeDict = dict[name] as? [String : Any] {
                        
                        if let object = findOrCreate(with: destinationEntity, dict: relativeDict) {
                            setValue(object, forKey: name)
                        }
                    }
                } else {
                    if let relativeDicts = dict[name] as? [[String : Any]] {
                        var relativeSet: Set<NSManagedObject> = Set()
                        
                        for relativeDict in relativeDicts {
                            if let object = findOrCreate(with: destinationEntity, dict: relativeDict) {
                                relativeSet.insert(object)
                            }
                        }
                        
                        if !relativeSet.isEmpty {
                            setValue(relativeSet, forKey: name)
                        }
                        
                    }
                }
            }
            
        }
    }
    
    private func findOrCreate(with entity: NSEntityDescription, dict: [String: Any]) -> NSManagedObject? {
        var predicateFormat = String()
        var args: [Any] = []
        
        for (name, attr) in entity.attributesByName {
            if let value = dict[name] {
                switch attr.attributeType {
                case .integer16AttributeType, .integer32AttributeType, .integer64AttributeType:
                    predicateFormat += name + " == %ld and "
                case .floatAttributeType:
                    predicateFormat += name + " == %a and "
                case .doubleAttributeType:
                    predicateFormat += name + " == %la and "
                default:
                    predicateFormat += name + " == %@ and "
                }
                args.append(value)
            }
        }
        let index = predicateFormat.index(predicateFormat.endIndex, offsetBy: -5)
        predicateFormat = predicateFormat.substring(to: index)
        
        let predicate = NSPredicate(format: predicateFormat, argumentArray: args)
        
        let object = findOrCreate(predicate, moc: managedObjectContext!, entityName: entity.managedObjectClassName)
        if let relativeObject = object.object as? ManagedObjectType {
            if !object.isFind {
                relativeObject.updateFromDictionary(dict: dict)
            }
            return relativeObject as? NSManagedObject
        }
        return nil
    }
    
}



/// updateFromDictionary 中建立关系需要使用到的方法
extension ManagedObjectType where Self: NSManagedObject{
    
    fileprivate func findOrCreate(_ predicate: NSPredicate?,
                                  moc: NSManagedObjectContext,
                                  entityName: String) -> (object: NSManagedObject, isFind: Bool) {
        
        guard let pre = predicate, let obj = findOrFetch(moc, matchingPredicate: pre, entityName: entityName) else {
            let newObject: NSManagedObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: moc)
            return (newObject, false)
        }
        return (obj, true)
    }
    
    fileprivate  func findOrFetch(_ moc: NSManagedObjectContext, matchingPredicate predicate: NSPredicate, entityName: String) -> NSManagedObject? {
        return fetchInContext(moc, entityName: entityName) { request in
            request.predicate = predicate
            request.returnsObjectsAsFaults = false
            request.fetchLimit = 1
            }.first
    }
    
    fileprivate func fetchInContext(_ moc: NSManagedObjectContext,
                                    entityName: String,
                                    configurationBlock: (NSFetchRequest<NSFetchRequestResult>) -> () = { _ in }) -> [NSManagedObject] {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        configurationBlock(request)
        do {
            let result = try moc.fetch(request) as! [NSManagedObject]
            return result
        } catch  {
            fatalError("Fetched objects have wrong type")
        }
    }
    
    
}




