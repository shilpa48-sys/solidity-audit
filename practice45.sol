// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Use modifier after function
CONCEPT: Post-execution flow
=========================================================

OBJECTIVE

- Learn modifier post-execution behavior
- Understand code execution after _;
- Learn execution wrapping flow
- Understand advanced modifier architecture

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Modifiers can execute:
- BEFORE function body
- AFTER function body

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

The special symbol:

_;

represents:
"insert function body here"

---------------------------------------------------------

Code:
BEFORE _;  -> pre-execution
AFTER  _;  -> post-execution

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Post-execution modifiers are used for:

- cleanup logic
- logging
- invariant checks
- reentrancy unlocking
- accounting verification

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Post-execution logic appears in:

- ReentrancyGuard
- fee settlement systems
- invariant validation
- logging frameworks
- protocol accounting

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- hidden post-state mutations
- execution ordering
- invariant enforcement
- modifier side effects
- reentrancy lock release

=========================================================
*/

contract PostExecutionModifier {

    /*
        OWNER ADDRESS
    */
    address public owner;

    /*
        EXECUTION STATUS
    */
    bool public locked;

    /*
        LAST ACTION TRACKER
    */
    string public lastAction;

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
        CONSTRUCTOR
    */
    constructor() {

        owner = msg.sender;
    }

    /*
    =====================================================
    MODIFIER WITH POST-EXECUTION LOGIC
    =====================================================
    */

    modifier trackExecution() {

        /*
            PRE-EXECUTION LOGIC
        */
        lastAction = "Function started";

        /*
            FUNCTION BODY EXECUTES HERE
        */
        _;

        /*
            POST-EXECUTION LOGIC

            Executes AFTER function body.
        */
        lastAction = "Function completed";
    }

    /*
    =====================================================
    REENTRANCY-STYLE MODIFIER
    =====================================================
    */

    modifier noReentrant() {

        /*
            PRE-EXECUTION CHECK
        */
        require(
            locked == false,
            "Reentrant call blocked"
        );

        /*
            LOCK BEFORE FUNCTION EXECUTION
        */
        locked = true;

        /*
            FUNCTION BODY EXECUTES HERE
        */
        _;

        /*
            UNLOCK AFTER FUNCTION EXECUTION

            POST-EXECUTION FLOW
        */
        locked = false;
    }

    /*
    =====================================================
    FUNCTION USING POST MODIFIER
    =====================================================
    */

    function deposit(
        uint256 _amount
    )
        external
        trackExecution
    {

        /*
            Function body.
        */
        require(
            _amount > 0,
            "Invalid amount"
        );

        balances[msg.sender] += _amount;
    }

    /*
    =====================================================
    FUNCTION USING REENTRANCY-STYLE MODIFIER
    =====================================================
    */

    function secureDeposit(
        uint256 _amount
    )
        external
        noReentrant
    {

        /*
            Function executes while locked=true.
        */
        require(
            _amount > 0,
            "Invalid amount"
        );

        balances[msg.sender] += _amount;
    }
}
//patched code
contract PostExecutionModifierPatched {

    address public owner;

    bool public locked;

    string public lastAction;

    uint256 public executionCount;

    uint256 public failedAttempts;

    mapping(address => uint256) public balances;

    event FunctionExecuted(
        address indexed user,
        string action,
        uint256 totalExecutions
    );

    error InvalidAmount();
    error ReentrantCall();
    error ZeroAddress();

    constructor() {
        owner = msg.sender;
    }

    /*
    =====================================================
    EXECUTION TRACKER MODIFIER
    =====================================================
    */

    modifier trackExecution() {

        lastAction = "Function started";

        _;

        executionCount++;

        lastAction = "Function completed";

        emit FunctionExecuted(
            msg.sender,
            "deposit",
            executionCount
        );
    }

    /*
    =====================================================
    CUSTOM NON-REENTRANT
    =====================================================
    */

    modifier nonReentrant() {

        if (locked) {
            failedAttempts++;
            revert ReentrantCall();
        }

        locked = true;

        _;

        locked = false;
    }

    /*
    =====================================================
    DEPOSIT
    =====================================================
    */

    function deposit(
        uint256 _amount
    )
        external
        trackExecution
    {
        if (_amount == 0) {
            failedAttempts++;
            revert InvalidAmount();
        }

        balances[msg.sender] += _amount;
    }

    /*
    =====================================================
    SECURE DEPOSIT
    =====================================================
    */

    function secureDeposit(
        uint256 _amount
    )
        external
        nonReentrant
        trackExecution
    {
        if (_amount == 0) {
            failedAttempts++;
            revert InvalidAmount();
        }

        balances[msg.sender] += _amount;
    }
}
/* 
Audit Report 
Scope

Contract Reviewed:

PostExecutionModifierPatched
Medium Severity
Failed Attempt Counter Can Be Bypassed
Description

The challenge requests a failed-attempt tracker.

Current implementation:

failedAttempts++;
revert InvalidAmount();

However:

revert

rolls back all state updates.

Therefore:

failedAttempts++

is reverted too.

Result:

failedAttempts

never increases.

Impact

Failed attempts are not actually tracked.

Monitoring becomes ineffective.

Recommendation

Use:

Events
Off-chain monitoring
try/catch in caller contracts

instead of storing failed attempts before revert.

Example

Bad:

failedAttempts++;
revert();

Good:

emit FailedAttempt(msg.sender);
revert();
Finding 2
Low Severity
Hardcoded Event Action Name
Description

Modifier emits:

"deposit"

for every function.

If modifier is reused:

withdraw()
transfer()
stake()

event becomes inaccurate.

Recommendation

Pass action name through modifier.

Example:

modifier trackExecution(
    string memory action
)
Finding 3
Low Severity
Expensive String Storage
Description

State variable:

string public lastAction;

writes:

"Function started"
"Function completed"

every call.

Storage writes are expensive.

Impact

Unnecessary gas consumption.

Recommendation

Replace with:

enum Status {
    None,
    Started,
    Completed
}

or use events only.

Finding 4
Informational
Custom Errors Properly Implemented

Good practice:

error InvalidAmount();
error ReentrantCall();

Benefits:

cheaper gas
cleaner code
standardized error handling
Finding 5
Informational
Non-Reentrant Pattern Correct

Implementation:

locked = true;
_;
locked = false;

follows standard lock/unlock architecture.

No reentrancy issue detected.

Finding 6
Informational
Post-Execution Modifier Works Correctly

Execution flow:

Modifier Start
      ↓
Function Body
      ↓
Execution Counter++
      ↓
Event Emission

Demonstrates post-execution behavior correctly.

Finding 7
Informational
CEI Pattern Not Required But Recommended

Current contract only updates storage.

No external calls exist.

If future code adds:

call
transfer
send
token.transfer

then follow:

Checks
↓
Effects
↓
Interactions
*/
/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
deposit(50)

=========================================================

STEP 1:
Modifier executes FIRST.

---------------------------------------------------------

trackExecution()

---------------------------------------------------------

PRE-EXECUTION:

lastAction =
"Function started"

---------------------------------------------------------

STEP 2:
_; reached

Execution enters function body.

---------------------------------------------------------

STEP 3:
Function body executes.

balances[Alice] += 50

---------------------------------------------------------

STEP 4:
Function body finishes.

Execution RETURNS to modifier.

---------------------------------------------------------

STEP 5:
POST-EXECUTION runs.

lastAction =
"Function completed"

---------------------------------------------------------

FINAL STATE:

balances[Alice] = 50

lastAction =
"Function completed"

=========================================================
REENTRANCY MODIFIER TRACE
=========================================================

CALL:
secureDeposit(100)

=========================================================

STEP 1:
Modifier executes.

---------------------------------------------------------

CHECK:
locked == false

RESULT:
true

---------------------------------------------------------

STEP 2:
locked = true

---------------------------------------------------------

STEP 3:
_; reached

Function body executes.

---------------------------------------------------------

STEP 4:
balances[Alice] += 100

---------------------------------------------------------

STEP 5:
Function body finishes.

---------------------------------------------------------

STEP 6:
POST-EXECUTION LOGIC

locked = false

---------------------------------------------------------

FINAL STATE:

locked = false

=========================================================
IMPORTANT EXECUTION MODEL
=========================================================

Modifier wraps function body.

---------------------------------------------------------

FLOW:

modifier start
    ->
function body
    ->
modifier end

=========================================================
VISUAL EXECUTION FLOW
=========================================================

trackExecution()
{
    before logic

    _;

    after logic
}

---------------------------------------------------------

deposit()
is inserted at _;

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
deposit(50)

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
50

---------------------------------------------------------

STEP 4:
Call:
lastAction()

EXPECTED:
"Function completed"

---------------------------------------------------------

STEP 5:
Call:
secureDeposit(100)

---------------------------------------------------------

STEP 6:
Call:
locked()

EXPECTED:
false

---------------------------------------------------------

OBSERVE:
Modifier unlocked AFTER execution.

=========================================================
VERY IMPORTANT SECURITY UNDERSTANDING
=========================================================

Post-execution modifier code
runs ONLY if execution reaches it.

---------------------------------------------------------

If transaction reverts:
post-execution code may NOT execute.

=========================================================
CRITICAL REENTRANCY UNDERSTANDING
=========================================================

noReentrant pattern:

1. lock before execution
2. execute function
3. unlock after execution

---------------------------------------------------------

This protects:
against nested reentrant calls.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. HIDDEN POST-STATE MUTATIONS
---------------------------------------------------------

Modifiers may silently:
change storage AFTER execution.

---------------------------------------------------------
2. LOCK NEVER RELEASED
---------------------------------------------------------

If unlock logic incorrect:
contract may freeze.

---------------------------------------------------------
3. EXECUTION ORDER BUGS
---------------------------------------------------------

Post-execution logic may:
break assumptions.

---------------------------------------------------------
4. MODIFIER SIDE EFFECTS
---------------------------------------------------------

Complex modifiers increase audit difficulty.

=========================================================
GAS OBSERVATION
=========================================================

Post-execution logic:
adds additional gas cost.

---------------------------------------------------------

Complex modifier chains:
increase execution complexity.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- What executes after _; ?
- Can post-logic fail?
- Are locks always released?
- Does modifier mutate state?
- Is execution order safe?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Developer forgets:
unlock step after execution.

Result:
permanent DOS/frozen contract.

---------------------------------------------------------

ANOTHER RISK

Post-execution modifier
changes state unexpectedly.

Result:
hidden accounting bug.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Pre-modifier logic
2. Function execution
3. Post-modifier logic
4. Revert behavior
5. Lock/unlock guarantees

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add execution counter modifier
2. Increment counter AFTER function
3. Add failed-attempt tracker
4. Add event emission after execution

BONUS:
Build complete custom:
nonReentrant modifier.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Modifiers can execute after function body
- _; represents function insertion point
- Post-execution logic wraps function execution
- Reentrancy guards use post-execution unlock flow
- Modifiers may mutate state after execution
- Execution order matters heavily
- Failed execution may skip post-logic
- Hidden modifier effects increase audit complexity
- Auditors trace modifier wrapping carefully
- Modifier flow is critical for smart contract security

=========================================================
*/