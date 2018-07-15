## WARNING

Version 2.2 is experimental. There were previous approaches using a similar approach that proved to not work on some machines / Swift versions. This new approach should be resilient to different Swift versions in how it lays out bytes. However, this version is reliant on how Swift treats enums (with and without associated values) in a Mirror.

If you are having issues please let me know and in the mean time use version 2.1 which relies on description to get the enum case name or version 1.4 which uses a manual approach to dealing with enum equality.

# AutoEquatable

[![Version](https://img.shields.io/cocoapods/v/AutoEquatable.svg?style=flat)](http://cocoapods.org/pods/AutoEquatable)
[![License](https://img.shields.io/cocoapods/l/AutoEquatable.svg?style=flat)](http://cocoapods.org/pods/AutoEquatable)
[![Platform](https://img.shields.io/cocoapods/p/AutoEquatable.svg?style=flat)](http://cocoapods.org/pods/AutoEquatable)

AutoEquatable is a convenient way to conform to the Swift protocol, Equatable.

The `AutoEquatable` protocol works by comparing all stored properties of an object. Can still implement a custom `==()` function and `AutoEquatable` will use that custom implementation instead of `AutoEquatable`'s default property comparison.

## Before AutoEquatable

```swift
class MyClass: Equatable {
    let myString: String
    let myInt: Int
    let myDouble: Double
    let myOptional: String?
    let myTuple: (String, Int)
    let myFunction: (String) -> Bool // functions are ignored when comparing objects
    let myStruct: MyStruct
    let myEnum: MyEnum

    public static func == (lhs: MyClass, rhs: MyClass) -> Bool {
        return lhs.myString == rhs.myString
            && lhs.myInt == rhs.myInt
            && lhs.myDouble == rhs.myDouble
            && lhs.myOptional == rhs.myOptional
            && lhs.myTuple == rhs.myTuple
            && lhs.myStruct == rhs.myStruct
            && lhs.myEnum == rhs.myEnum
    }
}

struct MyStruct: Equatable {
    let aString: String
    let anInt: Int
    let aTuple: (Int, String)

    public static func == (lhs: AStruct, rhs: AStruct) -> Bool {
        return lhs.aString == rhs.aString
            && lhs.anInt == rhs.anInt
            && lhs.aTuple == rhs.aTuple
    }
}

enum MyEnum: Equatable {
    case one
    case two(String)
    case three(String, Int, Double)

    public static func == (lhs: MyEnum, rhs: MyEnum) -> Bool {
        switch (lhs, rhs) {
        case (.one, .one):
            return true
        case (.two(let a), two(let b)):
            return return a == b
        case (.three(let a1, a2, a3), three(let b1, b2, b3)):
            return a1 == b1 && a2 == b2 && a3 == b3

        case (.one, _): return false
        case (.two, _): return false
        case (.three, _): return false
        }
    }
}
```

## After AutoEquatable

```swift
class MyClass: AutoEquatable {
    let myString: String
    let myInt: Int
    let myDouble: Double
    let myOptional: String?
    let myTuple: (String, Int)
    let myFunction: (String) -> Bool // functions are ignored when comparing objects
    let myStruct: MyStruct
    let myEnum: MyEnum
}

struct MyStruct: AutoEquatable {
    let aString: String
    let anInt: Int
    let aTuple: (Int, String)
}

enum MyEnum: AutoEquatable {
    case one
    case two(String)
    case three(String, Int, Double)
}
```

## Optionals

There is no need to have Optional conform to `AutoEquatable` and doing so will result in a fatal error. This is because optionals are already handled by `AutoEquatable` and allowing it will cause side effects.

## Tests

To see and run the tests for `AutoEquatable`. Download the playground and run it. The tests are written using [Deft](https://github.com/Rivukis/Deft).

## Requirements

* Xcode 8 and above
* Swift 3 and above

## Installation

AutoEquatable is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
platform :ios, "9.0"
use_frameworks!

target "<YOUR_TARGET>" do
    pod "AutoEquatable"
end
```

## Author

Brian Radebaugh, rivukis@gmail.com

## License

AutoEquatable is available under the MIT license. See the LICENSE file for more info.
