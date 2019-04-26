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
    
    /// update NSManagedObject with dict
    func updateFromDictionary(dict: [String: Any])
}


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
}


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
        predicateFormat = String(predicateFormat[..<index])
        //predicateFormat = predicateFormat.substring(to: index)
        
        let predicate = NSPredicate(format: predicateFormat, argumentArray: args)
        
        let object = findOrCreateInContext(predicate, moc: self.managedObjectContext!, entityName: entity.managedObjectClassName) { obj in
            guard let obj = obj as? ManagedObjectType else {
                fatalError("\(entity.managedObjectClassName!) dose not implement ManagedObjectType")
            }
            obj.updateFromDictionary(dict: dict)
        }
        
        return object
    }
    
}



extension ManagedObjectType where Self: NSManagedObject{
    
    fileprivate func findOrCreateInContext(_ predicate: NSPredicate,
                                  moc: NSManagedObjectContext,
                                  entityName: String,
                                  configure:((NSManagedObject) -> Void)?) -> NSManagedObject {

        guard let obj = fetchInContext(moc, matchingPredicate: predicate, entityName: entityName) else {
            let newObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: moc)
            configure?(newObject)
            return newObject
        }
        return obj
    }

    fileprivate  func fetchInContext(_ moc: NSManagedObjectContext, matchingPredicate predicate: NSPredicate, entityName: String) -> NSManagedObject? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = predicate
        request.returnsObjectsAsFaults = false
        request.fetchLimit = 1
        
        return (moc.doFetch(request) as? [NSManagedObject])?.first
    }
    
}




