// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Update state before require
CONCEPT: State rollback behavior
=========================================================

OBJECTIVE

- Learn what happens when require() fails
- Understand transaction rollback behavior
- Learn EVM atomicity guarantees
- Understand why reverted state changes disappear

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

If require() fails:

ALL state changes in the transaction
are reverted automatically.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Even if storage was updated BEFORE require():

A revert undoes everything.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

This is one of the MOST IMPORTANT
EVM security guarantees.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Rollback behavior protects:

- balances
- token transfers
- DeFi accounting
- governance state
- auction logic

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- execution order
- state updates before external calls
- revert handling
- atomicity assumptions
- partial-update risks

=========================================================
*/

contract StateRollbackBehavior {

    /*
        STORAGE VARIABLES

        Persist permanently unless reverted.
    */
    uint256 public totalCounter;

    mapping(address => uint256) public userCounter;

    /*
    =====================================================
    UPDATE STATE BEFORE REQUIRE
    =====================================================
    */

    function riskyIncrement(
        uint256 _value
    )
        external
    {

        /*
            STEP 1:
            UPDATE STORAGE

            State changes happen immediately
            during execution.
        */
        totalCounter =
            totalCounter + _value;

        userCounter[msg.sender] =
            userCounter[msg.sender] + _value;

        /*
            STEP 2:
            REQUIRE CHECK

            If this fails:
            ALL earlier storage changes revert.
        */
        require(
            _value <= 10,
            "Value too large"
        );
    }

    /*
    =====================================================
    SAFE VERSION
    =====================================================

    Validation first.
    */

    function safeIncrement(
        uint256 _value
    )
        external
    {

        /*
            VALIDATE FIRST
        */
        require(
            _value <= 10,
            "Value too large"
        );

        /*
            UPDATE STATE AFTER VALIDATION
        */
        totalCounter =
            totalCounter + _value;

        userCounter[msg.sender] =
            userCounter[msg.sender] + _value;
    }
}
//patched code
contract StateRollbackBehaviorPatched {

    error InsufficientBalance();
    error ValueTooLarge();

    uint256 public totalCounter;

    mapping(address => uint256) public userCounter;

    function safeIncrement(
        uint256 _value
    )
        external
    {
        if (_value > 10)
            revert ValueTooLarge();

        totalCounter =
            totalCounter + _value;

        userCounter[msg.sender] =
            userCounter[msg.sender] + _value;
    }

    /*
    =====================================================
    WITHDRAW USING CEI
    =====================================================
    */

    function withdraw(
        uint256 _amount
    )
        external
    {
        /*
            CHECKS
        */
        if (
            userCounter[msg.sender]
            < _amount
        ) {
            revert InsufficientBalance();
        }

        /*
            EFFECTS
        */
        userCounter[msg.sender] =
            userCounter[msg.sender]
            - _amount;

        totalCounter =
            totalCounter
            - _amount;

        /*
            INTERACTIONS

            None in this example.
        */
    }
}
/*
Audit report
Title:

Late Validation Causes Unnecessary State Updates Before Revert

Severity:

Low

Reason:

The riskyIncrement() function updates storage before performing validation.

Although the EVM correctly reverts all state changes when require() fails, performing storage writes before validation wastes gas and violates the recommended Checks-Effects-Interactions (CEI) pattern.

Location:

Contract: StateRollbackBehavior

Function: riskyIncrement()

Vulnerability Description:

The contract updates:

totalCounter =
    totalCounter + _value;

userCounter[msg.sender] =
    userCounter[msg.sender] + _value;

before executing:

require(
    _value <= 10,
    "Value too large"
);

If _value > 10, the transaction reverts and all storage writes are rolled back.

While no permanent corruption occurs because Ethereum transactions are atomic, the storage writes are still executed internally before the revert, causing unnecessary gas consumption.

Impact:

No direct loss of funds occurs.

Possible consequences include:

Unnecessary gas expenditure
Inefficient execution
Poor coding practice
Violation of CEI pattern
Increased attack surface for gas griefing
Proof of Concept:
Initial State
totalCounter = 0
userCounter[Alice] = 0
Step 1

Alice calls:

riskyIncrement(50)
Step 2

Temporary execution:

totalCounter = 50
userCounter[Alice] = 50
Step 3

Validation executes:

require(50 <= 10);

Result:

false
Step 4

Transaction reverts.

Final State
totalCounter = 0
userCounter[Alice] = 0
Observation:

State updates were performed but later discarded by the EVM rollback mechanism.

Root Cause:

Validation occurs after state modification.

totalCounter =
    totalCounter + _value;

userCounter[msg.sender] =
    userCounter[msg.sender] + _value;

require(
    _value <= 10,
    "Value too large"
);
Recommendation:

Always validate inputs before performing storage writes.

Follow:

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

INITIAL STATE

totalCounter = 0

userCounter[Alice] = 0

=========================================================
TRACE:
riskyIncrement(5)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

totalCounter =
0 + 5

NEW VALUE:
5

---------------------------------------------------------
STEP 2
---------------------------------------------------------

userCounter[Alice] =
0 + 5

NEW VALUE:
5

---------------------------------------------------------
STEP 3
---------------------------------------------------------

require(5 <= 10)

RESULT:
true

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

totalCounter = 5

userCounter[Alice] = 5

=========================================================
TRACE:
riskyIncrement(50)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

totalCounter =
5 + 50

TEMP VALUE:
55

---------------------------------------------------------
STEP 2
---------------------------------------------------------

userCounter[Alice] =
5 + 50

TEMP VALUE:
55

---------------------------------------------------------
STEP 3
---------------------------------------------------------

require(50 <= 10)

RESULT:
false

---------------------------------------------------------
TRANSACTION REVERTS
---------------------------------------------------------

ALL STATE CHANGES UNDONE.

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

totalCounter = 5

userCounter[Alice] = 5

---------------------------------------------------------

IMPORTANT:
Temporary updates disappear.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
riskyIncrement(5)

---------------------------------------------------------

STEP 3:
Call:
totalCounter()

EXPECTED:
5

---------------------------------------------------------

STEP 4:
Call:
riskyIncrement(50)

EXPECTED:
Transaction reverts

---------------------------------------------------------

STEP 5:
Call:
totalCounter()

EXPECTED:
Still 5

---------------------------------------------------------

STEP 6:
Call:
userCounter(your_address)

EXPECTED:
Still 5

---------------------------------------------------------

OBSERVE:
Failed transaction changed NOTHING.

=========================================================
IMPORTANT EVM UNDERSTANDING
=========================================================

ETHEREUM TRANSACTIONS ARE:

ATOMIC

---------------------------------------------------------

Meaning:

Either:
- EVERYTHING succeeds

OR:
- EVERYTHING reverts

=========================================================
ROLLBACK MECHANISM
=========================================================

When require() fails:

EVM:
- discards storage writes
- discards state changes
- refunds remaining gas
- reverts execution

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

TEMPORARY STORAGE CHANGES
can exist DURING execution.

---------------------------------------------------------

BUT:
they disappear after revert.

=========================================================
WHY VALIDATION-FIRST IS BETTER
=========================================================

THIS IS PREFERRED:

1. validate
2. update state

---------------------------------------------------------

Reason:
Avoid wasted computation/gas.

=========================================================
BAD PATTERN
=========================================================

1. update storage
2. validate later

---------------------------------------------------------

Problem:
Wasted gas if revert occurs.

=========================================================
GAS OBSERVATION
=========================================================

REVERTS:
Undo state changes

---------------------------------------------------------

BUT:
Gas already consumed is NOT fully refunded.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. VALIDATE BEFORE STATE CHANGES
---------------------------------------------------------

Auditors prefer:
Checks -> Effects -> Interactions

---------------------------------------------------------
2. UNDERSTAND ATOMICITY
---------------------------------------------------------

Partial state updates cannot persist
after revert.

---------------------------------------------------------
3. EXTERNAL CALL RISKS
---------------------------------------------------------

If external calls happen before revert,
complex behaviors may occur.

---------------------------------------------------------
4. GAS WASTAGE
---------------------------------------------------------

Late validation wastes gas.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker intentionally triggers reverts
after expensive computation.

Result:
Gas griefing / DOS potential.

---------------------------------------------------------

ANOTHER RISK

Incorrect assumptions about rollback
may create accounting vulnerabilities.

=========================================================
REAL AUDITOR PATTERN
=========================================================

AUDITORS TRACE:

1. What changes first?
2. What can revert?
3. Are external calls involved?
4. Can partial execution leak effects?
5. Is CEI pattern followed?

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add withdraw() function
2. Update balance before require()
3. Observe rollback manually
4. Then rewrite using:
Checks -> Effects -> Interactions

BONUS:
Add custom errors instead of require strings.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Ethereum transactions are atomic
- require() failure reverts all state changes
- Storage updates disappear after revert
- Temporary execution state exists internally
- Validation-first is preferred
- Late validation wastes gas
- Reverts undo storage writes
- CEI pattern improves security
- Auditors trace rollback behavior carefully
- State persistence only happens on success

=========================================================
*/