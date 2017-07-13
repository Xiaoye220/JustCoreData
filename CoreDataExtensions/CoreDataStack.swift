//
//  CoreDataStack.swift
//
//  Created by YZF on 2016/11/29.
//  Copyright © 2016年 YZF. All rights reserved.
//

import CoreData

class CoreDataStack {
    
    let dataModelName = "Person"
    
    static let shared = CoreDataStack()
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()
    
    
    /// 获取托管对象模型所在的bundle
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: self.dataModelName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    /// 创建持久化存储协调器，在用对象模型初始化它以后，给它添加 NSSQLiteStoreType 的持久化存储。存储的位置由url指定
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        var coordinator = NSPersistentStoreCoordinator.init(managedObjectModel: self.managedObjectModel)
        
        let url = self.applicationDocumentsDirectory.appendingPathComponent(self.dataModelName + ".sqlite")
        print("\(url!)")
        
        var error: NSError? = nil

        do{
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        }catch{
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return coordinator
    }()
    
    /// 使用 .mainQueueConcurrencyType 选项创建主上下文，并赋给persistentStoreCoordinator
    lazy var mainManagedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        
        var managedObjectContext = NSManagedObjectContext.init(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        return managedObjectContext
    }()
    
    /// 创建私有队列上下文，创建的同时添加观察者
    lazy var privateManagedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        
        var managedObjectContext = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        
        managedObjectContext.performAndWait() {
            
            managedObjectContext.persistentStoreCoordinator = coordinator
            
            // Avoid using default merge policy in multi-threading environment:
            // when we delete (and save) a record in one context,
            // and try to save edits on the same record in the other context before merging the changes,
            // an exception will be thrown because Core Data by default uses NSErrorMergePolicy.
            // Setting a reasonable mergePolicy is a good practice to avoid that kind of exception.
            managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
        
        NotificationCenter.default.addObserver(CoreDataStack.shared, selector: #selector(CoreDataStack.contextDidSaveNotificationHandler), name: .NSManagedObjectContextDidSave, object: nil)
        
        return managedObjectContext
    }()
    
    /// Handler for NSManagedObjectContextDidSaveNotification.
    /// Observe NSManagedObjectContextDidSaveNotification and merge the changes to the main context from other contexts.
    /// We rely on this to sync between contexts, thus avoid most of merge conflicts and keep UI refresh.
    /// In the sample code, we don’t edit the main context so not syncing with the private queue context won’t trigger any issue.
    @objc func contextDidSaveNotificationHandler(notification: NSNotification){
        let sender = notification.object as! NSManagedObjectContext
        if sender !== self.mainManagedObjectContext {
            self.mainManagedObjectContext.perform() {
                self.mainManagedObjectContext.mergeChanges(fromContextDidSave: notification as Notification)
            }
        } else {
            self.privateManagedObjectContext.perform() {
                self.privateManagedObjectContext.mergeChanges(fromContextDidSave: notification as Notification)
            }
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(CoreDataStack.shared)
    }
    
}
