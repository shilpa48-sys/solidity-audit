// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Return early from function
CONCEPT: Execution stopping
=========================================================

OBJECTIVE

- Learn how early return works
- Understand execution stopping behavior
- Learn control-flow optimization
- Understand auditor-style execution tracing

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

return immediately stops:
- function execution
- remaining code execution
- further state changes

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Once return executes:

Everything after it is skipped.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Early return is heavily used for:

- validation
- optimization
- branch control
- error handling
- gas reduction

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Used in:

- ERC20 logic
- DeFi routers
- staking systems
- access control
- governance systems
- liquidation checks

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- skipped code paths
- unreachable logic
- missed state updates
- incorrect return placement
- authorization bypasses

=========================================================
*/

contract EarlyReturnExample {

    /*
        STORAGE VARIABLES
    */
    mapping(address => uint256) public balances;

    bool public paused;

    /*
    =====================================================
    TOGGLE PAUSE
    =====================================================
    */

    function setPaused(
        bool _status
    )
        external
    {

        paused = _status;
    }

    /*
    =====================================================
    EARLY RETURN EXAMPLE
    =====================================================
    */

    function deposit(
        uint256 _amount
    )
        external
    {

        /*
            STEP 1:
            Check paused state.
        */
        if (paused == true) {

            /*
                EARLY RETURN

                Function stops here.
            */
            return;
        }

        /*
            STEP 2:
            Reject zero amount.
        */
        if (_amount == 0) {

            /*
                EARLY RETURN

                Remaining code skipped.
            */
            return;
        }

        /*
            STEP 3:
            Update balance.

            Executes ONLY if:
            - not paused
            - amount > 0
        */
        balances[msg.sender] += _amount;
    }

    /*
    =====================================================
    RETURN VALUE EARLY
    =====================================================
    */

    function checkLevel(
        uint256 _score
    )
        external
        pure
        returns (string memory)
    {

        /*
            FIRST BRANCH
        */
        if (_score >= 90) {

            return "Elite";
        }

        /*
            SECOND BRANCH
        */
        if (_score >= 50) {

            return "Standard";
        }

        /*
            DEFAULT BRANCH
        */
        return "Rejected";
    }

    /*
    =====================================================
    UNREACHABLE CODE DEMO
    =====================================================
    */

    function unreachableExample()
        external
        pure
        returns (uint256)
    {

        /*
            FUNCTION RETURNS HERE
        */
        return 100;

        /*
            UNREACHABLE CODE

            Never executes.
        */

        // uint256 x = 999;
    }
}
//patched code
contract EarlyReturnExamplePatched {

    mapping(address => uint256) public balances;

    mapping(address => bool) public blacklisted;

    bool public paused;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Not owner"
        );
        _;
    }

    function setPaused(
        bool _status
    )
        external
        onlyOwner
    {
        paused = _status;
    }

    function setBlacklist(
        address _user,
        bool _status
    )
        external
        onlyOwner
    {
        blacklisted[_user] = _status;
    }

    /*
        Early return version
    */
    function deposit(
        uint256 _amount
    )
        external
    {
        if (paused) {
            return;
        }

        if (blacklisted[msg.sender]) {
            return;
        }

        if (_amount == 0) {
            return;
        }

        balances[msg.sender] += _amount;
    }

    /*
        Require version
    */
    function depositWithRequire(
        uint256 _amount
    )
        external
    {
        require(
            !paused,
            "Contract paused"
        );

        require(
            !blacklisted[msg.sender],
            "Blacklisted user"
        );

        require(
            _amount > 0,
            "Invalid amount"
        );

        balances[msg.sender] += _amount;
    }

    /*
        Multiple nested early returns
    */
    function specialDeposit(
        uint256 _amount
    )
        external
    {
        if (paused) return;

        if (blacklisted[msg.sender]) return;

        if (_amount == 0) return;

        if (_amount > 1000) return;

        balances[msg.sender] += _amount;
    }
}

/*
Report
Title:

Missing Access Control on Pause and Blacklist Logic

Severity:

Medium

Reason:

The patched contract introduces critical control-flow mechanisms (paused state and blacklist checks), but if these controls can be modified by arbitrary users, attackers may manipulate execution flow by pausing the contract or altering blacklist status.

Location:

Contract: EarlyReturnExamplePatched
Functions: setPaused(), setBlacklist()

Vulnerability Description:

The patched contract adds:

Blacklist functionality
Early-return logic for blacklisted users
require()-based blacklist enforcement
Pause mechanism

These controls directly affect whether users can execute deposits.

If proper ownership checks are not implemented, any user may:

Pause the contract
Unpause the contract
Blacklist arbitrary users
Remove users from the blacklist

This allows unauthorized manipulation of contract behavior and denial-of-service against legitimate users.

Impact:

Unauthorized users may gain control over critical execution guards.

Possible consequences include:

Blocking legitimate deposits
Arbitrary user blacklisting
Unauthorized contract pausing
Denial-of-service conditions
Loss of protocol availability
Proof of Concept:
Scenario 1: Unauthorized Pause
Deploy contract
Alice deposits successfully
Bob calls:
setPaused(true);
Alice calls:
deposit(100);
Function exits early

Result:

balances[Alice]

remains unchanged.

Scenario 2: Unauthorized Blacklisting
Bob calls:
setBlacklist(Alice, true);
Alice calls:
depositWithRequire(50);
Transaction reverts

Result:

Alice is denied service by an unauthorized user.

Observation:

Critical security controls are exposed to all users.

Attackers can manipulate execution flow without authorization.

Root Cause:

Missing access-control validation on administrative functions.

Example vulnerable pattern:

function setPaused(bool _status) external {
    paused = _status;
}

function setBlacklist(
    address _user,
    bool _status
)
    external
{
    blacklisted[_user] = _status;
}

No ownership verification exists.

Recommendation:

Restrict administrative functions to the contract owner.

Example:

modifier onlyOwner() {
    require(
        msg.sender == owner,
        "Not owner"
    );
    _;
}

Apply modifier:

function setPaused(
    bool _status
)
    external
    onlyOwner
{
    paused = _status;
}

function setBlacklist(
    address _user,
    bool _status
)
    external
    onlyOwner
{
    blacklisted[_user] = _status;
}

This ensures only authorized users can modify critical execution controls.
Security Improvement:

The patched implementation:

Adds ownership protection
Prevents unauthorized pausing
Prevents arbitrary blacklisting
Demonstrates early-return behavior safely
Demonstrates require()-based validation safely
Preserves the educational objective while preventing privilege abuse
Provides a clear comparison between silent exits and transaction reverts for auditors and students
/*

=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

paused = false

balances[Alice] = 0

=========================================================
TRACE:
deposit(10)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

if (paused == true)

CHECK:
false == true

RESULT:
false

Execution continues.

---------------------------------------------------------
STEP 2
---------------------------------------------------------

if (_amount == 0)

CHECK:
10 == 0

RESULT:
false

Execution continues.

---------------------------------------------------------
STEP 3
---------------------------------------------------------

balances[Alice] += 10

FINAL STATE:

balances[Alice] = 10

=========================================================
EARLY RETURN TRACE
=========================================================

SET:
paused = true

---------------------------------------------------------

CALL:
deposit(10)

---------------------------------------------------------
STEP 1
---------------------------------------------------------

if (paused == true)

CHECK:
true == true

RESULT:
true

---------------------------------------------------------

RETURN EXECUTES

---------------------------------------------------------

FUNCTION STOPS IMMEDIATELY

---------------------------------------------------------

STEP 2 and STEP 3 NEVER EXECUTE

---------------------------------------------------------

FINAL STATE:

balances[Alice] unchanged

=========================================================
ANOTHER TRACE
=========================================================

CALL:
checkLevel(95)

---------------------------------------------------------

FIRST IF:
95 >= 90

RESULT:
true

---------------------------------------------------------

RETURN "Elite"

---------------------------------------------------------

FUNCTION ENDS IMMEDIATELY

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
deposit(10)

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
10

---------------------------------------------------------

STEP 4:
Call:
setPaused(true)

---------------------------------------------------------

STEP 5:
Call:
deposit(50)

---------------------------------------------------------

STEP 6:
Call:
balances(your_address)

EXPECTED:
Still 10

---------------------------------------------------------

OBSERVE:
Function returned early.

---------------------------------------------------------

STEP 7:
Call:
checkLevel(95)

EXPECTED:
"Elite"

---------------------------------------------------------

STEP 8:
Call:
checkLevel(60)

EXPECTED:
"Standard"

---------------------------------------------------------

STEP 9:
Call:
checkLevel(20)

EXPECTED:
"Rejected"

=========================================================
IMPORTANT EXECUTION UNDERSTANDING
=========================================================

return does TWO things:

1. optionally returns value
2. STOPS execution immediately

=========================================================
VERY IMPORTANT
=========================================================

Any code AFTER return:
is unreachable.

---------------------------------------------------------

Unreachable code:
never executes.

=========================================================
EARLY RETURN VS REQUIRE
=========================================================

---------------------------------------------------------
EARLY RETURN
---------------------------------------------------------

- Stops execution silently
- No revert
- State before return persists

---------------------------------------------------------
REQUIRE
---------------------------------------------------------

- Reverts transaction
- Undoes state changes
- Throws error

=========================================================
WHEN EARLY RETURN IS USEFUL
=========================================================

GOOD FOR:

- optional execution
- gas optimization
- branch exits
- skip logic
- read-only checks

=========================================================
WHEN REQUIRE IS BETTER
=========================================================

GOOD FOR:

- validation
- security rules
- invariant enforcement
- authorization

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. SKIPPED SECURITY CHECKS
---------------------------------------------------------

Early return may bypass logic accidentally.

---------------------------------------------------------
2. UNREACHABLE CODE
---------------------------------------------------------

Dead code increases confusion.

---------------------------------------------------------
3. PARTIAL EXECUTION
---------------------------------------------------------

Some state may update
before early return.

---------------------------------------------------------
4. LOGIC FRAGMENTATION
---------------------------------------------------------

Too many returns make auditing harder.

=========================================================
GAS OBSERVATION
=========================================================

Early return:
can reduce gas usage.

---------------------------------------------------------

Reason:
remaining code skipped.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Which paths return early?
- What code becomes unreachable?
- Are security checks skipped?
- Can attacker abuse branch exits?
- Does state remain consistent?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Developer places return incorrectly.

Critical validation skipped.

Result:
authorization bypass.

---------------------------------------------------------

ANOTHER RISK

Partial state update before return
may break invariants.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Every return point
2. Remaining skipped logic
3. State before return
4. State after return
5. Reachable vs unreachable code

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add blacklist logic
2. Return early for blacklisted users
3. Add require() version too
4. Compare behavior carefully

BONUS:
Create function with:
multiple nested early returns.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- return stops execution immediately
- Remaining code becomes unreachable
- Early return does NOT revert transaction
- require() and return behave differently
- Early returns can optimize gas
- Incorrect returns may skip security checks
- Auditors trace all execution exits
- Branch analysis is critical
- Partial execution must be understood
- Control flow impacts security heavily

=========================================================
*/