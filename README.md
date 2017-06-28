# AutoEquatable

[![Version](https://img.shields.io/cocoapods/v/AutoEquatable.svg?style=flat)](http://cocoapods.org/pods/AutoEquatable)
[![License](https://img.shields.io/cocoapods/l/AutoEquatable.svg?style=flat)](http://cocoapods.org/pods/AutoEquatable)
[![Platform](https://img.shields.io/cocoapods/p/AutoEquatable.svg?style=flat)](http://cocoapods.org/pods/AutoEquatable)

AutoEquatable is a convenient way to conform to the Swift protocol, Equatable.

The `AutoEquatable` protocol works by comparing all stored properties of an object. Can still implement a custom `==()` function and `AutoEquatable` will use that custom implementation instead of `AutoEquatable`'s default property comparison.

## Conforming to AutoEquatable

```swift
// before AutoEquatable

class MyClass: Equatable {
    let myString: String
    let myInt: Int
    let myDouble: Double
    let myOptional: String?
    let myTuple: (String, Int)
    let myFunction: (String) -> Bool // functions are ignored when comparing objects
    let myStruct: AStruct

    public static func == (lhs: MyClass, rhs: MyClass) -> Bool {
        return lhs.myString == rhs.myString
            && lhs.myInt == rhs.myInt
            && lhs.myDouble == rhs.myDouble
            && lhs.myOptional == rhs.myOptional
            && lhs.myTuple == rhs.myTuple
            && lhs.myStruct == rhs.myStruct
    }
}

struct AStruct: Equatable {
    let aString: String
    let anInt: Int
    let aTuple: (Int, String)

    public static func == (lhs: AStruct, rhs: AStruct) -> Bool {
        return lhs.aString == rhs.aString
            && lhs.anInt == rhs.anInt
            && lhs.aTuple == rhs.aTuple
    }
}

// after AutoEquatable

class MyClass: AutoEquatable {
    let myString: String
    let myInt: Int
    let myDouble: Double
    let myOptional: String?
    let myTuple: (String, Int)
    let myFunction: (String) -> Bool // functions are ignored when comparing objects
    let myStruct: AStruct
}

struct AStruct: AutoEquatable {
    let aString: String
    let anInt: Int
    let aTuple: (Int, String)
}
```

## Conforming to AutoEquatableEnum

Enums are not allowed to conform to `AutoEquatable` and doing so will result in a fatal error. This is because enums aren't as friendly as the other object types. Instead use `AutoEquatableEnum` and use `areAssociatedValuesEqual()` to compare all associated values at once.

### Enums without associated values

An enum that does not have any associated value on any case conform to `Equatable` by default. Thanks Swift!

In this case, simply conform to `AutoEquatableEnum`.

```swift
enum GenericEnum: AutoEquatableEnum {
    case one
    case two
}
```

### Enums with associated values

Unfortunately, if at least one case has at least one associated value then you must conform to `Equatable` manually.

For this to work, a little bit of boilerplate code required. Fortunately, there is a function on `AutoEquatableEnum` that can compare all the associated values at once.

```swift
// without using `default` (for compiler help so there is no way to accidentally leave out a case out of the switch statement)
enum EnumWithAssociatedValue: AutoEquatableEnum {
    case three(String)
    case four(String, Int, Double)

    public static func == (lhs: EnumWithAssociatedValue, rhs: EnumWithAssociatedValue) -> Bool {
        switch (lhs, rhs) {
        case (.three(let a), three(let b)):
            return areAssociatedValuesEqual(a, b)
        case (.four(let a), four(let b)):
            return areAssociatedValuesEqual(a, b)

        case (.three, _): return false
        case (.four, _): return false
        }
    }
}

// using `default` (small and faster, but might forget to add a case to the switch statement)
enum EnumWithAssociatedValue: AutoEquatableEnum {
    case three(String)
    case four(String, Int)

    public static func == (lhs: EnumWithAssociatedValue, rhs: EnumWithAssociatedValue) -> Bool {
        switch (lhs, rhs) {
        case (.three(let a), three(let b)):
            return areAssociatedValuesEqual(a, b)
        case (.four(let a), four(let b)):
            return areAssociatedValuesEqual(a, b)
        default: false
        }
    }
}
```

## Optionals

There is no need to have Optional conform to `AutoEquatable` and doing so will result in a fatal error. This is because optionals are already handled by `AutoEquatable` and allowing it will cause side effects.

## Tests

To see and run the tests for `AutoEquatable`. Download the playground and run it. The tests are written using [Deft](https://github.com/Rivukis/Deft).

## Requirements

* Xcode 8
* Swift 3

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
