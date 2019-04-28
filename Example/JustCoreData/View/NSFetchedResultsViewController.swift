//
//  NSFetchedResultsViewController.swift
//  CoreDataExtensions
//
//  Created by YZF on 13/7/17.
//  Copyright © 2017年 Xiaoye. All rights reserved.
//

import UIKit
import JustCoreData

class NSFetchedResultsViewController: UITableViewController {

    var fetchedResultsManager: FetchedResultsManager<Father>!
    let cd = CoreData<Father>()

    override func viewDidLoad() {
        super.viewDidLoad()

        fetchedResultsManager = FetchedResultsManager<Father>(contextType: .private,
                                                              tableView: tableView,
                                                              sectionName: nil,
                                                              cacheName: nil,
                                                              fetchRequestConfigure: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsManager.numberOfSections()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsManager.numberOfRowsInSection(section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "cell")
        }
        let obj = fetchedResultsManager.objectAtIndexPath(indexPath)
        cell?.textLabel?.text = "id: " + String(obj.id) + "  name: " + obj.name!
        return cell!
    }
    
    @IBAction func save(_ sender: Any) {
        cd.concurrencyType(.mainSync)
            .configure { (index, person) in
                person.id = 1000
                person.name = "Lily"
            }
            .save()
    }
    @IBAction func deletePerson(_ sender: Any) {
        cd.concurrencyType(.private)
            .fetchRequest { request in
                request.predicate(NSPredicate.init(format: "name = %@", "Lily"))
            }
            .delete()
    }
 
    
}
