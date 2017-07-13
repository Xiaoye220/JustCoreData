//
//  Son.swift
//  CoreDataExtensions
//
//  Created by YZF on 11/7/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import Foundation

extension Children: ManagedObjectType {
    
    public static var entityName: String {
        return "Children"
    }
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor.init(key: "id", ascending: true)]
    }
}

extension Children: CoreDataOperationsType {
    public static var fetchBatchSize: Int {
        return 100
    }
    
    public typealias ManageObject = Children
}
