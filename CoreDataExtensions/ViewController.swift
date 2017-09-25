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
                         "parent": ["id": i,
                                    "name": "Li gang",
                                    "age": 50]] as [String : Any]
            dicts.append(dict)
        }
        return dicts
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func saveInMainContext(_ sender: Any) {
        Person.save(by: .mainContext, dataCount: dicts.count, completion: {
            self.resultLabel.text = "Save in mainContext is" + ($0 ? "success" : "failed")
        }) { (index, person) in
            person.updateFromDictionary(dict: self.dicts[index])
        }
        
    }
    
    @IBAction func saveInPrivateContext(_ sender: Any) {
        Person.save(by: .privateContext, dataCount: dicts.count, completion: {
            self.resultLabel.text = "Save in privateContext is" + ($0 ? "success" : "failed")
        }) { (index, person) in
            person.updateFromDictionary(dict: self.dicts[index])
        }
    }
    
    @IBAction func deleteAllInMain(_ sender: Any) {
        Person.deleteAll(by: .mainContext) {
            self.resultLabel.text = "Delete in mainContext is" + ($0 ? "success" : "failed")
        }
    }
    
    @IBAction func deleteAllInPrivate(_ sender: Any) {
        Person.deleteAll(by: .privateContext) {
            self.resultLabel.text = "Delete in privateContext is" + ($0 ? "success" : "failed")
        }
    }
    
    @IBAction func updateInMain(_ sender: Any) {
        let dict = ["id": 1, "name": "Han meimei", "age": 15] as [String : Any]
        let predicate = NSPredicate(format: "id == %ld", 1)
        
        Person.update(by: .mainContext, predicate: predicate, completion: {
            self.resultLabel.text = "Update in mainContext is" + ($0 ? "success" : "failed")
        }) { person in
            person.updateFromDictionary(dict: dict)
        }
    }
    
    @IBAction func updateInPrivate(_ sender: Any) {
        let dict = ["id": 1, "name": "Xiao hong", "age": 15] as [String : Any]
        let predicate = NSPredicate(format: "id == %ld", 1)
        
        Person.update(by: .privateContext, predicate: predicate, completion: {
            self.resultLabel.text = "Update in privateContext is" + ($0 ? "success" : "failed")
        }) { person in
            person.updateFromDictionary(dict: dict)
        }
    }
    
    @IBAction func syncFind(_ sender: Any) {
        let results = Person.findAll()
        resultLabel.text = "Sync find success, count of data: " + String(results.count)
    }
    
    @IBAction func asyncFind(_ sender: Any) {
        Person.asyncFindAll { results in
            self.resultLabel.text = "Async find success, count of data: " + String(results.count)
        }
    }


}

