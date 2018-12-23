import Foundation

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

class MyClassWithArray<T>: AutoEquatable {
    let myArray: [T]

    init(myArray: [T]) {
        self.myArray = myArray
    }
}

class MyClassWithDictionary<T>: AutoEquatable {
    let myDictionary: [String: T]

    init(myDictionary: [String: T]) {
        self.myDictionary = myDictionary
    }
}

class MyClassWithFunction: AutoEquatable {
    let myFunction: () -> Bool

    init(myFunction: @escaping () -> Bool) {
        self.myFunction = myFunction
    }
}

class MyClassWithNSObject: AutoEquatable {
    class MyNSObject: NSObject {
        let value: Int

        init(value: Int) {
            self.value = value
        }
    }

    let myNSObject: MyNSObject

    init(myNSObject: MyNSObject) {
        self.myNSObject = myNSObject
    }
}

class MyClassWithOptional: AutoEquatable {
    let myOptional: String?

    init(myOptional: String?) {
        self.myOptional = myOptional
    }
}

enum GenericEnum: AutoEquatable {
    case one
    case two
}

class MyClassWithGenericEnum: AutoEquatable {
    let myEnum: GenericEnum

    init(myEnum: GenericEnum) {
        self.myEnum = myEnum
    }
}

enum EnumWithAssociatedValue: AutoEquatable {
    case uno(String)
    case dos(String, Int)
}

enum EnumWithEnumAssociatedValue: AutoEquatable {
    case one
    case two(EnumWithAssociatedValue)
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
            it("should return false") {
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
            it("should return false") {
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
            it("should return false") {
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
    }

    describe("properties that are NSObjects") {
        context("when the properties are the same instance") {
            it("should return true (NSObject's Equatable defaults to pointer comparison)") {
                let sameObject = MyClassWithNSObject.MyNSObject(value: 1)
                let myClass1 = MyClassWithNSObject(myNSObject: sameObject)
                let myClass2 = MyClassWithNSObject(myNSObject: sameObject)

                expect(myClass1 == myClass2).to(beTrue())
            }
        }

        context("when the properties are NOT the same instance") {
            it("should return false (NSObject's Equatable defaults to pointer comparison)") {
                let myClass1 = MyClassWithNSObject(myNSObject: MyClassWithNSObject.MyNSObject(value: 1))
                let myClass2 = MyClassWithNSObject(myNSObject: MyClassWithNSObject.MyNSObject(value: 1))

                expect(myClass1 == myClass2).to(beFalse())
            }
        }
    }

    describe("properties that are enums") {
        describe("generic enums") {
            context("when the enums are the same") {
                it("should return true for the same enum") {
                    let myClass1 = MyClassWithGenericEnum(myEnum: .one)
                    let myClass2 = MyClassWithGenericEnum(myEnum: .one)

                    expect(myClass1 == myClass2).to(beTrue())
                }
            }

            context("when the enums are NOT the same") {
                it("should return false") {
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
                it("should return false when using convienence function") {
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
                it("should return false") {
                    let myClass1 = MyClassWithEnumWithAssociatedValue(myEnum: .uno(""))
                    let myClass2 = MyClassWithEnumWithAssociatedValue(myEnum: .dos("", 0))

                    expect(myClass1 == myClass2).to(beFalse())
                }
            }
        }
    }

    describe("properties that are collections") {
        context("when the arrays are equal") {
            it("should return true") {
                let myClassWithArray1 = MyClassWithArray(myArray: [1, 2, 3])
                let myClassWithArray2 = MyClassWithArray(myArray: [1, 2, 3])

                expect(myClassWithArray1 == myClassWithArray2).to(beTrue())
            }
        }

        context("when the arrays are NOT equal") {
            it("should return false") {
                let myClassWithArray1 = MyClassWithArray(myArray: [-1, -2, -3])
                let myClassWithArray2 = MyClassWithArray(myArray: [1, 2, 3])

                expect(myClassWithArray1 == myClassWithArray2).to(beFalse())
            }
        }

        context("when the arrays contain tuples of AutoEquatable; arrays are equal") {
            it("should return true") {
                let myClassWithArray3 = MyClassWithArray(myArray: [(-1, -1), (-2, -2)])
                let myClassWithArray4 = MyClassWithArray(myArray: [(-1, -1), (-2, -2)])

                expect(myClassWithArray3 == myClassWithArray4).to(beTrue())
            }
        }

        context("when the arrays contain tuples of AutoEquatable; arrays are NOT equal") {
            it("should return false") {
                let myClassWithArray1 = MyClassWithArray(myArray: [(-1, -1), (-2, -2)])
                let myClassWithArray2 = MyClassWithArray(myArray: [(-1, -1), (2, 2)])

                expect(myClassWithArray1 == myClassWithArray2).to(beFalse())
            }
        }

        context("when the arrays have different count") {
            it("should return false") {
                let myClassWithArray1 = MyClassWithArray(myArray: [(-1, -1), (-2, -2)])
                let myClassWithArray2 = MyClassWithArray(myArray: [(-1, -1)])

                expect(myClassWithArray1 == myClassWithArray2).to(beFalse())
            }
        }
    }

    describe("properties that are dictionaries") {
        context("when the dictionaries are equal") {
            it("should return true") {
                let myClassWithDictionary1 = MyClassWithDictionary(myDictionary: ["one": "1", "two": "2"])
                let myClassWithDictionary2 = MyClassWithDictionary(myDictionary: ["one": "1", "two": "2"])

                expect(myClassWithDictionary1 == myClassWithDictionary2).to(beTrue())
            }
        }

        context("when the dictionaries are equal but created with key-value pairs in a different order") {
            it("should return true") {
                let myClassWithDictionary1 = MyClassWithDictionary(myDictionary: ["one": "1", "two": "2"])
                let myClassWithDictionary2 = MyClassWithDictionary(myDictionary: ["two": "2", "one": "1"])

                expect(myClassWithDictionary1 == myClassWithDictionary2).to(beTrue())
            }
        }

        context("when the dictionaries are NOT equal") {
            it("should return false") {
                let myClassWithDictionary1 = MyClassWithDictionary(myDictionary: ["one": "1", "two": "2"])
                let myClassWithDictionary2 = MyClassWithDictionary(myDictionary: ["one": "1", "three": "3"])

                expect(myClassWithDictionary1 == myClassWithDictionary2).to(beFalse())
            }
        }

        context("when the dictionaries have different counts") {
            it("should return false") {
                let myClassWithDictionary1 = MyClassWithDictionary(myDictionary: ["one": "1", "two": "2"])
                let myClassWithDictionary2 = MyClassWithDictionary(myDictionary: ["one": "1"])

                expect(myClassWithDictionary1 == myClassWithDictionary2).to(beFalse())
            }
        }

        context("when the arrays contain tuples of AutoEquatable; dictionaries are equal") {
            it("should return true") {
                let myClassWithDictionary1 = MyClassWithDictionary(myDictionary: ["one": (-1, -1), "two": (-2, -2)])
                let myClassWithDictionary2 = MyClassWithDictionary(myDictionary: ["one": (-1, -1), "two": (-2, -2)])

                expect(myClassWithDictionary1 == myClassWithDictionary2).to(beTrue())
            }
        }

        context("when the arrays contain tuples of AutoEquatable; dictionaries are NOT equal") {
            it("should return false") {
                let myClassWithDictionary3 = MyClassWithDictionary(myDictionary: ["one": (-1, -1), "two": (-2, -2)])
                let myClassWithDictionary4 = MyClassWithDictionary(myDictionary: ["one": (1, 1), "two": (2, 2)])

                expect(myClassWithDictionary3 == myClassWithDictionary4).to(beFalse())
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
                it("should return false") {
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
                it("should return false when using convienence function") {
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
                it("should return false") {
                    let myEnum1 = EnumWithAssociatedValue.uno("")
                    let myEnum2 = EnumWithAssociatedValue.dos("", 0)

                    expect(myEnum1 == myEnum2).to(beFalse())
                }
            }
        }
        
        describe("enums with enum associated values") {
            context("when the case w/o associated values are the same") {
                it("should return true when using convienence function") {
                    let myEnum1 = EnumWithEnumAssociatedValue.one
                    let myEnum2 = EnumWithEnumAssociatedValue.one
                    
                    expect(myEnum1 == myEnum2).to(beTrue())
                }
            }
            
            context("when the associated values are the same") {
                it("should return true when using convienence function") {
                    let myEnum1 = EnumWithEnumAssociatedValue.two(.uno("String"))
                    let myEnum2 = EnumWithEnumAssociatedValue.two(.uno("String"))
                    
                    expect(myEnum1 == myEnum2).to(beTrue())
                }
            }

            context("when the associated values are not the same") {
                it("should return false when using convienence function") {
                    let myEnum1 = EnumWithEnumAssociatedValue.two(.uno("String1"))
                    let myEnum2 = EnumWithEnumAssociatedValue.two(.uno("String2"))
                    
                    expect(myEnum1 == myEnum2).to(beFalse())
                }
            }
        }
    }

    describe("properties that are optional") {
        context("when both are nil") {
            it("should return true") {
                let myClass1: MyClassWithOptional = MyClassWithOptional(myOptional: nil)
                let myClass2: MyClassWithOptional = MyClassWithOptional(myOptional: nil)

                expect(myClass1 == myClass2).to(beTrue())
            }
        }

        context("when one is nil and one is non-nil") {
            it("should return false") {
                let myClass1: MyClassWithOptional = MyClassWithOptional(myOptional: nil)
                let myClass2: MyClassWithOptional = MyClassWithOptional(myOptional: "")

                expect(myClass1 == myClass2).to(beFalse())
                expect(myClass2 == myClass1).to(beFalse())
            }
        }

        context("when both are non-nil and equal value") {
            it("should return true for two non-nils of equal value") {
                let myClass1: MyClassWithOptional = MyClassWithOptional(myOptional: "blah")
                let myClass2: MyClassWithOptional = MyClassWithOptional(myOptional: "blah")

                expect(myClass1 == myClass2).to(beTrue())
            }
        }

        context("when both are non-nil and NOT equal value") {
            it("should return false for two non-nils of different value") {
                let myClass1: MyClassWithOptional = MyClassWithOptional(myOptional: "blah")
                let myClass2: MyClassWithOptional = MyClassWithOptional(myOptional: "not blah")

                expect(myClass1 == myClass2).to(beFalse())
            }
        }
    }

    describe("optional") {
        context("when both are nil") {
            it("should return true") {
                let myClass1: MyClass? = nil
                let myClass2: MyClass? = nil

                expect(myClass1 == myClass2).to(beTrue())
            }
        }

        context("when one is nil and one is non-nil") {
            it("should return false") {
                let myClass1: MyClass? = nil
                let myClass2: MyClass? = MyClass(myString: "", myInt: 0)

                expect(myClass1 == myClass2).to(beFalse())
                expect(myClass2 == myClass1).to(beFalse())
            }
        }

        context("when both are non-nil and have same properties") {
            it("should return true") {
                let myClass1: MyClass? = MyClass(myString: "one", myInt: 10)
                let myClass2: MyClass? = MyClass(myString: "one", myInt: 10)

                expect(myClass1 == myClass2).to(beTrue())
            }
        }

        context("when both are non-nil and have different properties") {
            it("should return false") {
                let myClass1: MyClass? = MyClass(myString: "one", myInt: 10)
                let myClass2: MyClass? = MyClass(myString: "two", myInt: 5)

                expect(myClass1 == myClass2).to(beFalse())
            }
        }
    }

    describe("overriding `==()` operation") {
        it("should always use custom function for Equatable") {
            let myClass1 = MyClassWithCustomEquatable(usedToDetermineEquatable: "same", doesNotMatterForEquatable: "doesn't matter")
            let myClass2 = MyClassWithCustomEquatable(usedToDetermineEquatable: "same", doesNotMatterForEquatable: "still doesn't matter")
            let myClass3 = MyClassWithCustomEquatable(usedToDetermineEquatable: "different", doesNotMatterForEquatable: "still doesn't matter")

            expect(myClass1 == myClass2).to(beTrue())
            expect(myClass2 == myClass3).to(beFalse())
        }
    }

    describe("AutoEquatableGeneric") {
        let autoEquatableGenericFunction: (AutoEquatableGeneric) -> Void = { _ in }

        it("should be able to pass in any AutoEquatable") {
            autoEquatableGenericFunction(MyClass(myString: "", myInt: 0))
        }
    }
}
