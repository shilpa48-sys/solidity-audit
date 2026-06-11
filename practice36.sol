// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Execute function line-by-line manually
CONCEPT: Mental execution tracing
=========================================================

OBJECTIVE

- Learn how to mentally execute Solidity code
- Understand EVM execution flow
- Learn state changes step-by-step
- Build auditor-style tracing skills

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Professional auditors mentally trace:

- every variable change
- every storage update
- every require()
- every loop iteration
- every external call

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Auditing is NOT only reading syntax.

You must simulate execution in your head.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most vulnerabilities are found by:

- tracing state changes
- understanding execution order
- detecting unexpected behavior

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Mental execution tracing is critical for:

- smart contract auditing
- exploit analysis
- protocol reviews
- gas optimization
- invariant checking

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors mentally track:

- msg.sender
- msg.value
- storage changes
- memory usage
- require conditions
- external interactions
- reentrancy possibilities

=========================================================
*/

contract MentalExecutionTracing {

    /*
        STORAGE VARIABLES

        Persist permanently on blockchain.
    */
    uint256 public totalBalance;

    mapping(address => uint256) public balances;

    /*
    =====================================================
    DEPOSIT FUNCTION
    =====================================================
    */

    function deposit(
        uint256 _amount
    )
        external
    {

        /*
            STEP 1:
            Validate amount.
        */
        require(
            _amount > 0,
            "Invalid amount"
        );

        /*
            STEP 2:
            Read current balance from storage.

            balances[msg.sender]
            initially may be 0.
        */
        uint256 currentBalance =
            balances[msg.sender];

        /*
            STEP 3:
            Add deposit amount.
        */
        uint256 newBalance =
            currentBalance + _amount;

        /*
            STEP 4:
            Update storage mapping.
        */
        balances[msg.sender] =
            newBalance;

        /*
            STEP 5:
            Update total system balance.
        */
        totalBalance =
            totalBalance + _amount;
    }

    /*
    =====================================================
    WITHDRAW FUNCTION
    =====================================================
    */

    function withdraw(
        uint256 _amount
    )
        external
    {

        /*
            STEP 1:
            Read user balance from storage.
        */
        uint256 userBalance =
            balances[msg.sender];

        /*
            STEP 2:
            Ensure enough balance exists.
        */
        require(
            userBalance >= _amount,
            "Insufficient balance"
        );

        /*
            STEP 3:
            Subtract withdrawal amount.
        */
        uint256 updatedBalance =
            userBalance - _amount;

        /*
            STEP 4:
            Save updated balance.
        */
        balances[msg.sender] =
            updatedBalance;

        /*
            STEP 5:
            Reduce total system balance.
        */
        totalBalance =
            totalBalance - _amount;
    }
}
//patched code
contract MentalExecutionTracingPatched {

    uint256 public totalBalance;

    mapping(address => uint256) public balances;

    function deposit(
        uint256 _amount
    )
        external
    {
        require(
            _amount > 0,
            "Invalid amount"
        );

        uint256 currentBalance =
            balances[msg.sender];

        uint256 newBalance =
            currentBalance + _amount;

        balances[msg.sender] =
            newBalance;

        totalBalance =
            totalBalance + _amount;
    }

    function withdraw(
        uint256 _amount
    )
        external
    {
        uint256 userBalance =
            balances[msg.sender];

        require(
            userBalance >= _amount,
            "Insufficient balance"
        );

        uint256 updatedBalance =
            userBalance - _amount;

        balances[msg.sender] =
            updatedBalance;

        totalBalance =
            totalBalance - _amount;
    }

    /*
    =====================================================
    PATCHED TRANSFER FUNCTION
    =====================================================
    */

    function transfer(
        address _receiver,
        uint256 _amount
    )
        external
    {
        require(
            _receiver != address(0),
            "Invalid receiver"
        );

        uint256 senderBalance =
            balances[msg.sender];

        require(
            senderBalance >= _amount,
            "Insufficient balance"
        );

        balances[msg.sender] =
            senderBalance - _amount;

        balances[_receiver] =
            balances[_receiver] + _amount;

        /*
            totalBalance unchanged
            because funds stay inside system
        */
    }
}

/*
Audit Report
Title:

Missing Internal Transfer Function Limits State Transition Testing

Severity:

Informational

Reason:

The contract demonstrates deposits and withdrawals but lacks an internal transfer mechanism.

Because of this, developers and learners cannot practice tracing balance movements between multiple accounts, which is a critical auditing skill.

Location:

Contract: MentalExecutionTracing

Missing functionality between:

deposit()
withdraw()
Vulnerability Description:

The contract focuses on storage updates and manual execution tracing.

However, it only demonstrates:

balance increases
balance decreases

It does not demonstrate:

sender balance reduction
receiver balance increase
multi-account state transitions

As a result, students may not gain experience tracing more realistic accounting flows commonly found in production protocols.

Impact:

No direct security vulnerability exists.

However:

execution-tracing education is incomplete
balance movement between users cannot be tested
auditors cannot practice multi-user state analysis
Proof of Concept
Initial State
totalBalance = 0

Alice = 0
Bob = 0
Step 1

Alice calls:

deposit(500)

State:

Alice = 500
Bob = 0

totalBalance = 500
Step 2

Alice calls:

transfer(Bob, 200)

State:

Alice = 300
Bob = 200

totalBalance = 500
Step 3

Bob calls:

withdraw(50)

State:

Alice = 300
Bob = 150

totalBalance = 450
Observation

The transfer operation changes balances between users while preserving the system invariant:

Sum of user balances = totalBalance
Root Cause

The educational contract only demonstrates:

deposit()
withdraw()

and omits a balance transfer workflow.

Recommendation

Add a transfer function with:

require(
    _receiver != address(0),
    "Invalid receiver"
);

and

require(
    balances[msg.sender] >= _amount,
    "Insufficient balance"
);

before updating balances.

Patched Code

The patched contract introduces a transfer() function that:

validates receiver address
validates sender balance
debits sender
credits receiver
preserves total system balance

This enables realistic state-transition tracing and improves auditor training by demonstrating multi-user accounting behavior.
/*

/*
=========================================================
MANUAL EXECUTION TRACE
=========================================================

---------------------------------------------------------
INITIAL STATE
---------------------------------------------------------

totalBalance = 0

balances[Alice] = 0

=========================================================
TRACE:
deposit(100)
called by Alice
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

require(_amount > 0)

CHECK:
100 > 0

RESULT:
true

Execution continues.

---------------------------------------------------------
STEP 2
---------------------------------------------------------

currentBalance =
balances[Alice]

READ STORAGE:

balances[Alice] = 0

SO:

currentBalance = 0

---------------------------------------------------------
STEP 3
---------------------------------------------------------

newBalance =
currentBalance + _amount

= 0 + 100

= 100

---------------------------------------------------------
STEP 4
---------------------------------------------------------

balances[Alice] = newBalance

STORAGE UPDATE:

balances[Alice] = 100

---------------------------------------------------------
STEP 5
---------------------------------------------------------

totalBalance =
totalBalance + _amount

= 0 + 100

= 100

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

balances[Alice] = 100

totalBalance = 100

=========================================================
SECOND TRACE
=========================================================

CALL:
withdraw(40)

by Alice

---------------------------------------------------------
STEP 1
---------------------------------------------------------

userBalance =
balances[Alice]

READ STORAGE:

balances[Alice] = 100

---------------------------------------------------------
STEP 2
---------------------------------------------------------

require(userBalance >= _amount)

CHECK:
100 >= 40

RESULT:
true

---------------------------------------------------------
STEP 3
---------------------------------------------------------

updatedBalance =
100 - 40

= 60

---------------------------------------------------------
STEP 4
---------------------------------------------------------

balances[Alice] = 60

STORAGE UPDATED

---------------------------------------------------------
STEP 5
---------------------------------------------------------

totalBalance =
100 - 40

= 60

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

balances[Alice] = 60

totalBalance = 60

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
deposit(100)

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
100

---------------------------------------------------------

STEP 4:
Call:
totalBalance()

EXPECTED:
100

---------------------------------------------------------

STEP 5:
Call:
withdraw(40)

---------------------------------------------------------

STEP 6:
Call:
balances(your_address)

EXPECTED:
60

---------------------------------------------------------

STEP 7:
Call:
totalBalance()

EXPECTED:
60

=========================================================
FAILURE TRACE
=========================================================

CALL:
withdraw(1000)

WHEN:
balance = 60

---------------------------------------------------------
STEP 1
---------------------------------------------------------

userBalance = 60

---------------------------------------------------------
STEP 2
---------------------------------------------------------

CHECK:
60 >= 1000

RESULT:
false

---------------------------------------------------------
TRANSACTION REVERTS
---------------------------------------------------------

NO STATE CHANGES OCCUR.

=========================================================
IMPORTANT AUDITOR SKILL
=========================================================

WHILE TRACING:

Track:

- storage reads
- storage writes
- memory variables
- require conditions
- execution order
- state before/after

=========================================================
WHY EXECUTION ORDER MATTERS
=========================================================

Incorrect order may cause:

- reentrancy
- stale state
- accounting bugs
- invariant violations

=========================================================
MENTAL MODEL USED BY AUDITORS
=========================================================

FOR EVERY LINE ASK:

1. What data is read?
2. From storage/memory/calldata?
3. What changes?
4. Can execution revert?
5. What happens if attacker controls input?
6. What is final state?

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. TRACE STATE CAREFULLY
---------------------------------------------------------

Most bugs hide in:
state transitions.

---------------------------------------------------------
2. WATCH STORAGE WRITES
---------------------------------------------------------

Storage changes are critical.

---------------------------------------------------------
3. CHECK REQUIRE ORDER
---------------------------------------------------------

Validation must happen before:
dangerous operations.

---------------------------------------------------------
4. THINK LIKE ATTACKER
---------------------------------------------------------

Ask:
"What if input is malicious?"

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

If require() were missing:

Attacker could:
withdraw more than balance.

---------------------------------------------------------

ANOTHER RISK

Incorrect execution order may:
enable reentrancy exploits.

=========================================================
MINI CHALLENGE
=========================================================

Manually trace:

1. deposit(500)
2. withdraw(200)
3. deposit(50)

Write:
- every variable value
- every storage update
- final contract state

BONUS:
Add transfer() function
and trace sender + receiver balances.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Auditors mentally execute code
- Storage changes must be tracked carefully
- require() controls execution flow
- Reverts undo state changes
- Execution order matters heavily
- State tracing reveals vulnerabilities
- External input is attacker-controlled
- Storage/memory/calldata differ greatly
- Manual tracing is essential for auditing
- Professional auditors simulate EVM execution mentally

=========================================================
*/