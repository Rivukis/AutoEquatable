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
            // The case names should be the same
            guard enumCaseName(lhs) == enumCaseName(rhs) else {
                return false
            }
            // All associated values should be equal
            for (lhsChild, rhsChild) in zip(lhsMirror.children, rhsMirror.children) {
                guard areAssociatedValuesEqual(lhsChild, rhsChild) else {
                    return false
                }
            }
            return true
        }

        return areChildrenEqual(lhsMirror: lhsMirror, rhsMirror: rhsMirror)
    }
}

private func enumCaseName(_ value: Any) -> String {
    let name = String(describing: value)
    if let index = name.range(of: "(")?.lowerBound {
        return String(name.prefix(upTo: index))
    }
    return name
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
        return areChildrenEqual(lhsMirror: lhsMirror, rhsMirror: rhsMirror)
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

// MARK: Common Types Conforming to AutoEquatable

extension String: AutoEquatable {}
extension Int: AutoEquatable {}
extension Double: AutoEquatable {}
extension Float: AutoEquatable {}
extension Bool: AutoEquatable {}
extension Set: AutoEquatable {}
extension NSObject: AutoEquatable {}
