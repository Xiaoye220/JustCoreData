//
//  ViewController.swift
//  CoreDataExtensions
//
//  Created by YZF on 12/7/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var resultLabel: UILabel!
    
    var dataCount: Int = 10
    
    var dicts: [[String: Any]] {
        var dicts: [[String: Any]] = []
        for i in 1 ... 10 {
            let dict =  ["id": i,
                         "name": "Li lei",
                         "age": 25,
                         "children": [["id": 2*i-1, "name": "Ding ding", "age": 1],
                                      ["id": 2*i, "name": "La la", "age": 2]],
                         "grandFather": ["id": 1,
                                         "name": "Li gang",
                                         "age": 50]] as [String : Any]
            dicts.append(dict)
        }
        return dicts
    }
    
    /*
    let childrenDict = ["id": 1,
                        "name": "Ding ding",
                        "age": 1,
                        "father": ["id": 1,
                                   "name": "Li Lei",
                                   "age": 25,
                                   "grandFather": ["id": 1,
                                                   "name": "Li gang",
                                                   "age": 50]]
                        ] as [String : Any]
    */
    
    let cd = CoreData<Father>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func saveInMainContext(_ sender: Any) {
        cd.concurrencyType(.mainQueue_sync)
            .saveDataCount(10)
            .configure { (index, person) in
                person.updateFromDictionary(dict: self.dicts[index])
            }
            .completion { (success, _) in
                print("\(Thread.current)\nsync save \(success ? "success" : "fail")")
            }
            .save()
    
        print("perform finish")
    }
    
    @IBAction func saveInPrivateContext(_ sender: Any) {
        cd.concurrencyType(.privateQueue_async)
            .saveDataCount(5)
            .configure { (index, person) in
                person.name = "\(index).Han meimei"
            }
            .completion { (success, _) in
                print("\(Thread.current)\nasync save \(success ? "success" : "fail")")
            }
            .save()
        
        print("perform finish")
    }
    
    @IBAction func deleteAllInMain(_ sender: Any) {
        cd.concurrencyType(.mainQueue_sync)
            .fetchRequest { _ in }
            .completion { (success, _) in
                print("\(Thread.current)\nsync delete \(success ? "success" : "fail")")
            }
            .delete()
        
        print("perform finish")
    }
    
    @IBAction func deleteAllInPrivate(_ sender: Any) {
        cd.concurrencyType(.privateQueue_async)
            .fetchRequest { _ in }
            .completion { (success, _) in
                print("\(Thread.current)\nasync delete \(success ? "success" : "fail")")
            }
            .delete()
        
        print("perform finish")
    }
    
    @IBAction func updateInMain(_ sender: Any) {
        cd.concurrencyType(.mainQueue_sync)
            .fetchRequest { request in
                request.predicate(NSPredicate(format: "name = %@", "1.Li lei"))
            }
            .configure { (index, person) in
                person.name = "Bob"
            }
            .completion { (success, _) in
                print("\(Thread.current)\nsync update \(success ? "success" : "fail")")
            }
            .update()
        
        print("perform finish")
    }
    
    @IBAction func updateInPrivate(_ sender: Any) {
        cd.concurrencyType(.privateQueue_async)
            .fetchRequest { request in
                request.predicate(NSPredicate(format: "name = %@", "1.Han meimei"))
            }
            .configure { (index, person) in
                person.name = "Lily"
            }
            .completion { (success, _) in
                print("\(Thread.current)\nasync update \(success ? "success" : "fail")")
            }
            .update()
        
        print("perform finish")
    }
    
    @IBAction func syncFind(_ sender: Any) {
        cd.concurrencyType(.mainQueue_sync)
            .fetchRequest { request in
                request.predicate(NSPredicate(format: "name = %@", "Li lei"))
                    .fetchLimit(1)
                    .resultType(.managedObjectResultType)
            }
            .completion { (success, results) in
                print("\(Thread.current)\nsync find \(success ? "success" : "fail")")
                let persons = results as! [Father]
                print("result count: \(persons.count)")
            }
            .read()
        
        print("perform finish")
    }
    
    @IBAction func asyncFind(_ sender: Any) {
        cd.concurrencyType(.privateQueue_async)
            .fetchRequest { _ in
                //request.predicate(NSPredicate(format: "name = %@", "Li lei"))
            }
            .completion { (success, results) in
                print("\(Thread.current)\nasync find \(success ? "success" : "fail")")
                let persons = results as! [Father]
                print("result count: \(persons.count)")
            }
            .read()
        
        print("perform finish")
    }

    @IBAction func customTest(_ sender: Any) {
        cd.concurrencyType(.mainQueue_sync)
            .fetchRequest { request in
                request.sortDescriptors([NSSortDescriptor(key: "name", ascending: true)])
                    .returnsObjectsAsFaults(false)
                    .includesPropertyValues(true)
            }
            .completion { (success, results) in
                let persons = results as! [Father]
                persons.forEach{print($0.name!)}
            }
            .read()
    }
    
}

