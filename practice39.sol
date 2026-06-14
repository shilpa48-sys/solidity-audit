// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Use multiple require checks
CONCEPT: Execution guards
=========================================================

OBJECTIVE

- Learn how multiple require() checks work
- Understand execution guards in Solidity
- Learn defensive validation patterns
- Understand fail-fast security design

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

require() acts as an execution guard.

If ANY require() fails:
- execution stops
- transaction reverts
- state changes rollback

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Multiple require() checks create:
layered protection.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Smart contracts must validate:
- caller
- values
- balances
- permissions
- timing
- protocol rules

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Multiple require() checks used in:

- ERC20 transfers
- staking contracts
- governance systems
- lending protocols
- NFT minting
- DEX routers

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- missing validations
- incorrect validation order
- bypass possibilities
- access control flaws
- logic assumptions

=========================================================
*/

contract MultipleRequireChecks {

    /*
        OWNER ADDRESS

        Set during deployment.
    */
    address public owner;

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
        MAX LIMIT
    */
    uint256 public constant MAX_DEPOSIT = 100 ether;

    /*
        CONSTRUCTOR

        Runs once during deployment.
    */
    constructor() {

        owner = msg.sender;
    }

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
            REQUIRE #1

            Amount must be positive.
        */
        require(
            _amount > 0,
            "Amount must be > 0"
        );

        /*
            REQUIRE #2

            Amount must not exceed max limit.
        */
        require(
            _amount <= MAX_DEPOSIT,
            "Deposit too large"
        );

        /*
            REQUIRE #3

            Prevent overflow-like balance growth.
        */
        require(
            balances[msg.sender] + _amount
                <= 1000 ether,
            "Balance limit exceeded"
        );

        /*
            EXECUTION REACHES HERE
            ONLY IF ALL CHECKS PASS.
        */
        balances[msg.sender] += _amount;
    }

    /*
    =====================================================
    OWNER-ONLY RESET
    =====================================================
    */

    function resetBalance(
        address _user
    )
        external
    {

        /*
            REQUIRE #1

            Access control.
        */
        require(
            msg.sender == owner,
            "Not owner"
        );

        /*
            REQUIRE #2

            Reject zero address.
        */
        require(
            _user != address(0),
            "Invalid address"
        );

        /*
            REQUIRE #3

            User must have balance.
        */
        require(
            balances[_user] > 0,
            "No balance"
        );

        /*
            RESET USER BALANCE
        */
        balances[_user] = 0;
    }
}
//patched code
contract MultipleRequireChecksPatched {

    error NotOwner();
    error ContractPaused();
    error Blacklisted();
    error InvalidAmount();
    error DepositTooLarge();
    error BalanceLimitExceeded();
    error InsufficientBalance();

    address public owner;

    bool public paused;

    mapping(address => bool) public blacklist;

    mapping(address => uint256) public balances;

    uint256 public constant MAX_DEPOSIT = 100 ether;

    constructor() {
        owner = msg.sender;
    }

    function deposit(uint256 _amount) external {

        if (_amount == 0)
            revert InvalidAmount();

        if (_amount > MAX_DEPOSIT)
            revert DepositTooLarge();

        if (
            balances[msg.sender] + _amount >
            1000 ether
        )
            revert BalanceLimitExceeded();

        balances[msg.sender] += _amount;
    }

    function withdraw(uint256 _amount) external {

        // REQUIRE #1
        if (paused)
            revert ContractPaused();

        // REQUIRE #2
        if (blacklist[msg.sender])
            revert Blacklisted();

        // REQUIRE #3
        if (_amount == 0)
            revert InvalidAmount();

        // REQUIRE #4
        if (balances[msg.sender] < _amount)
            revert InsufficientBalance();

        balances[msg.sender] -= _amount;
    }

    function setPaused(bool _status)
        external
    {
        if (msg.sender != owner)
            revert NotOwner();

        paused = _status;
    }

    function setBlacklist(
        address _user,
        bool _status
    )
        external
    {
        if (msg.sender != owner)
            revert NotOwner();

        blacklist[_user] = _status;
    }

    function resetBalance(
        address _user
    )
        external
    {
        if (msg.sender != owner)
            revert NotOwner();

        balances[_user] = 0;
    }
}
/*
Report
Title:

Missing Pause and Blacklist Validation in Withdraw Function

Severity:

Low

Reason:

The original contract implements multiple layered require() checks for deposits and balance resets, but the Mini Challenge requirements introduce a withdraw() function that should include additional execution guards:

Pause status validation
Balance sufficiency validation
Blacklist validation

Without these checks, withdrawals may execute when protocol operations should be restricted, violating intended business rules.

Location:

Contract: MultipleRequireChecksPatched
Function: withdraw()

Vulnerability Description:

The challenge requires a withdrawal mechanism protected by multiple execution guards.

If a withdrawal function is implemented without:

pause checks,
blacklist checks,
balance validation,

users may continue interacting with the protocol despite administrative restrictions.

This creates inconsistency between protocol rules and actual execution behavior.

Impact:

Potential consequences include:

Withdrawals during emergency pause
Blacklisted users accessing funds
Invalid balance accounting
Broken protocol restrictions

Because balance manipulation is involved, missing validation may result in unauthorized operations.

Proof of Concept:
Scenario 1 – Missing Pause Check
Owner pauses protocol
User calls withdraw(10)
Withdrawal succeeds

Expected:
Transaction should revert.

Scenario 2 – Missing Blacklist Check
Owner blacklists Bob
Bob calls withdraw(5)
Withdrawal succeeds

Expected:
Transaction should revert.

Scenario 3 – Missing Balance Check
User balance = 5
User calls withdraw(100)
Arithmetic underflow or incorrect accounting occurs

Expected:
Transaction should revert.

Root Cause:

Missing defensive validation guards before balance modification.

Example vulnerable pattern:

function withdraw(uint256 _amount) external {
    balances[msg.sender] -= _amount;
}

Issues:

No pause validation
No blacklist validation
No balance validation
Recommendation:

Implement layered execution guards before state updates.

Recommended order:

Pause check
Blacklist check
Amount validation
Balance validation
State update

Using custom errors further reduces gas costs.
Patched Code Explanation:

The patched contract adds the Mini Challenge requirements:

Added withdraw() function
Added pause protection
Added blacklist protection
Added balance validation
Replaced require() strings with custom errors
Preserved the original layered-validation teaching style
Demonstrates fail-fast execution guards that auditors expect to see in production Solidity contracts

This implementation satisfies the challenge while remaining very similar to the original educational example.

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
deposit(10)

=========================================================

STEP 1:
require(10 > 0)

RESULT:
true

---------------------------------------------------------

STEP 2:
require(10 <= MAX_DEPOSIT)

RESULT:
true

---------------------------------------------------------

STEP 3:
Balance limit check

RESULT:
true

---------------------------------------------------------

ALL CHECKS PASSED

---------------------------------------------------------

STORAGE UPDATE:

balances[msg.sender] += 10

=========================================================
FAILURE TRACE
=========================================================

CALL:
deposit(0)

---------------------------------------------------------

STEP 1:
require(0 > 0)

RESULT:
false

---------------------------------------------------------

TRANSACTION REVERTS IMMEDIATELY

---------------------------------------------------------

IMPORTANT:
Other require() checks never execute.

=========================================================
ANOTHER FAILURE TRACE
=========================================================

CALL:
resetBalance(user)

BY:
non-owner

---------------------------------------------------------

STEP 1:
require(msg.sender == owner)

RESULT:
false

---------------------------------------------------------

EXECUTION STOPS IMMEDIATELY

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
deposit(10)

EXPECTED:
Success

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
10

---------------------------------------------------------

STEP 4:
Call:
deposit(0)

EXPECTED:
Revert

---------------------------------------------------------

STEP 5:
Call:
deposit(500 ether)

EXPECTED:
Revert

---------------------------------------------------------

STEP 6:
Switch account in Remix

---------------------------------------------------------

STEP 7:
Call:
resetBalance(your_address)

EXPECTED:
Revert (not owner)

=========================================================
IMPORTANT REQUIRE UNDERSTANDING
=========================================================

require() acts as:
EXECUTION GUARD.

---------------------------------------------------------

If condition fails:
- execution stops
- revert triggered
- state rolled back

=========================================================
FAIL-FAST PRINCIPLE
=========================================================

Solidity follows:
FAIL FAST design.

---------------------------------------------------------

Bad input:
Stop immediately.

=========================================================
ORDER OF REQUIRE CHECKS
=========================================================

BEST PRACTICE:

1. Cheapest checks first
2. Expensive checks later

---------------------------------------------------------

Reason:
Save gas on early failure.

=========================================================
GOOD VALIDATION ORDER
=========================================================

GOOD:

1. msg.sender checks
2. zero-address checks
3. value checks
4. expensive loops/calls

=========================================================
BAD VALIDATION ORDER
=========================================================

BAD:

1. expensive computation
2. external calls
3. validation later

---------------------------------------------------------

Problem:
Wasted gas and risk.

=========================================================
GAS OBSERVATION
=========================================================

FAILED REQUIRE:
Still consumes gas.

---------------------------------------------------------

Earlier failure:
Usually cheaper.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MISSING REQUIRE CHECKS
---------------------------------------------------------

Very common vulnerability source.

---------------------------------------------------------
2. INCORRECT ACCESS CONTROL
---------------------------------------------------------

Missing owner checks
can destroy protocols.

---------------------------------------------------------
3. VALIDATION ORDER
---------------------------------------------------------

Cheap checks should happen first.

---------------------------------------------------------
4. DEFENSE IN DEPTH
---------------------------------------------------------

Multiple require() checks
create layered security.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Missing require() allows:
- unauthorized access
- invalid balances
- protocol corruption

---------------------------------------------------------

ANOTHER RISK

Incorrect ordering may:
waste gas or expose reentrancy.

=========================================================
REAL AUDITOR QUESTIONS
=========================================================

Auditors ask:

- What assumptions exist?
- Are all assumptions validated?
- Can attacker bypass checks?
- Is access control enforced?
- Are limits bounded safely?

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add withdraw() function
2. Add:
   - pause check
   - balance check
   - owner blacklist check

BONUS:
Replace require strings
with custom errors.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- require() creates execution guards
- Failed require() reverts transaction
- Multiple require() checks add layered protection
- Validation order matters
- Cheap checks should execute first
- Fail-fast principle improves safety
- Missing checks create vulnerabilities
- Access control is critical
- Auditors inspect validation carefully
- Defense-in-depth improves smart contract security

=========================================================
*/