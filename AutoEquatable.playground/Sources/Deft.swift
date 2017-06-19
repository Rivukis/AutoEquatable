
// Matcher Framework

public class Matcher<T> {
    func execute(actual: T) -> Bool {
        fatalError("This is a Base class. Must subclass to use")
    }
}

// - Default Matchers

class EqualMatcher<T: Equatable>: Matcher<T> {
    let expected: T

    init(expected: T) {
        self.expected = expected
    }

    override func execute(actual: T) -> Bool {
        return actual == expected
    }
}

public protocol BoolType {}
extension Bool: BoolType {}

class BeTrueMatcher<T: BoolType>: Matcher<T> {
    override func execute(actual: T) -> Bool {
        return (actual as! Bool)
    }
}

class BeFalseMatcher<T: BoolType>: Matcher<T> {
    override func execute(actual: T) -> Bool {
        return !(actual as! Bool)
    }
}

protocol BlockType {}
struct Block: BlockType {
    let held: () -> Void

    init(_ held: @escaping () -> Void) {
        self.held = held
    }
}
class LogTrackerMatcher<T: BlockType>: Matcher<T> {
    override func execute(actual: T) -> Bool {
        (actual as! Block).held()
        return true
    }
}

// - Global Matcher Functions

public func equal<T: Equatable>(_ expected: T) -> Matcher<T> {
    let mirror = Mirror(reflecting: expected)
    if mirror.displayStyle == .optional {
        fatalError("use optEqual to compare optionals")
    }
    return EqualMatcher(expected: expected)
}

public func beTrue<T: BoolType>() -> Matcher<T> {
    return BeTrueMatcher()
}

public func beFalse<T: BoolType>() -> Matcher<T> {
    return BeFalseMatcher()
}

func log<T: BlockType>() -> Matcher<T> {
    return LogTrackerMatcher()
}


// BDD Framework

private struct Constant {
    static let levelSpace = "   "
    static let emptyTitle = ""

    struct OutPutPrefix {
        static let topLevel = "Test: "
        static let describe = "Describe: "
        static let context = "Context: "
        static let group = "Group: "
        static let it = "It: "

        static let focused = "F-"
        static let pending = "X-"
    }

    struct SingleCharacter {
        static let blank = " "
        static let success = "."
        static let failure = "F"
        static let pending = ">"
    }
}

private struct I18n {
    enum Key {
        case tooManySubjectActions
        case newScopesWhileExecuting
        case stepOutsideOfScope(StepType)
        case itOutsideOfScope
        case expectOutsideOfIt
        case notAllowedInIt(String)
        case lineOutput(text: String, level: Int, firstCharacter: String)
        case endLine(totalCount: Int, succeeded: Int, pending: Int)
        case failureOutputLine(failureLines: [Int])
    }

    static func t(_ key: Key) -> String {
        switch key {
        case .tooManySubjectActions:
            return "Only one \"subjectAction()\" per `it`."
        case .newScopesWhileExecuting:
            return "Tried to add a scope during a test. This is probably caused be a test block (describe, it, beforeEach, etc.) is defined inside an `it` block."
        case .stepOutsideOfScope(let type):
            return "`\(type)`s must be inside a `describe` or `context` scope."
        case .itOutsideOfScope:
            return "`it`s must be inside a `describe` or `context` scope."
        case .expectOutsideOfIt:
            return "`expects`s must be inside an `it` scope."
        case .notAllowedInIt(let string):
            return "`\(string)` not allowed in `it` scope."
        case .lineOutput(let text, let level, let firstCharacter):
            let space = String(repeating: Constant.levelSpace, count: level)
            return firstCharacter + space + text + "\n"
        case .endLine(let totalCount, let succeeded, let pending):
            let testText = totalCount == 1 ? "test" : "tests"
            return "\n Executed \(totalCount) \(testText)\n  |- \(succeeded) succeeded\n  |- \(totalCount - succeeded - pending) failed\n  |- \(pending) pending\n\n"
        case .failureOutputLine(let failureLines):
            let linesString = failureLines.count == 1 ? "line" : "lines"
            return "\n Failed on " + linesString + ": [" + failureLines.map{"\($0)"}.joined(separator: ", ") + "]\n"
        }
    }
}


private protocol TrackedScope {
    func add(_ scope: Scope)
    func add(_ step: Step)
    func add(_ it: It)
}

private enum StepType {
    case beforeEach
    case subjectAction
    case afterEach
}

private enum ScopeType {
    case topLevel
    case describe
    case context
    case group

    var outputPrefix: String {
        switch self {
        case .topLevel: return Constant.OutPutPrefix.topLevel
        case .describe: return Constant.OutPutPrefix.describe
        case .context: return Constant.OutPutPrefix.context
        case .group: return Constant.OutPutPrefix.group
        }
    }
}

private enum Mark {
    case none
    case focused
    case pending
}


private class TestResult {
    let description: String
    let total: Int
    let succeeded: Int
    let pending: Int
    let failureLines: [Int]

    init(description: String = "", total: Int = 0, succeeded: Int = 0, pending: Int = 0, failureLines: [Int] = []) {
        self.description = description
        self.total = total
        self.succeeded = succeeded
        self.pending = pending
        self.failureLines = failureLines
    }

    static func + (lhs: TestResult, rhs: TestResult) -> TestResult {
        return TestResult(description: lhs.description + rhs.description,
                          total: lhs.total + rhs.total,
                          succeeded: lhs.succeeded + rhs.succeeded,
                          pending: lhs.pending + rhs.pending,
                          failureLines: lhs.failureLines + rhs.failureLines)
    }
}

private class Expect {
    private let captured: () -> Bool
    private let line: Int
    private let negativeTest: Bool

    init<T>(actual: T, matcher: Matcher<T>, line: Int, negativeTest: Bool) {
        self.captured = { matcher.execute(actual: actual) }
        self.line = line
        self.negativeTest = negativeTest
    }

    private func execute() -> Bool {
        let result = captured()
        return result && !negativeTest || !result && negativeTest
    }

    static func execute(_ expects: [Expect]) -> (Bool, [Int]) {
        var failedLines = [Int]()
        var allSucceeded = true

        for expect in expects {
            let success = expect.execute()

            if !success {
                failedLines.append(expect.line)
                allSucceeded = false
            }
        }

        return (allSucceeded, failedLines)
    }
}

public class ExpectPartOne<T> {
    let actual: T
    let line: Int

    init(actual: T, line: Int) {
        self.actual = actual
        self.line = line
    }

    public func to(_ matcher: Matcher<T>) {
        guard let currentScope = TestScope.currentTestScope else {
            fatalError(I18n.t(.expectOutsideOfIt))
        }

        let expect = Expect(actual: actual, matcher: matcher, line: line, negativeTest: false)
        currentScope.intake(expect)
    }

    public func toNot(_ matcher: Matcher<T>) {
        guard let currentScope = TestScope.currentTestScope else {
            fatalError(I18n.t(.expectOutsideOfIt))
        }

        let expect = Expect(actual: actual, matcher: matcher, line: line, negativeTest: true)
        currentScope.intake(expect)
    }

    public func notTo(_ matcher: Matcher<T>) {
        toNot(matcher)
    }
}

private class It {
    private let title: String
    private let mark: Mark

    let closure: () -> Void

    var expects: [Expect] = []
    var underFocus: Bool = false
    var underPending: Bool = false

    var actingFocused: Bool {
        return mark == .focused || underFocus
    }

    var actingPending: Bool {
        return mark == .pending || underPending
    }

    var displayableTitle: String {
        let prePrefix: String
        switch mark {
        case .none: prePrefix = ""
        case .focused: prePrefix = Constant.OutPutPrefix.focused
        case .pending: prePrefix = Constant.OutPutPrefix.pending
        }

        return prePrefix + Constant.OutPutPrefix.it + (title.isEmpty ? Constant.emptyTitle : title)
    }

    init(title: String, mark: Mark, closure: @escaping () -> Void) {
        self.title = title
        self.mark = mark
        self.closure = closure
    }

    func process(underFocus: Bool, underPending: Bool) {
        self.underFocus = underFocus
        self.underPending = underPending
    }

    func add(_ expect: Expect) {
        expects.append(expect)
    }

    // MARK: Helper

    private func shouldExecute(isSomethingFocused: Bool) -> Bool {
        if actingPending {
            return false
        }

        if isSomethingFocused {
            return actingFocused
        }

        return true
    }

    // MARK: - Static

    static func execute(_ its: [It], level: Int, steps: [Step], isSomethingFocused: Bool, inGroup: Bool) -> TestResult {
        if inGroup {
            return executeGroup(its, level: level, steps: steps, isSomethingFocused: isSomethingFocused)
        } else {
            return its.reduce(TestResult()) { $0 + executeGroup([$1], level: level, steps: steps, isSomethingFocused: isSomethingFocused) }
        }
    }

    // MARK: Helper

    private static func executeGroup(_ its: [It], level: Int, steps: [Step], isSomethingFocused: Bool) -> TestResult {
        let hasTestsToRun = its.reduce(false) { $0 || $1.shouldExecute(isSomethingFocused: isSomethingFocused) }
        guard hasTestsToRun else {
            return its.reduce(TestResult()) {
                let testDescription = I18n.t(.lineOutput(text: $1.displayableTitle, level: level, firstCharacter: Constant.SingleCharacter.pending))
                return $0 + TestResult(description: testDescription, total: 1, pending: 1)
            }
        }
        guard let currentScope = TestScope.currentTestScope else {
            fatalError(I18n.t(.itOutsideOfScope))
        }

        let beforeEachs = steps.filter { $0.type == .beforeEach }
        let subjectActions = steps.filter { $0.type == .subjectAction }
        let afterEachs = steps.filter { $0.type == .afterEach }

        guard subjectActions.count <= 1 else {
            fatalError(I18n.t(.tooManySubjectActions))
        }

        beforeEachs.forEach { $0.closure() }
        subjectActions.forEach { $0.closure() }
        its.forEach { currentScope.process($0) }

        let result = its.reduce(TestResult()) {
            guard $1.shouldExecute(isSomethingFocused: isSomethingFocused) else {
                let testDescription = I18n.t(.lineOutput(text: $1.displayableTitle, level: level, firstCharacter: Constant.SingleCharacter.pending))
                return $0 + TestResult(description: testDescription, total: 1, pending: 1)
            }

            let (success, failureLines) = Expect.execute($1.expects)
            let outcomeSymbol = success ? Constant.SingleCharacter.success : Constant.SingleCharacter.failure
            let testDescription = I18n.t(.lineOutput(text: $1.displayableTitle, level: level, firstCharacter: outcomeSymbol))
            return $0 + TestResult(description: testDescription, total: 1, succeeded: success ? 1 : 0, failureLines: failureLines)
        }

        afterEachs.reversed().forEach { $0.closure() }

        return result
    }
}

private class Step {
    let type: StepType
    let closure: () -> Void

    init(type: StepType, _ closure: @escaping () -> Void) {
        self.type = type
        self.closure = closure
    }
}

private class Scope: TrackedScope {
    private let title: String
    private let mark: Mark

    let type: ScopeType

    private var underFocus: Bool = false
    private var underPending: Bool = false
    private var steps: [Step] = []
    private var its: [It] = []
    private var subScopes: [Scope] = []

    private var actingFocused: Bool {
        return mark == .focused || underFocus
    }

    private var actingPending: Bool {
        return mark == .pending || underPending
    }

    private var displayableTitle: String {
        let prePrefix: String
        switch mark {
        case .none: prePrefix = ""
        case .focused: prePrefix = Constant.OutPutPrefix.focused
        case .pending: prePrefix = Constant.OutPutPrefix.pending
        }

        let prefix: String
        switch type {
        case .topLevel: prefix = prePrefix + Constant.OutPutPrefix.topLevel
        case .describe: prefix = prePrefix + Constant.OutPutPrefix.describe
        case .context: prefix = prePrefix + Constant.OutPutPrefix.context
        case .group: prefix = prePrefix + Constant.OutPutPrefix.group
        }

        let displayableDescription = title.isEmpty ? Constant.emptyTitle : title

        return prefix + displayableDescription
    }

    var hasActiveFocus: Bool {
        if actingPending {
            return false
        } else {
            let subScopeHasFocus = subScopes.reduce(false) { $0 || $1.hasActiveFocus }
            let itHasFocus = its.reduce(false) { $0 || $1.actingFocused }
            return subScopeHasFocus || itHasFocus || actingFocused
        }
    }

    init(type: ScopeType, title: String, mark: Mark) {
        self.type = type
        self.title = title
        self.mark = mark
    }

    func process(underFocus: Bool, underPending: Bool) {
        self.underFocus = underFocus
        self.underPending = underPending

        its.forEach { $0.process(underFocus: actingFocused, underPending: actingPending) }
        subScopes.forEach { $0.process(underFocus: actingFocused, underPending: actingPending) }
    }

    // MARK: - TrackerScope Protocol

    func add(_ step: Step) {
        steps.append(step)
    }

    func add(_ it: It) {
        its.append(it)
    }

    func add(_ scope: Scope) {
        subScopes.append(scope)
    }

    // MARK: static

    static func execute(_ scopes: [Scope], isSomethingFocused: Bool, level: Int = 0, accumulatedSteps: [Step] = []) -> TestResult {
        return scopes.reduce(TestResult()) {
            let aggregatedSteps = accumulatedSteps + $1.steps

            let scopeDescriptionResult = TestResult(description: I18n.t(.lineOutput(text: $1.displayableTitle, level: level, firstCharacter: Constant.SingleCharacter.blank)))
            let itsResult = It.execute($1.its, level: level + 1, steps: aggregatedSteps, isSomethingFocused: isSomethingFocused, inGroup: $1.type == .group)
            let subScopesResult = execute($1.subScopes, isSomethingFocused: isSomethingFocused, level: level + 1, accumulatedSteps: aggregatedSteps)

            return $0 + scopeDescriptionResult + itsResult + subScopesResult
        }
    }
}


private class Tracker {
    var scopes: [TrackedScope]
    var it: It?

    init(rootScope: TrackedScope) {
        self.scopes = [rootScope]
    }

    var currentScope: TrackedScope {
        return scopes.last!
    }

    func intake(_ scope: Scope, closure: () -> Void) {
        scopes.last!.add(scope)
        scopes.append(scope)
        closure()
        scopes.removeLast()
    }

    func intake(_ it: It) {
        scopes.last!.add(it)
    }

    func intake(_ step: Step) {
        scopes.last!.add(step)
    }

    func process(_ it: It) {
        self.it = it
        it.closure()
        self.it = nil
    }

    func intake(_ expect: Expect) {
        guard let it = it else {
            fatalError(I18n.t(.expectOutsideOfIt))
        }
        it.add(expect)
    }
}

private class TestScope: TrackedScope {
    static var currentTestScope: TestScope?

    private let tracker: Tracker
    private let rootScope: Scope

    private var isExecuting = false

    init(title: String, closure: () -> Void, mark: Mark) {
        rootScope = Scope(type: .topLevel, title: title, mark: mark)
        self.tracker = Tracker(rootScope: rootScope)

        TestScope.currentTestScope = self

        closure()
    }

    func intake(_ scope: Scope, closure: () -> Void) {
        ensureNotExecuting()
        tracker.intake(scope, closure: closure)
    }

    func intake(_ it: It) {
        ensureNotExecuting()
        tracker.intake(it)
    }

    func intake(_ step: Step) {
        ensureNotExecuting()
        tracker.intake(step)
    }

    func intake(_ expect: Expect) {
        guard isExecuting else {
            fatalError(I18n.t(.expectOutsideOfIt))
        }
        tracker.intake(expect)
    }

    func process(_ it: It) {
        tracker.process(it)
    }

    func execute() {
        isExecuting = true
        rootScope.process(underFocus: false, underPending: false)
        let result = Scope.execute([rootScope], isSomethingFocused: rootScope.hasActiveFocus)
        let failureLine = I18n.t(.failureOutputLine(failureLines: result.failureLines))
        let endLine = I18n.t(.endLine(totalCount: result.total, succeeded: result.succeeded, pending: result.pending))
        print(result.description + failureLine + endLine)
        isExecuting = false
    }

    // MARK: Helper

    private func ensureNotExecuting() {
        guard !isExecuting else {
            fatalError(I18n.t(.newScopesWhileExecuting))
        }
    }

    // MARK: - TrackedScope Protocol

    func add(_ scope: Scope) {
        rootScope.add(scope)
    }

    func add(_ step: Step) {
        rootScope.add(step)
    }

    func add(_ it: It) {
        rootScope.add(it)
    }
}


// MARK: Scopes

public func describe(_ title: String, _ closure: () -> Void) {
    intakeScope(type: .describe, title, closure, mark: .none)
}

public func fdescribe(_ title: String, _ closure: () -> Void) {
    intakeScope(type: .describe, title, closure, mark: .focused)
}

public func xdescribe(_ title: String, _ closure: () -> Void) {
    intakeScope(type: .describe, title, closure, mark: .pending)
}

public func context(_ title: String, _ closure: () -> Void) {
    intakeScope(type: .context, title, closure, mark: .none)
}

public func fcontext(_ title: String, _ closure: () -> Void) {
    intakeScope(type: .context, title, closure, mark: .focused)
}

public func xcontext(_ title: String, _ closure: () -> Void) {
    intakeScope(type: .context, title, closure, mark: .pending)
}

public func group(_ title: String = "", _ closure: () -> Void) {
    intakeScope(type: .group, title, closure, mark: .none)
}

public func fgroup(_ title: String = "", _ closure: () -> Void) {
    intakeScope(type: .group, title, closure, mark: .focused)
}

public func xgroup(_ title: String = "", _ closure: () -> Void) {
    intakeScope(type: .group, title, closure, mark: .pending)
}

public func it(_ title: String, _ closure: @escaping () -> Void) {
    intakeIt(title, closure: closure, mark: .none)
}

public func fit(_ title: String, _ closure: @escaping () -> Void) {
    intakeIt(title, closure: closure, mark: .focused)
}

public func xit(_ title: String, _ closure: @escaping () -> Void) {
    intakeIt(title, closure: closure, mark: .pending)
}

// MARK: Steps

public func beforeEach(_ closure: @escaping () -> Void) {
    intakeStep(type: .beforeEach, closure: closure)
}

public func subjectAction(_ closure: @escaping () -> Void) {
    intakeStep(type: .subjectAction, closure: closure)
}

public func afterEach(_ closure: @escaping () -> Void) {
    intakeStep(type: .afterEach, closure: closure)
}

// MARK: Expect

public func expect<T>(_ actual: T, line: Int = #line) -> ExpectPartOne<T> {
    return ExpectPartOne(actual: actual, line: line)
}


// Helpers

private func intakeScope(type: ScopeType, _ title: String, _ closure: () -> Void, mark: Mark) {
    if let testScope = TestScope.currentTestScope {
        testScope.intake(Scope(type: type, title: title, mark: mark), closure: closure)
    } else {
        newTest(title: title, closure: closure, mark: mark)
    }
}

private func intakeStep(type: StepType, closure: @escaping () -> Void) {
    guard let currentScope = TestScope.currentTestScope else {
        fatalError(I18n.t(.stepOutsideOfScope(type)))
    }

    currentScope.intake(Step(type: type, closure))
}

private func intakeIt(_ title: String, closure: @escaping () -> Void, mark: Mark) {
    guard let currentScope = TestScope.currentTestScope else {
        fatalError(I18n.t(.itOutsideOfScope))
    }

    currentScope.intake(It(title: title, mark: mark, closure: closure))
}

private func newTest(title: String, closure: () -> Void, mark: Mark) {
    let testScope = TestScope(title: title, closure: closure, mark: mark)
    testScope.execute()
    TestScope.currentTestScope = nil
}
