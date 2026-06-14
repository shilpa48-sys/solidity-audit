// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Fail require after state update
CONCEPT: Transaction atomicity
=========================================================

OBJECTIVE

- Learn Ethereum transaction atomicity
- Understand rollback after require() failure
- Observe temporary vs permanent state changes
- Learn why partial updates cannot persist

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

If require() fails:

EVERYTHING inside the transaction
is reverted.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Even if:
- storage updated
- balances changed
- counters incremented

A revert removes ALL changes.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Atomicity is a core EVM guarantee.

Without atomicity:
partial state corruption would occur.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Atomicity protects:

- ERC20 transfers
- DeFi accounting
- lending protocols
- AMMs
- auctions
- governance systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- state updates before revert points
- external call ordering
- partial execution assumptions
- transaction rollback behavior
- CEI pattern compliance

=========================================================
*/

contract TransactionAtomicity {

    /*
        STORAGE VARIABLES

        Persist only if transaction succeeds.
    */
    uint256 public globalCounter;

    mapping(address => uint256) public balances;

    /*
    =====================================================
    FAIL REQUIRE AFTER STATE UPDATE
    =====================================================
    */

    function brokenExecution(
        uint256 _amount
    )
        external
    {

        /*
            STEP 1:
            UPDATE GLOBAL COUNTER

            Temporary state update.
        */
        globalCounter =
            globalCounter + _amount;

        /*
            STEP 2:
            UPDATE USER BALANCE

            Temporary state update.
        */
        balances[msg.sender] =
            balances[msg.sender] + _amount;

        /*
            STEP 3:
            REQUIRE FAILURE

            If _amount > 5:
            transaction reverts completely.
        */
        require(
            _amount <= 5,
            "Amount too large"
        );
    }

    /*
    =====================================================
    SAFE EXECUTION
    =====================================================

    Validation first.
    */

    function safeExecution(
        uint256 _amount
    )
        external
    {

        /*
            VALIDATE BEFORE CHANGES
        */
        require(
            _amount <= 5,
            "Amount too large"
        );

        /*
            UPDATE STATE AFTER VALIDATION
        */
        globalCounter =
            globalCounter + _amount;

        balances[msg.sender] =
            balances[msg.sender] + _amount;
    }
}

//patched code
interface IReceiver {
    function receiveTokens(
        uint256 amount
    ) external;
}

contract TransactionAtomicityPatched {

    error AmountTooLarge();

    uint256 public globalCounter;

    mapping(address => uint256) public balances;

    /*
    =====================================================
    UNSAFE VERSION FOR DEMONSTRATION
    =====================================================
    */

    function unsafeTransfer(
        address _receiver,
        uint256 _amount
    )
        external
    {
        globalCounter =
            globalCounter + _amount;

        balances[msg.sender] =
            balances[msg.sender] + _amount;

        IReceiver(_receiver)
            .receiveTokens(_amount);

        if (_amount > 5) {
            revert AmountTooLarge();
        }
    }

    /*
    =====================================================
    PATCHED CEI VERSION
    =====================================================
    */

    function safeTransfer(
        address _receiver,
        uint256 _amount
    )
        external
    {
        /*
            CHECKS
        */
        if (_amount > 5) {
            revert AmountTooLarge();
        }

        /*
            EFFECTS
        */
        globalCounter =
            globalCounter + _amount;

        balances[msg.sender] =
            balances[msg.sender] + _amount;

        /*
            INTERACTIONS
        */
        IReceiver(_receiver)
            .receiveTokens(_amount);
    }
}

/*Report
Title:

External Call Before Revert Demonstrates Unsafe Execution Ordering

Severity:

Medium

Reason:

The contract demonstrates transaction atomicity and rollback behavior but does not include an external interaction scenario.

Developers may incorrectly assume that all effects of an external call are automatically safe simply because a later require() reverts.

Introducing an external call before a revert point is a useful auditing exercise because external interactions complicate execution flow and can introduce reentrancy risks if not ordered correctly.

Location:

Contract: TransactionAtomicity

Function: brokenExecution()

Vulnerability Description:

The contract updates state before validation:

globalCounter =
    globalCounter + _amount;

balances[msg.sender] =
    balances[msg.sender] + _amount;

require(
    _amount <= 5,
    "Amount too large"
);

While EVM atomicity correctly reverts all state changes when require() fails, the example does not demonstrate the more dangerous real-world case where an external interaction occurs before a revert point.

Auditors frequently review contracts where:

state is modified
external calls occur
execution later reverts

Understanding this ordering is critical because external calls increase complexity and may expose reentrancy opportunities if CEI is not followed.

Impact:

Potential consequences in real protocols include:

Reentrancy exposure
Unexpected execution flow
Difficult-to-audit logic
Gas griefing opportunities
Unsafe interaction ordering
Proof of Concept
Initial State
globalCounter = 0
balances[Alice] = 0
Step 1

Alice calls:

unsafeTransfer(10)
Step 2

Contract updates state:

globalCounter = 10
balances[Alice] = 10
Step 3

External call executes.

Step 4

Validation runs:

require(
    _amount <= 5,
    "Amount too large"
);

Result:

false
Step 5

Transaction reverts.

Final State
globalCounter = 0
balances[Alice] = 0
Observation:

State changes are rolled back because of EVM atomicity.

However, placing external interactions before validation violates the recommended Checks-Effects-Interactions pattern and creates audit complexity.

Root Cause:

Execution ordering:

State Update
    ↓
External Call
    ↓
Validation

instead of:

Checks
    ↓
Effects
    ↓
Interactions
Recommendation:

Follow the CEI pattern:

Validate input
Update internal state
Perform external interactions

Use custom errors for gas efficiency.
Patched Code:

The patched contract adds an external token-transfer style interaction and 
demonstrates both unsafe and safe execution ordering. 
The secure implementation validates inputs before modifying state and performs the external interaction last, 
following the Checks-Effects-Interactions pattern and reducing audit risk.
*/

/*
=========================================================
INITIAL STATE
=========================================================

globalCounter = 0

balances[Alice] = 0

=========================================================
TRACE:
brokenExecution(3)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

globalCounter =
0 + 3

TEMP VALUE:
3

---------------------------------------------------------
STEP 2
---------------------------------------------------------

balances[Alice] =
0 + 3

TEMP VALUE:
3

---------------------------------------------------------
STEP 3
---------------------------------------------------------

require(3 <= 5)

RESULT:
true

---------------------------------------------------------
TRANSACTION SUCCEEDS
---------------------------------------------------------

FINAL STATE:

globalCounter = 3

balances[Alice] = 3

=========================================================
TRACE:
brokenExecution(10)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

globalCounter =
3 + 10

TEMP VALUE:
13

---------------------------------------------------------
STEP 2
---------------------------------------------------------

balances[Alice] =
3 + 10

TEMP VALUE:
13

---------------------------------------------------------
STEP 3
---------------------------------------------------------

require(10 <= 5)

RESULT:
false

---------------------------------------------------------
TRANSACTION REVERTS
---------------------------------------------------------

ALL STATE CHANGES UNDONE.

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

globalCounter = 3

balances[Alice] = 3

---------------------------------------------------------

IMPORTANT:
Temporary values disappear.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
brokenExecution(3)

---------------------------------------------------------

STEP 3:
Call:
globalCounter()

EXPECTED:
3

---------------------------------------------------------

STEP 4:
Call:
balances(your_address)

EXPECTED:
3

---------------------------------------------------------

STEP 5:
Call:
brokenExecution(10)

EXPECTED:
Transaction reverts

---------------------------------------------------------

STEP 6:
Call:
globalCounter()

EXPECTED:
Still 3

---------------------------------------------------------

STEP 7:
Call:
balances(your_address)

EXPECTED:
Still 3

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
- entire transaction succeeds

OR:
- entire transaction reverts

=========================================================
WHAT REVERT DOES
=========================================================

When require() fails:

EVM:
- undoes storage writes
- restores old state
- stops execution
- refunds remaining gas

=========================================================
TEMPORARY EXECUTION STATE
=========================================================

During execution:

Temporary storage updates exist internally.

---------------------------------------------------------

BUT:
They persist ONLY if transaction succeeds.

=========================================================
WHY VALIDATION-FIRST MATTERS
=========================================================

BEST PRACTICE:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

This is:
Checks-Effects-Interactions pattern.

=========================================================
BAD PATTERN
=========================================================

1. update storage
2. validate later

---------------------------------------------------------

Problems:
- wasted gas
- dangerous with external calls
- harder to audit

=========================================================
GAS OBSERVATION
=========================================================

Even reverted transactions:
consume gas.

---------------------------------------------------------

Reason:
Computation already executed.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. TRACE EXECUTION ORDER
---------------------------------------------------------

Auditors inspect:
what changes BEFORE revert points.

---------------------------------------------------------
2. PARTIAL STATE ASSUMPTIONS
---------------------------------------------------------

Partial updates cannot survive revert.

---------------------------------------------------------
3. EXTERNAL CALL DANGER
---------------------------------------------------------

External interactions before revert
may create reentrancy risks.

---------------------------------------------------------
4. CEI PATTERN
---------------------------------------------------------

Checks -> Effects -> Interactions
improves security.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker repeatedly triggers:
expensive computation + revert.

Result:
gas griefing DOS.

---------------------------------------------------------

ANOTHER RISK

Improper external-call ordering
before revert may expose vulnerabilities.

=========================================================
REAL AUDITOR QUESTIONS
=========================================================

Auditors ask:

- What happens before require()?
- Can external calls occur first?
- What reverts?
- What persists?
- Is rollback behavior understood?

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add external token transfer logic
2. Trigger revert after external call
3. Observe rollback behavior carefully

BONUS:
Implement proper CEI ordering.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Ethereum transactions are atomic
- require() failure reverts all state changes
- Temporary updates disappear after revert
- Storage persists only on success
- Validation-first is preferred
- Reverted transactions still consume gas
- CEI pattern improves security
- Execution order matters heavily
- Auditors trace rollback behavior carefully
- Partial state corruption is prevented by EVM atomicity

=========================================================
*/