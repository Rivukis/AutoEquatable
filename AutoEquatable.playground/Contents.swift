
// MARK: - Test Helper Types

extension String: AutoEquatable {}
extension Int: AutoEquatable {}

// This should fatal error saying that optional should not conform to AutoEquatable
//extension Optional: AutoEquatable {}

class MyClass: AutoEquatable {
    let myString: String
    let myInt: Int

    init(myString: String, myInt: Int) {
        self.myString = myString
        self.myInt = myInt
    }
}

class MyClassWithAnotherClass: AutoEquatable {
    let myClass: MyClass

    init(myClass: MyClass) {
        self.myClass = myClass
    }
}

class MyClassWithTuple: AutoEquatable {
    let myTuple: (String, String)

    init(myTuple: (String, String)) {
        self.myTuple = myTuple
    }
}

class MyClassWithFunction: AutoEquatable {
    let myFunction: () -> Bool

    init(myFunction: @escaping () -> Bool) {
        self.myFunction = myFunction
    }
}

class MyClassWithOptional: AutoEquatable {
    let myOptional: String?

    init(myOptional: String?) {
        self.myOptional = myOptional
    }
}

// This should fatal error saying that enums should not conform to AutoEquatable but instead AutoEquatableEnum
//enum GenericEnum: AutoEquatable {

enum GenericEnum: AutoEquatableEnum {
    case one
    case two
}

class MyClassWithGenericEnum: AutoEquatable {
    let myEnum: GenericEnum

    init(myEnum: GenericEnum) {
        self.myEnum = myEnum
    }
}

enum EnumWithAssociatedValue: AutoEquatableEnum {
    case uno(String)
    case dos(String, Int)

    public static func == (lhs: EnumWithAssociatedValue, rhs: EnumWithAssociatedValue) -> Bool {
        switch (lhs, rhs) {
        case (.uno(let a), uno(let b)):
            return areAssociatedValuesEqual(a, b)
        case (.dos(let a), dos(let b)):
            return areAssociatedValuesEqual(a, b)

        case (.uno, _): return false
        case (.dos, _): return false
        }
    }
}

class MyClassWithEnumWithAssociatedValue: AutoEquatable {
    let myEnum: EnumWithAssociatedValue

    init(myEnum: EnumWithAssociatedValue) {
        self.myEnum = myEnum
    }
}

class MyClassWithCustomEquatable: AutoEquatable {
    let usedToDetermineEquatable: String
    let doesNotMatterForEquatable: String

    init(usedToDetermineEquatable: String, doesNotMatterForEquatable: String) {
        self.usedToDetermineEquatable = usedToDetermineEquatable
        self.doesNotMatterForEquatable = doesNotMatterForEquatable
    }

    public static func == (lhs: MyClassWithCustomEquatable, rhs: MyClassWithCustomEquatable) -> Bool {
        return lhs.usedToDetermineEquatable == rhs.usedToDetermineEquatable
    }
}

// MARK: Tests

describe("AutoEquatable") {
    describe("properties one level deep") {
        context("when the properties are equal") {
            it("should return true") {
                let myClass1 = MyClass(myString: "yes", myInt: 5)
                let myClass2 = MyClass(myString: "yes", myInt: 5)

                expect(myClass1 == myClass2).to(beTrue())
            }
        }

        context("when the properties are NOT equal") {
            it("should return true") {
                let myClass1 = MyClass(myString: "yes", myInt: 5)
                let myClass2 = MyClass(myString: "no", myInt: 10)

                expect(myClass1 == myClass2).to(beFalse())
            }
        }
    }

    describe("properties more than one level deep") {
        context("when the properties are equal") {
            it("should return true") {
                let myClass1 = MyClassWithAnotherClass(myClass: MyClass(myString: "yes", myInt: 5))
                let myClass2 = MyClassWithAnotherClass(myClass: MyClass(myString: "yes", myInt: 5))

                expect(myClass1 == myClass2).to(beTrue())
            }
        }

        context("when the properties are NOT equal") {
            it("should return true") {
                let myClass1 = MyClassWithAnotherClass(myClass: MyClass(myString: "yes", myInt: 5))
                let myClass2 = MyClassWithAnotherClass(myClass: MyClass(myString: "no", myInt: 10))

                expect(myClass1 == myClass2).to(beFalse())
            }
        }
    }

    describe("properties that are tuples") {
        context("when the properties are equal") {
            it("should return true") {
                let myClass1 = MyClassWithTuple(myTuple: ("one", "two"))
                let myClass2 = MyClassWithTuple(myTuple: ("one", "two"))

                expect(myClass1 == myClass2).to(beTrue())
            }
        }

        context("when the properties are NOT equal") {
            it("should return true") {
                let myClass1 = MyClassWithTuple(myTuple: ("one", "two"))
                let myClass2 = MyClassWithTuple(myTuple: ("three", "four"))

                expect(myClass1 == myClass2).to(beFalse())
            }
        }
    }

    describe("properties that are functions") {
        it("should always return true") {
            let myClass1 = MyClassWithFunction(myFunction: { true })
            let myClass2 = MyClassWithFunction(myFunction: { false })

            expect(myClass1 == myClass2).to(beTrue())
        }
        _ = "" // this line is here so code collapsing works properly
    }

    describe("properties that are enums") {
        describe("generic enums") {
            context("when the enums are the same") {
                it("should return true") {
                    let myClass1 = MyClassWithGenericEnum(myEnum: .one)
                    let myClass2 = MyClassWithGenericEnum(myEnum: .one)

                    expect(myClass1 == myClass2).to(beTrue())
                }
            }

            context("when the enums are NOT the same") {
                it("should return true") {
                    let myClass1 = MyClassWithGenericEnum(myEnum: .one)
                    let myClass2 = MyClassWithGenericEnum(myEnum: .two)

                    expect(myClass1 == myClass2).to(beFalse())
                }
            }
        }

        describe("enums with associated values") {
            context("when the enums are the same with same associated values (multiple)") {
                it("should return true when using convienence function") {
                    let myClass1 = MyClassWithEnumWithAssociatedValue(myEnum: .dos("1", 5))
                    let myClass2 = MyClassWithEnumWithAssociatedValue(myEnum: .dos("1", 5))

                    expect(myClass1 == myClass2).to(beTrue())
                }
            }

            context("when the enums are the same with same associated value (singular)") {
                it("should return true when using convienence function") {
                    let myClass1 = MyClassWithEnumWithAssociatedValue(myEnum: .uno("1"))
                    let myClass2 = MyClassWithEnumWithAssociatedValue(myEnum: .uno("1"))

                    expect(myClass1 == myClass2).to(beTrue())
                }
            }

            context("when the enums are the same with different associated values (multiple)") {
                it("should return true when using convienence function") {
                    let myClass1 = MyClassWithEnumWithAssociatedValue(myEnum: .dos("2", 6))
                    let myClass2 = MyClassWithEnumWithAssociatedValue(myEnum: .dos("1", 5))

                    expect(myClass1 == myClass2).to(beFalse())
                }
            }

            context("when the enums are the same with a different associated value (singular)") {
                it("should return false when using convienence function") {
                    let myClass1 = MyClassWithEnumWithAssociatedValue(myEnum: .uno("1"))
                    let myClass2 = MyClassWithEnumWithAssociatedValue(myEnum: .uno("2"))

                    expect(myClass1 == myClass2).to(beFalse())
                }
            }

            context("when the enums are NOT the same") {
                it("should return true") {
                    let myClass1 = MyClassWithEnumWithAssociatedValue(myEnum: .uno(""))
                    let myClass2 = MyClassWithEnumWithAssociatedValue(myEnum: .dos("", 0))

                    expect(myClass1 == myClass2).to(beFalse())
                }
            }
        }
    }

    describe("enums (excluding Optional)") {
        describe("generic enums") {
            context("when the enums are the same") {
                it("should return true") {
                    let myEnum1 = GenericEnum.one
                    let myEnum2 = GenericEnum.one

                    expect(myEnum1 == myEnum2).to(beTrue())
                }
            }

            context("when the enums are NOT the same") {
                it("should return true") {
                    let myEnum1 = GenericEnum.one
                    let myEnum2 = GenericEnum.two

                    expect(myEnum1 == myEnum2).to(beFalse())
                }
            }
        }

        describe("enums with associated values") {
            context("when the enums are the same with same associated values (multiple)") {
                it("should return true when using convienence function") {
                    let myEnum1 = EnumWithAssociatedValue.dos("1", 5)
                    let myEnum2 = EnumWithAssociatedValue.dos("1", 5)

                    expect(myEnum1 == myEnum2).to(beTrue())
                }
            }

            context("when the enums are the same with same associated value (singular)") {
                it("should return true when using convienence function") {
                    let myEnum1 = EnumWithAssociatedValue.uno("1")
                    let myEnum2 = EnumWithAssociatedValue.uno("1")

                    expect(myEnum1 == myEnum2).to(beTrue())
                }
            }

            context("when the enums are the same with different associated values (multiple)") {
                it("should return true when using convienence function") {
                    let myClass1 = EnumWithAssociatedValue.dos("2", 6)
                    let myClass2 = EnumWithAssociatedValue.dos("1", 5)

                    expect(myClass1 == myClass2).to(beFalse())
                }
            }

            context("when the enums are the same with a different associated value (singular)") {
                it("should return false when using convienence function") {
                    let myEnum1 = EnumWithAssociatedValue.uno("1")
                    let myEnum2 = EnumWithAssociatedValue.uno("2")

                    expect(myEnum1 == myEnum2).to(beFalse())
                }
            }

            context("when the enums are NOT the same") {
                it("should return true") {
                    let myEnum1 = EnumWithAssociatedValue.uno("")
                    let myEnum2 = EnumWithAssociatedValue.dos("", 0)

                    expect(myEnum1 == myEnum2).to(beFalse())
                }
            }
        }
    }

    describe("properties that are optional") {
        it("should return true for two nils") {
            let myClass1: MyClassWithOptional = MyClassWithOptional(myOptional: nil)
            let myClass2: MyClassWithOptional = MyClassWithOptional(myOptional: nil)

            expect(myClass1 == myClass2).to(beTrue())
        }

        it("should return false for nil and non-nil comparision") {
            let myClass1: MyClassWithOptional = MyClassWithOptional(myOptional: nil)
            let myClass2: MyClassWithOptional = MyClassWithOptional(myOptional: "")

            expect(myClass1 == myClass2).to(beFalse())
            expect(myClass2 == myClass1).to(beFalse())
        }

        it("should return true for two non-nils of equal value") {
            let myClass1: MyClassWithOptional = MyClassWithOptional(myOptional: "blah")
            let myClass2: MyClassWithOptional = MyClassWithOptional(myOptional: "blah")

            expect(myClass1 == myClass2).to(beTrue())
        }

        it("should return false for two non-nils of different value") {
            let myClass1: MyClassWithOptional = MyClassWithOptional(myOptional: "blah")
            let myClass2: MyClassWithOptional = MyClassWithOptional(myOptional: "not blah")

            expect(myClass1 == myClass2).to(beFalse())
        }
    }

    describe("optional") {
        it("should return true for two nils of the same type") {
            let myClass1: MyClass? = nil
            let myClass2: MyClass? = nil

            expect(myClass1 == myClass2).to(beTrue())
        }

        it("should return false for nil and non-nil comparison") {
            let myClass1: MyClass? = nil
            let myClass2: MyClass? = MyClass(myString: "", myInt: 0)

            expect(myClass1 == myClass2).to(beFalse())
            expect(myClass2 == myClass1).to(beFalse())
        }

        it("should return true for two non-nil with the same property values") {
            let myClass1: MyClass? = MyClass(myString: "one", myInt: 10)
            let myClass2: MyClass? = MyClass(myString: "one", myInt: 10)

            expect(myClass1 == myClass2).to(beTrue())
        }

        it("should return false for two non-nil with different property values") {
            let myClass1: MyClass? = MyClass(myString: "one", myInt: 10)
            let myClass2: MyClass? = MyClass(myString: "two", myInt: 5)

            expect(myClass1 == myClass2).to(beFalse())
        }
    }

    describe("overriding `==()` operation") {
        it("should use custom function for Equatable") {
            let myClass1 = MyClassWithCustomEquatable(usedToDetermineEquatable: "same", doesNotMatterForEquatable: "doesn't matter")
            let myClass2 = MyClassWithCustomEquatable(usedToDetermineEquatable: "same", doesNotMatterForEquatable: "still doesn't matter")
            let myClass3 = MyClassWithCustomEquatable(usedToDetermineEquatable: "different", doesNotMatterForEquatable: "still doesn't matter")

            expect(myClass1 == myClass2).to(beTrue())
            expect(myClass2 == myClass3).to(beFalse())
        }
        _ = "" // this line is here so code collapsing works properly
    }
}
