# CoreDataExtensions

## Usage

### 1.Data Model

先看例子中的 Data Model

![DataModel](https://github.com/Xiaoye220/CoreDataExtensions/blob/master/ScreenShot/DataModel.png)


### 2.实体实现 ManagedObjectType 协议

实体需要实现 ManagedObjectType 协议，协议实现了根据实体名和默认 NSSortDescriptor ，并提供了根据 Dictionary 给实体赋值的功能，此处以实体 Person 做例子。

```swift
extension Father: ManagedObjectType {
    public static var entityName: String {
        return "Father"
    }
    
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return []
    }
}
```


### 4.操作数据库
以 Father 实现 CoreDataOperationsType 协议为例
#### 数据源
自定义 dict 用来存储需要进行操作的数据。
```swift
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
```
#### 初始化 CoreData 类
```Swift
let cd = CoreData<Father>()
```

#### 保存
```swift
cd.concurrencyType(.mainQueue_sync)
    .saveDataCount(10)
    .configure { (index, person) in
        person.updateFromDictionary(dict: self.dicts[index])
    }
    .completion { (success, _) in
        print("\(Thread.current)\nsync save \(success ? "success" : "fail")")
    }
    .save()
```
上面 ``person.updateFromDictionary(dict: self.dicts[index])`` 可以根据字典给实体初始化，实体包含关系的话，也可以实现其中的关系。如上述 dict 中含有 children 和 parent，那个给 Person 实体初始化时可以将 Person 的 children 和 parent 的关系一起实现。

当然也可以通过自己的方式给实体赋值。

#### 删除
```swift
cd.concurrencyType(.mainQueue_sync)
    .fetchRequest { _ in }
    .completion { (success, _) in
        print("\(Thread.current)\nsync delete \(success ? "success" : "fail")")
    }
    .delete()
```
fetchRequest 用于选择需要删除的实体


#### 更新数据
```swift
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

```

#### 查找数据


```swift
cd.concurrencyType(.mainQueue_sync)
    .fetchRequest { request in
        request.predicate(NSPredicate(format: "name = %@", "Li lei"))
        .fetchLimit(1)
        .resultType(.managedObjectResultType)
        ......
    }
    .completion { (success, results) in
        print("\(Thread.current)\nsync find \(success ? "success" : "fail")")
        let persons = results as! [Father]
        print("result count: \(persons.count)")
    }
    .read()
```


### 5.NSFetchedResultsController

除了以上功能，对 NSFetchedResultsController 也做了一些封装

#### 使用
``` Swift 
class NSFetchedResultsViewController: UITableViewController {

    var fetchedResultsManager: FetchedResultsManager<Father>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 初始化 FetchedResultsManager，下面就可以直接通过 fetchedResultsManager 实现 tableView 的数据源
        // 任何对 Core Data 的操作可以直接反应在 tableView 上
        fetchedResultsManager = FetchedResultsManager<Father>(contextType: .privateContext, tableView: tableView, sectionName: nil, cacheName: nil, fetchRequestConfigure: nil)
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
        return fetchedResultsManager.numberOfItemsInSection(section)
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
    
}
```
