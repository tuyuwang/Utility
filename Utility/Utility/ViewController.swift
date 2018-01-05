//
//  ViewController.swift
//  Utility
//
//  Created by Mac on 2017/12/28.
//  Copyright © 2017年 MYXG. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        utility()
        
//        alamofire()

    }

    fileprivate func utility() {
    
        let diys = [1, 2, 3, 4]
        
        diys.accumulate(0, +)
        
        diys.accumulate(2) { (a, b) -> Int in
        return a + b
        }
        
        diys.reduce(0, +)
        
        diys.forEach { diy in
        //            print(diy)
        }
        
        view.backgroundColor = "#bac8e1".ul.hex
        
        let str = "12345678"
        print(str.dropLast(2))
        
        let array = Array(str)
        
        print(String(array[0..<2]))
        
        
        print("md5: \(str.ul.md5)")
        print("md5: \(str.ul.md5.data!)")

        print("img: \("2".ul.img!)")
        
        let float: CGFloat = 2
        
        print("CGFloat: \(float.ul.vpx)")
        print("CGFloat: \(CGFloat(float.hashValue))")

        let md5 = str.ul.md5
        print(md5)
        
        print(100.ul.vpx)
        print(100.ul.hpx)
        print(2.0.ul.vpx)
        
        
        print("12333".ul.isPhone)
        print("@163.com".ul.isEmail)
        print("_aas".ul.isName)
        print("123456".ul.isPassword)
        print("3508211993110".ul.isIDCard)
        
        for prefix in PrefixSequence(string: "Hello") {
            print(prefix)
        }
        let dic = ["A": "a", "B": "b", "C": ["1", "2", "3"]] as [String : Any]
        let json = JSON(dic)
        print(json["C"])
        
        let test = Test(dic)
        print(test["C", 1])
        
        let hf = [1, 2, 3, 4, 3, 2, 1].headMirrorsTail(2)
        print(hf)
        
    }
    
    fileprivate func alamofire() {
        Alamofire.request("https://httpbin.org/get").responseJSON { (response) in
            
            debugPrint("All Response Info: \(response)")
            
            print("Request: \(String(describing: response.request))")
            print("Response: \(String(describing: response.response))")
            print("Result: \(String(describing: response.result))")

            if let json  = response.result.value {
                print("JOSN: \(json)")
            }
            
            if let data = response.data, let utf8Text = String.init(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)")
            }
        }
        
        //more handler
        Alamofire.request("https://httpbin.org/get").responseString { (response) in
            print("Success: \(response.result.isSuccess)")
            print("Response String: \(response.result.value!)")
            }
            .responseJSON { (response) in
                print("Response JSON: \(response.result.value!)")
        }
        
        //validation
        Alamofire.request("https://httpbin.org/get")
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData { (response) in
                switch response.result {
                case .success:
                    print("Validation Successful")
                case .failure(let error):
                    print(error)
                }
        }
        
        //encoding
        Alamofire.request("https://httpbin.org/get", method: .get, encoding: JSONEncoding.default).responseJSON { (response) in
            print(response.result.value!)
            print(JSON(response.result.value!))
        }
    }

}

enum TestType {
    case array
    case dictionary
    case null
}
struct Test {
    var type: TestType { return _type}
    fileprivate var _type: TestType = .null
    fileprivate var rawArray: [Any] = []
    fileprivate var rawDictionary: [String: Any] = [:]
    fileprivate var rawNull: NSNull = NSNull()
    
    init(_ object: Any) {
        switch object {
        case let object as [Test] where object.count > 0:
            self.init(array: object)
        case let object as [String: Test]  where object.count > 0:
            self.init(dictionary: object)
        default:
            self.init(jsonObject: object)
        }
    }
    
    init(array: [Test]) {
        self.init(array.map{ $0.object})
    }
    
    init(dictionary: [String: Test]) {
        var newDicitonary = [String: Any](minimumCapacity: dictionary.count)
        for (key, json) in dictionary {
            newDicitonary[key] = json.object
        }
        self.init(newDicitonary)
    }
    
    init(jsonObject: Any) {
        self.object = jsonObject
    }
    
    var object: Any {
        get {
            switch self.type {
            case .array:
                return self.rawArray
            case .dictionary:
                return self.rawDictionary
            default:
                return self.rawNull
            }
        }
        
        set {
            switch newValue {
            case let array as [Any]:
                _type = .array
                self.rawArray = array
            case let dictionary as [String: Any]:
                _type = .dictionary
                self.rawDictionary = dictionary
            default:
                _type = .null
            }
        }
    }
    
}

extension Test {
    public subscript(path: JSONSubscriptType...) -> Test {
        get {
            return self[path]
        }
        
        set {
            self[path] = newValue
        }
    }
    
    public subscript(path: [JSONSubscriptType]) -> Test {
        get {
            return path.reduce(self) { $0[sub: $1] }
        }
        
        set {
            switch path.count {
            case 0: return
            case 1: self[sub:path[0]].object = newValue.object
            default:
                var aPath = path; aPath.remove(at: 0)
                var nextTest = self[sub: path[0]]
                nextTest[aPath] = newValue
                self[sub: path[0]] = nextTest
                
                
            }
        }
    }
    
    fileprivate subscript(sub sub: JSONSubscriptType) -> Test {
        get {
            switch sub.jsonKey {
            case .index(let index): return self[index: index]
            case .key(let key): return self[key: key]
            }
        }
        
        set {
            switch sub.jsonKey {
            case .index(let index): self[index: index] = newValue
            case .key(let key): self[key: key] = newValue
            }
        }
    }
    
    fileprivate subscript(index index: Int) -> Test {
        get {
            if self.type == .array {
                if index >= 0 && index < self.rawArray.count {
                    return Test(self.rawArray[index])
                }else
                {
                    return Test(NSNull())
                }
            }else {
                return Test(NSNull())
            }
        }
        
        set {
            if self.type == .array {
                if self.rawArray.count > index {
                    self.rawArray[index] = newValue.object
                }
            }
        }
    }
    
    fileprivate subscript(key key: String) -> Test {
        
        get {
            var t = Test(NSNull())
            
            if self.type == .dictionary {
                if let o = self.rawDictionary[key] {
                    t = Test(o)
                }
            }
            
            return t
        }
        
        set {
            if self.type == .dictionary {
                self.rawDictionary[key] = newValue.object
            }
        }
    }
}


// -----

//判断一个序列的开头和结尾是否以同样的n个元素开始
extension Sequence
    where Iterator.Element: Equatable,
    SubSequence: Sequence,
    SubSequence.Iterator.Element == Iterator.Element
{
    func headMirrorsTail(_ n: Int) -> Bool {
        let head = prefix(n)
        let tail = suffix(n).reversed()
        return head.elementsEqual(tail)
    }
}

// -----

///一个能够将元素入队和出队的类型
protocol Queue {
    
    ///在self中所持有的元素的类型
    associatedtype Element
    
    ///将newElement入队到self
    mutating func enqueue(_ newElement: Element)
    
    ///从self出队一个元素
    mutating func dequeue() -> Element?
}
