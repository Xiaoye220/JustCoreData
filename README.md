# CoreDataExtensions

## Usage

### 1.Data Model

先看例子中的 Data Model

![DataModel](https://github.com/Xiaoye220/CoreDataExtensions/blob/master/ScreenShot/DataModel.png)


### 2.实体实现 ManagedObjectType 协议

实体需要实现 ManagedObjectType 协议，协议实现了根据实体名和 NSSortDescriptor 提供多个 NSFetchRequest 模板，并提供了根据 Dictionary 给实体赋值的功能，此处以实体 Person 做例子。

```swift
extension Person: ManagedObjectType {
    // 实体名
    public static var entityName: String {
        return "Person"
    }
    // 默认排序方式
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor.init(key: "id", ascending: true)]
    }
}
```

### 3.给需要提供 Core Data 各种操作的类 实现 CoreDataOperationsType 协议

CoreDataOperationsType 协议实现了 Core Data 的增删改查的基本功能。
此处还是以类 Person 做为实现的类

```swift
extension Person: CoreDataOperationsType {
    // 批量更新每批大小
    public static var fetchBatchSize: Int {
        return 100
    }
    // 操作的实体类
    public typealias ManageObject = Person
}
```
接下来对 CoreData 的操作 Person 就可以通过下面这种方式实现
``` Swift
Person.findAll()
```

或者可以单独实现一个类用于进行 Core Data 的操作，像以下这样子实现
```swift
class CoreDataAPI<E: NSManagedObject>: CoreDataOperationsType where E: ManagedObjectType  {
    
    public static var fetchBatchSize: Int {
        return 100
    }
    
    public typealias ManageObject = E
    
}
```
那么对 CoreData 的操作就该这么实现
```swift
CoreDataAPI<Person>.findAll()
```


### 4.通过 CoreDataOperationsType 协议中的方法操作数据库
以 Person 实现 CoreDataOperationsType 协议为例
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
#### 保存
```swift
/// 保存数据
///
/// - Parameters:
///   - contextType: 并发方式
///   - dataCount: 需要保存数据的条数
///   - saveBatchSize: 多少条数据保存一次
///   - configure: 数据赋值
Person.save(by: .mainContext, dataCount: dicts.count, saveBatchSize: 100, completion: { isSuccess in
    // do something
}, configure: { (index, person) in
    person.updateFromDictionary(dict: self.dicts[index])
})
```
上面 ``person.updateFromDictionary(dict: self.dicts[index])`` 可以根据字典给实体初始化，实体包含关系的话，也可以其中的关系。如上述 dict 中含有 children 和 parent，那个给 Person 实体初始化时可以将 Person 的 children 和 parent 的关系一起实现。

当然也可以通过自己的方式给实体赋值（比如用 MJExtension 等第三方库）。

#### 删除
```swift
/// 删除所有数据
Person.deleteAll(by: .mainContext) { isSuccess in
    // do something
}
```
当然也可以根据谓词删除数据

```swift
public static func delete(by contextType: ContextType, predicate: NSPredicate, completion: @escaping (_ isSuccess: Bool) -> Void = { _ in })
```

#### 更新数据
```swift
let dict = ["id": 1, "name": "Han meimei", "age": 15] as [String : Any]
let predicate = NSPredicate(format: "id == %ld", 1)

// 根据谓词查找数据后更新数据
Person.update(by: .mainContext, predicate: predicate, completion: {
    // do something
}) { person in
    person.updateFromDictionary(dict: dict) //更新为什么数据可以自己实现
}

```

#### 查找数据

```swift
// 同步查找数据，数据量大的时候会阻塞主线程
let results = Person.findAll()

// 异步查找，不会阻塞主线程
Person.asyncFindAll { results in
  // do something
}
```

也可以根据谓词查找，分页查找
```swift
// 谓词查找
public static func find(by predicate: NSPredicate) -> [ManageObject]

public static func asyncFind(by predicate: NSPredicate, completion: @escaping ([ManageObject]) -> Void)

// 分页查找
public static func find(by pageNum: Int, pageSize: Int) -> [ManageObject]
```

除上面的功能外还有一些功能，可以查看协议 CoreDataOperationsType

### 5.NSFetchedResultsController

除了以上功能，对 NSFetchedResultsController 也做了一些封装

#### 使用
``` Swift 
class NSFetchedResultsViewController: UITableViewController {

    var fetchedResultsManager: FetchedResultsManager<Person>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 初始化 FetchedResultsManager，下面就可以直接通过 fetchedResultsManager 实现 tableView 的数据源
        // 任何对 Core Data 的操作可以直接反应在 tableView 上
        fetchedResultsManager = FetchedResultsManager.init(fetchRequest: Person.sortedFetchRequest, contextType: .mainContext, tableView: tableView, sectionName: nil)
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
