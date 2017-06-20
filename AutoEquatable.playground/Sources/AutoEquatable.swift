
// MARK: _InternalAutoEquatable

public protocol _InternalAutoEquatable {
    func _isEqual(to other: Any) -> Bool
}

extension _InternalAutoEquatable where Self: Equatable {
    public func _isEqual(to other: Any) -> Bool {
        guard let other = other as? Self else {
            return false
        }

        return self == other
    }
}

// MARK: - AutoEquatabeEnum

public protocol AutoEquatableEnum: Equatable, _InternalAutoEquatable {
    static func areAssociatedValuesEqual(_ lhs: Any, _ rhs: Any) -> Bool
}

extension AutoEquatableEnum where Self: Equatable {
    public static func areAssociatedValuesEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        if let lhs = lhs as? _InternalAutoEquatable, let rhs = rhs as? _InternalAutoEquatable {
            return lhs._isEqual(to: rhs)
        }

        for (lhsProperty, rhsProperty) in zippedChildren(lhs: lhs, rhs: rhs) {
            if !isPropertyEqual(lhsProperty: lhsProperty, rhsProperty: rhsProperty) {
                return false
            }
        }

        return true
    }
}

// MARK: - AutoEquatabeEnum

public protocol AutoEquatable: Equatable, _InternalAutoEquatable {}

extension AutoEquatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        let lhsMirror = Mirror(reflecting: lhs)

        if lhsMirror.displayStyle == .enum {
            fatalError("Enums are NOT allowed to conform to AutoEquatable. <\(Self.self)> should conform to AutoEquatableEnum instead.")
        }

        let rhsMirror = Mirror(reflecting: rhs)

        for (lhsProperty, rhsProperty) in zippedChildren(lhsMirror: lhsMirror, rhsMirror: rhsMirror) {
            if !isPropertyEqual(lhsProperty: lhsProperty, rhsProperty: rhsProperty) {
                return false
            }
        }

        return true
    }
}

// MARK: OptionalType

public protocol OptionalType {}
extension Optional: OptionalType {}

extension AutoEquatable where Self: OptionalType {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        fatalError("Optional should NOT conform to AutoEquatable.")
    }
}

// MARK: - Private Helpers

private func isPropertyEqual(lhsProperty: Any, rhsProperty: Any) -> Bool {
    if let lhsProperty = lhsProperty as? _InternalAutoEquatable, let rhsProperty = rhsProperty as? _InternalAutoEquatable {
        return lhsProperty._isEqual(to: rhsProperty)
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
        for (lhsProperty, rhsProperty) in zippedChildren(lhsMirror: lhsMirror, rhsMirror: rhsMirror) {
            guard let lhsProperty = lhsProperty as? _InternalAutoEquatable, let rhsProperty = rhsProperty as? _InternalAutoEquatable else {
                fatalError("I only know how to deal with internal auto equatable")
            }

            if !lhsProperty._isEqual(to: rhsProperty) {
                return false
            }
        }

        return true
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

private func zippedChildren(lhs: Any, rhs: Any) -> Zip2Sequence<[Any], [Any]> {
    let lhsProperties = Mirror(reflecting: lhs).children.map{$0.1}
    let rhsProperties = Mirror(reflecting: rhs).children.map{$0.1}

    return zip(lhsProperties, rhsProperties)
}

private func zippedChildren(lhsMirror: Mirror, rhsMirror: Mirror) -> Zip2Sequence<[Any], [Any]> {
    let lhsProperties = lhsMirror.children.map{$0.1}
    let rhsProperties = rhsMirror.children.map{$0.1}

    return zip(lhsProperties, rhsProperties)
}

private func isAFunction(value: Any) -> Bool {
    return String(describing: value) == "(Function)"
}

// MARK: Common Types Conforming to AutoEquatable

extension String: AutoEquatable {}
extension Int: AutoEquatable {}
extension Double: AutoEquatable {}
extension Float: AutoEquatable {}
extension Array: AutoEquatable {}
extension Dictionary: AutoEquatable {}
extension Set: AutoEquatable {}
