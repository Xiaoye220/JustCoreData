//
//  Person.swift
//  CoreDataExtensions
//
//  Created by YZF on 4/7/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import Foundation

extension Person: ManagedObjectType {
    
    public static var entityName: String {
        return "Person"
    }
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor.init(key: "id", ascending: true)]
    }
}

extension Person: CoreDataOperationsType {
    public static var fetchBatchSize: Int {
        return 100
    }
    
    public typealias ManageObject = Person
}

