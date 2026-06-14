// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Reorder logic intentionally
CONCEPT: Vulnerability creation
=========================================================

OBJECTIVE

- Learn how bad execution order creates vulnerabilities
- Understand dangerous state-update sequencing
- Learn reentrancy-style ordering issues
- Think like a smart contract auditor

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Execution order is SECURITY CRITICAL.

Changing line order may:
- break invariants
- expose reentrancy
- corrupt accounting
- enable fund theft

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Same logic
+
Different order
=
Completely different security outcome.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Many real-world hacks happened because:
logic executed in wrong order.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Ordering mistakes affected:

- DAO hack
- lending protocols
- vault systems
- reward systems
- staking protocols
- AMMs

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- state-update order
- external-call timing
- validation placement
- stale-state reads
- invariant preservation

=========================================================
*/

contract ReorderLogicVulnerability {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
        TOTAL SYSTEM BALANCE
    */
    uint256 public totalBalance;

    /*
    =====================================================
    SAFE DEPOSIT
    =====================================================
    */

    function safeDeposit()
        external
        payable
    {

        /*
            STEP 1:
            Validate FIRST.
        */
        require(
            msg.value > 0,
            "No ETH sent"
        );

        /*
            STEP 2:
            Update user balance.
        */
        balances[msg.sender] += msg.value;

        /*
            STEP 3:
            Update global accounting.
        */
        totalBalance += msg.value;
    }

    /*
    =====================================================
    SAFE WITHDRAW
    =====================================================

    Uses:
    Checks -> Effects -> Interactions
    */

    function safeWithdraw(
        uint256 _amount
    )
        external
    {

        /*
            CHECKS
        */
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            EFFECTS

            Update storage BEFORE external call.
        */
        balances[msg.sender] -= _amount;

        totalBalance -= _amount;

        /*
            INTERACTION

            External ETH transfer LAST.
        */
        payable(msg.sender).transfer(_amount);
    }

    /*
    =====================================================
    VULNERABLE WITHDRAW
    =====================================================

    INTENTIONALLY BAD ORDER
    */

    function vulnerableWithdraw(
        uint256 _amount
    )
        external
    {

        /*
            CHECK:
            User balance validation.
        */
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            DANGEROUS ORDER:

            External call BEFORE state update.
        */
        payable(msg.sender).call{
            value: _amount
        }("");

        /*
            STATE UPDATED TOO LATE
        */
        balances[msg.sender] -= _amount;

        totalBalance -= _amount;
    }

    /*
    =====================================================
    BAD REWARD ORDER
    =====================================================
    */

    mapping(address => uint256) public rewards;

    function badRewardUpdate(
        uint256 _deposit
    )
        external
    {

        /*
            WRONG ORDER:

            Reward calculated BEFORE
            balance update.
        */
        rewards[msg.sender] =
            balances[msg.sender] / 10;

        /*
            Balance updated later.
        */
        balances[msg.sender] += _deposit;
    }

    /*
    =====================================================
    SAFE REWARD ORDER
    =====================================================
    */

    function safeRewardUpdate(
        uint256 _deposit
    )
        external
    {

        /*
            Correct order:
            update balance first.
        */
        balances[msg.sender] += _deposit;

        /*
            Reward uses NEW balance.
        */
        rewards[msg.sender] =
            balances[msg.sender] / 10;
    }
}
//patched code 
contract ReorderLogicPatched {

    mapping(address => uint256) public balances;
    mapping(address => uint256) public rewards;

    uint256 public totalBalance;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    bool private locked;

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    function deposit()
        external
        payable
    {
        require(msg.value > 0, "No ETH sent");

        balances[msg.sender] += msg.value;
        totalBalance += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(
        uint256 amount
    )
        external
        nonReentrant
    {
        require(
            balances[msg.sender] >= amount,
            "Insufficient balance"
        );

        // EFFECTS
        balances[msg.sender] -= amount;
        totalBalance -= amount;

        // INTERACTION
        (bool success, ) =
            payable(msg.sender).call{value: amount}("");

        require(success, "Transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    function updateReward(
        uint256 depositAmount
    )
        external
    {
        balances[msg.sender] += depositAmount;

        rewards[msg.sender] =
            balances[msg.sender] / 10;
    }
}
/* 
Audit Report 
Finding 1
Critical Severity
Reentrancy Vulnerability in vulnerableWithdraw()
Location
payable(msg.sender).call{
    value: _amount
}("");

balances[msg.sender] -= _amount;
totalBalance -= _amount;
Description

The contract performs an external call before updating internal accounting.

This violates CEI:

Checks
Interactions
Effects

instead of:

Checks
Effects
Interactions
Attack Scenario

Attacker deposits ETH.

Attacker calls:

vulnerableWithdraw(1 ether);

During the external call:

receive() external payable {
    victim.vulnerableWithdraw(1 ether);
}

Because balance has not yet been reduced:

balances[attacker]

still contains the original amount.

The attacker can repeatedly re-enter and withdraw multiple times.

Impact
Complete ETH drain possible
Protocol insolvency
Loss of user funds
Recommendation

Update state before external interaction.

balances[msg.sender] -= amount;
totalBalance -= amount;

(bool success,) =
    payable(msg.sender).call{value: amount}("");

require(success);

Add:

nonReentrant

protection.

Status

Fixed in patched version.

Finding 2
Medium Severity
Ignored Return Value From Low-Level Call
Location
payable(msg.sender).call{
    value: _amount
}("");
Description

Low-level calls return:

(bool success, bytes memory data)

The result is ignored.

If transfer fails:

state may still update
accounting becomes inconsistent
Impact
Incorrect bookkeeping
Lost withdrawal attempts
Unexpected user experience
Recommendation
(bool success,) =
    payable(msg.sender).call{value:_amount}("");

require(success, "Transfer failed");
Status

Fixed.

Finding 3
Low Severity
Stale Reward Calculation
Location
rewards[msg.sender] =
    balances[msg.sender] / 10;

balances[msg.sender] += _deposit;
Description

Reward uses the old balance.

Example

Before:

Balance = 100

Call:

badRewardUpdate(50);

Result:

Reward = 10
Balance = 150

Expected:

Reward = 15
Impact

Incorrect reward distribution.

Recommendation
balances[msg.sender] += _deposit;

rewards[msg.sender] =
    balances[msg.sender] / 10;
Status

Fixed.

Finding 4
Low Severity
Missing Events On Critical Actions
Description

No event emitted for:

deposits
withdrawals
Impact

Poor observability for:

frontends
indexers
monitoring bots
Recommendation

Add:

event Deposit(...);
event Withdraw(...);

Emit after successful execution.

Finding 5
Informational
safeWithdraw() Uses CEI Correctly
Observation
require(...);

balances[msg.sender] -= amount;
totalBalance -= amount;

transfer(amount);

This follows industry best practice.

Status
No issue.

Finding 6
Informational
Solidity 0.8 Overflow Protection

Arithmetic operations:

+=
-=

benefit from built-in overflow/underflow checks.

Status

Safe.

Finding 7
Informational
Accounting Invariant

Expected invariant:

totalBalance
=
sum(all user balances)

Auditors should continuously verify this relationship.

Recommended assertion during testing:

assert(totalBalance >= 0);

and fuzz-test accounting consistency.
*/

/*
=========================================================
IMPORTANT SECURITY UNDERSTANDING
=========================================================

BAD ORDER:
interaction before state update

=
classic reentrancy vulnerability.

=========================================================
SAFE WITHDRAW TRACE
=========================================================

CALL:
safeWithdraw(10)

=========================================================

STEP 1:
Balance check.

---------------------------------------------------------

STEP 2:
balances[Alice] -= 10

---------------------------------------------------------

STEP 3:
totalBalance -= 10

---------------------------------------------------------

STEP 4:
ETH transfer occurs LAST.

---------------------------------------------------------

SAFE:
state already updated.

=========================================================
VULNERABLE TRACE
=========================================================

CALL:
vulnerableWithdraw(10)

=========================================================

STEP 1:
Balance validated.

---------------------------------------------------------

STEP 2:
External ETH call occurs FIRST.

---------------------------------------------------------

DANGER:
Attacker contract can reenter NOW.

---------------------------------------------------------

STEP 3:
Balance reduced TOO LATE.

---------------------------------------------------------

ATTACK RESULT:
multiple withdrawals possible.

=========================================================
WHY REORDERING CREATES VULNERABILITIES
=========================================================

Security depends on:
WHEN state changes occur.

---------------------------------------------------------

Incorrect ordering may expose:
temporary inconsistent state.

=========================================================
REWARD BUG TRACE
=========================================================

INITIAL:

balances[Alice] = 100

---------------------------------------------------------

CALL:
badRewardUpdate(50)

---------------------------------------------------------

STEP 1:
Reward calculated.

100 / 10 = 10

---------------------------------------------------------

STEP 2:
Balance updated later.

balances[Alice] = 150

---------------------------------------------------------

FINAL:
Reward stale and incorrect.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
safeRewardUpdate(100)

---------------------------------------------------------

STEP 3:
Call:
rewards(your_address)

EXPECTED:
10

---------------------------------------------------------

STEP 4:
Deploy fresh contract

---------------------------------------------------------

STEP 5:
Call:
badRewardUpdate(100)

---------------------------------------------------------

STEP 6:
Call:
rewards(your_address)

EXPECTED:
0

---------------------------------------------------------

OBSERVE:
Wrong order caused stale calculation.

=========================================================
CRITICAL AUDITOR CONCEPT
=========================================================

Auditors care deeply about:

EXECUTION ORDER

---------------------------------------------------------

Because:
same code + different order
can create exploits.

=========================================================
CHECKS-EFFECTS-INTERACTIONS
=========================================================

SAFE PATTERN:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

Prevents:
many reentrancy attacks.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. EXTERNAL CALL BEFORE STATE UPDATE
---------------------------------------------------------

Classic reentrancy risk.

---------------------------------------------------------
2. STALE STATE READS
---------------------------------------------------------

Logic reads outdated values.

---------------------------------------------------------
3. INVARIANT VIOLATIONS
---------------------------------------------------------

Temporary inconsistent state exposed.

---------------------------------------------------------
4. PARTIAL EXECUTION ASSUMPTIONS
---------------------------------------------------------

Incorrect ordering breaks accounting.

=========================================================
GAS OBSERVATION
=========================================================

Incorrect ordering may:
waste gas during revert paths.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- What executes first?
- When is state updated?
- Are external calls dangerous?
- Can temporary state be abused?
- Are invariants preserved throughout execution?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker deploys malicious contract.

---------------------------------------------------------

During vulnerableWithdraw():

1. receives ETH
2. fallback triggers
3. reenters withdraw()
4. balance still unchanged
5. steals funds repeatedly

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Exact execution order
2. Storage update timing
3. External interaction timing
4. Revert points
5. Reentrancy windows

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add external token transfer
2. Intentionally place it before
   balance reduction
3. Analyze vulnerability
4. Fix using CEI pattern

BONUS:
Implement nonReentrant modifier.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Execution order is security critical
- Reordering logic can create vulnerabilities
- External calls before state updates are dangerous
- CEI pattern prevents many attacks
- Stale reads create incorrect accounting
- Temporary inconsistent state is exploitable
- Reentrancy depends heavily on ordering
- Auditors trace exact execution sequence
- Same logic with different order changes security
- Order dependency is fundamental to smart contract auditing

=========================================================
*/