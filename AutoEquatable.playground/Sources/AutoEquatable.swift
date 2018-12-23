import Foundation

// MARK: _InternalAutoEquatable

public protocol _DO_NOT_DIRECTLY_CONFORM_TO_InternalAutoEquatable {
    func _DO_NOT_OVERRIDE_isEqual(to other: Any) -> Bool
}

extension _DO_NOT_DIRECTLY_CONFORM_TO_InternalAutoEquatable where Self: Equatable {
    public func _DO_NOT_OVERRIDE_isEqual(to other: Any) -> Bool {
        guard let other = other as? Self else {
            return false
        }

        return self == other
    }
}

// MARK: - AutoEquatableGeneric

public protocol AutoEquatableGeneric: _DO_NOT_DIRECTLY_CONFORM_TO_InternalAutoEquatable {}

// MARK: - AutoEquatabe

public protocol AutoEquatable: Equatable, AutoEquatableGeneric {}

extension AutoEquatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        let lhsMirror = Mirror(reflecting: lhs)
        let rhsMirror = Mirror(reflecting: rhs)

        if lhsMirror.displayStyle == .enum {
            return areEnumCasesEqual(lhs: lhs, rhs: rhs, lhsMirror: lhsMirror, rhsMirror: rhsMirror)
        }

        return areChildrenEqual(lhsMirror: lhsMirror, rhsMirror: rhsMirror)
    }

    func rawData() -> UInt8 {
        var me: Self = self
        guard let rawValue = Data(bytes: &me, count: MemoryLayout<Self>.size).last else {
            fatalError("Something went wrong when getting the raw bytes.")
        }

        return rawValue
    }
}

private func areEnumCasesEqual<T: AutoEquatable>(lhs: T, rhs: T, lhsMirror: Mirror, rhsMirror: Mirror) -> Bool {
    // Make sure that both enums have or don't have associated values
    guard lhsMirror.children.isEmpty == rhsMirror.children.isEmpty else {
        return false
    }

    /*
     If an enum has NO children than it has no associated values
     therefore the data representations will represent the enum case
     */
    if lhsMirror.children.isEmpty {
        return lhs.rawData() == rhs.rawData()
    }

    // If an enum HAS children than the case name is the used as the label to associated values
    guard let lhsCaseName = lhsMirror.children.first?.label, let rhsCaseName = rhsMirror.children.first?.label else {
        fatalError("Swift is not laying out an enum in the expected way in Mirror")
    }

    return lhsCaseName == rhsCaseName && areAssociatedValuesEqual(Array(lhsMirror.children), Array(rhsMirror.children))
}

private func areAssociatedValuesEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    if let lhs = lhs as? _DO_NOT_DIRECTLY_CONFORM_TO_InternalAutoEquatable, let rhs = rhs as? _DO_NOT_DIRECTLY_CONFORM_TO_InternalAutoEquatable {
        return lhs._DO_NOT_OVERRIDE_isEqual(to: rhs)
    }
    let lhsMirror = Mirror(reflecting: lhs)
    let rhsMirror = Mirror(reflecting: rhs)

    return areChildrenEqual(lhsMirror: lhsMirror, rhsMirror: rhsMirror)
}

// MARK: OptionalType Protection

public protocol OptionalType {}
extension Optional: OptionalType {}

extension AutoEquatable where Self: OptionalType {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        fatalError("Optional should NOT conform to AutoEquatable.")
    }
}

// MARK: Collection Protection

extension AutoEquatable where Self: Collection {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        fatalError("Collections (aka \(typeNameWithOutGenerics(Self.self))) should NOT conform to AutoEquatable.")
    }
}

// MARK: - Private Helpers

private func areChildrenEqual(lhsMirror: Mirror, rhsMirror: Mirror) -> Bool {
    let lhsChildren = lhsMirror.children
    let rhsChildren = rhsMirror.children

    guard lhsChildren.count == rhsChildren.count else {
        return false
    }

    let lhsProperties = lhsChildren.map { $0.1 }
    let rhsProperties = rhsChildren.map { $0.1 }

    for (lhsProperty, rhsProperty) in zip(lhsProperties, rhsProperties) {
        if !isPropertyEqual(lhsProperty: lhsProperty, rhsProperty: rhsProperty) {
            return false
        }
    }

    return true
}

private func isPropertyEqual(lhsProperty: Any, rhsProperty: Any) -> Bool {
    if let lhsProperty = lhsProperty as? _DO_NOT_DIRECTLY_CONFORM_TO_InternalAutoEquatable, let rhsProperty = rhsProperty as? _DO_NOT_DIRECTLY_CONFORM_TO_InternalAutoEquatable {
        return lhsProperty._DO_NOT_OVERRIDE_isEqual(to: rhsProperty)
    }

    return isNonInternalAutoEquatableEqual(lhs: lhsProperty, rhs: rhsProperty)
}

private func isNonInternalAutoEquatableEqual(lhs: Any, rhs: Any) -> Bool {

    // Function Check

    if isAFunction(value: lhs) && isAFunction(value: rhs) {
        return true
    }

    let lhsMirror = Mirror(reflecting: lhs)
    let rhsMirror = Mirror(reflecting: rhs)

    // Tuple Check

    if lhsMirror.displayStyle == .tuple && rhsMirror.displayStyle == .tuple {
        return areChildrenEqual(lhsMirror: lhsMirror, rhsMirror: rhsMirror)
    }

    // Collection Check

    if lhsMirror.displayStyle == .collection && rhsMirror.displayStyle == .collection {
        return areChildrenEqual(lhsMirror: lhsMirror, rhsMirror: rhsMirror)
    }

    // Dictionary Check

    if lhsMirror.displayStyle == .dictionary && rhsMirror.displayStyle == .dictionary {
        return manualDictionaryEquality(lhsMirror: lhsMirror, rhsMirror: rhsMirror)
    }

    // Optional Check

    if lhsMirror.displayStyle == .optional && rhsMirror.displayStyle == .optional {
        let lhsValue = lhsMirror.children.first?.value
        let rhsValue = rhsMirror.children.first?.value

        if let lhsValue = lhsValue, let rhsValue = rhsValue {
            return isPropertyEqual(lhsProperty: lhsValue, rhsProperty: rhsValue)
        }

        return lhsValue == nil && rhsValue == nil
    }

    fatalError("type \(type(of: lhs)) must conform to AutoEquatable")
}

private func isAFunction(value: Any) -> Bool {
    return String(describing: value) == "(Function)"
}

private func typeNameWithOutGenerics<T>(_: T.Type) -> String {
    let type = String(describing: T.self)

    if let typeWithoutGeneric = type.split(separator: "<").first {
        return String(typeWithoutGeneric)
    }

    return type
}

private func manualDictionaryEquality(lhsMirror: Mirror, rhsMirror: Mirror) -> Bool {
    let lhsDictionary = convertMirrorOfDictionaryToDictionary(mirror: lhsMirror)
    let rhsDictionary = convertMirrorOfDictionaryToDictionary(mirror: rhsMirror)

    let lhsKeySet = Set<AnyHashable>(lhsDictionary.keys)
    let rhsKeySet = Set<AnyHashable>(rhsDictionary.keys)

    guard lhsKeySet == rhsKeySet else {
        return false
    }

    for lhsKey in lhsDictionary.keys {
        guard let lhsValue = lhsDictionary[lhsKey], let rhsValue = rhsDictionary[lhsKey] else {
            // key doesn't not exist in both dictionaries
            return false
        }

        guard isPropertyEqual(lhsProperty: lhsValue, rhsProperty: rhsValue) else {
            // values for the same key are not equal
            return false
        }
    }

    return true
}

private func convertMirrorOfDictionaryToDictionary(mirror: Mirror) -> [AnyHashable: Any] {
    var dictionary: [AnyHashable: Any] = [:]

    for child in mirror.children {
        if let pair = child.value as? (key: AnyHashable, value: Any) {
            dictionary[pair.key] = pair.value
        } else {
            fatalError("Unable to reconstruct dictionary from a Mirror with a `displatyStyle` of `.dictionary`")
        }
    }

    return dictionary
}

// MARK: Common Types Conforming to AutoEquatable

extension String: AutoEquatable {}
extension Int: AutoEquatable {}
extension Double: AutoEquatable {}
extension Float: AutoEquatable {}
extension Bool: AutoEquatable {}
extension Set: AutoEquatable {}
extension NSObject: AutoEquatable {}
