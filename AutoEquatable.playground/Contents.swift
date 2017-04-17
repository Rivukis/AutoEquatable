
protocol _Internal_AutoEquatable {
    func isEqual(other: Any) -> Bool
}

extension _Internal_AutoEquatable {
    func isEqual(other: Any) -> Bool {
        fatalError(cleanedTypeName(of: self) + " should NOT conform to '_Internal_AutoEquatable'. Conform to AutoEquatable instead.")
    }
}

extension _Internal_AutoEquatable where Self: Equatable {
    func isEqual(other: Any) -> Bool {
        guard let castedOther = other as? Self else {
            fatalError("\(other) of reported type \(type(of: other)) is NOT the same type as \(self) of reported type \(type(of: self))")
        }

        print("###### actual comparison of equatables", self, other)
        return self == castedOther

//        return self == other as! Self
    }
}

protocol AutoEquatable_KeepDefaultEquatable: _Internal_AutoEquatable {}

protocol AutoEquatable: Equatable, _Internal_AutoEquatable {}

extension AutoEquatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        let lhsMirror = Mirror(reflecting: lhs)
        let rhsMirror = Mirror(reflecting: rhs)

        let lhsMirrorProperties = lhsMirror.children.map { $0.1 }
        let rhsMirrorProperties = rhsMirror.children.map { $0.1 }

        let zippedProperties = zip(lhsMirrorProperties, rhsMirrorProperties)

        // Note: Don't need to check for tuple here since tuples can not conform to protocols

        for (lhsMirrorProperty, rhsMirrorProperty) in zippedProperties {
            if !isIAEEqual(lhs: lhsMirrorProperty, rhs: rhsMirrorProperty) {
                return false
            }
        }
        
        return true
    }
}

private func isIAEEqual<T>(lhs: T, rhs: T) -> Bool {
    let lhsMirror = Mirror(reflecting: lhs)
    let rhsMirror = Mirror(reflecting: rhs)

    print("lhs", lhs)
    print("lhs displaystyle", "\(lhsMirror.displayStyle)")

    // Can not compare functions, returning true to skip comparison.
    guard String(describing: lhs) != "(Function)" else {
        return true
    }

    // Tuples can not conform to protocols, checking the contents instead.
    guard lhsMirror.displayStyle != .tuple else {
        return isTupleEqual(lhsMirror: lhsMirror, rhsMirror: rhsMirror)
    }

    // Enums
//    guard lhsMirror.displayStyle != .enum else {
//        print("enum", lhs)
//        print(lhsMirror.children.count)
//
//        return true
//    }

    guard let lhsIAE = lhs as? _Internal_AutoEquatable,
          let rhsIAE = rhs as? _Internal_AutoEquatable else {
            let type = cleanedTypeName(of: lhs)
            let message = "Must write an extension for '\(type)' and have it conform to AutoEquatable. (No other work is required for conformance)"
            fatalError(message)
    }


    // Enums
//    print("lhs displaystyle", "\(lhsMirror.displayStyle == .enum)")
//    if lhsMirror.displayStyle == .enum {
//        print("da fuk: ", lhsIAE)
//    }

    return lhsIAE.isEqual(other: rhsIAE)
}

private func isTupleEqual(lhsMirror: Mirror, rhsMirror: Mirror) -> Bool {
    let lhsMirrorProperties = lhsMirror.children.map { $0.1 }
    let rhsMirrorProperties = rhsMirror.children.map { $0.1 }

    let zippedProperties = zip(lhsMirrorProperties, rhsMirrorProperties)

    for (lhsMirrorProperty, rhsMirrorProperty) in zippedProperties {
        if !isIAEEqual(lhs: lhsMirrorProperty, rhs: rhsMirrorProperty) {
            return false
        }
    }

    return true
}

private func cleanedTypeName(of instance: Any) -> String {
    let type = String(describing: type(of: instance))

    if let index = type.characters.index(of: "<") {
        return type[type.startIndex..<index]
    }

    return type
}



// Something that doesn't conform
class ClassThatDoesNotConform {
    let blah: String

    init(blah: String) {
        self.blah = blah
    }
}

// An Enum
// TODO: figure this out!!!!!
// Compiler Error
enum MyEnum: AutoEquatable_KeepDefaultEquatable {
    case one
    case two
}

// Making other types conform
extension String: AutoEquatable {}
extension Int: AutoEquatable {}
extension Double: AutoEquatable {}
extension UInt8: AutoEquatable {}
extension Optional: AutoEquatable {}


// Makeing your types conform
class MyClass: AutoEquatable {
    let name: String
    let age: Int
    let double: Double
    let other: OtherClass?
    let tuple: (Int, String)
//    let tuple: (Int, Int, ClassThatDoesNotConform)
    let closure: (String) -> String = blahString
//    let myEnum: MyEnum


    init(name: String, age: Int, double: Double, other: OtherClass?, blah: String, myEnum: MyEnum) {
        self.name = name
        self.age = age
        self.double = double
        self.other = other
        self.tuple = (4, blah)
//        self.tuple = (4, 5, ClassThatDoesNotConform(blah: blah))
//        self.myEnum = myEnum
    }
}

func blahString(string: String) -> String {
    return string
}

func blah<T>(_ thing: T) -> T {
    return thing
}

// Can still write your own Equatable
class OtherClass: AutoEquatable {
    let name: String
    let otherName: String

    init(name: String, otherName: String) {
        self.name = name
        self.otherName = otherName
    }

//    public static func == (lhs: OtherClass, rhs: OtherClass) -> Bool {
//        return lhs.name == rhs.name
//    }
}



let myClass1 = MyClass(name: "Brian", age: 24, double: 3, other: OtherClass(name: "df", otherName: "asdf"), blah: "blah1", myEnum: .one)
let myClass2 = MyClass(name: "Brian", age: 24, double: 3, other: OtherClass(name: "df", otherName: ""), blah: "blah1", myEnum: .two)

print(myClass1 == myClass2)




//class SomeClass: AutoEquatable {
//    let name: String
//    let int: UInt8
//    let myClass: MyClass
//
//    init(name: String, myClass: MyClass) {
//        self.name = name
//        self.myClass = myClass
//        self.int = 3
//
//    }
//}
//
//
//let some1 = SomeClass(name: "dave", myClass: MyClass(name: "a", age: 12, double: 4, other: nil))
//let some2 = SomeClass(name: "dave", myClass: MyClass(name: "a", age: 12, double: 4, other: nil))
//
//
//print(some1 == some2)



MyEnum.one == MyEnum.two











