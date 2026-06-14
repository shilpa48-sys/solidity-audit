// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Use modifier before function
CONCEPT: Pre-execution flow
=========================================================

OBJECTIVE

- Learn how modifiers work
- Understand pre-execution flow
- Learn execution wrapping behavior
- Understand access-control architecture

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Modifiers execute:
BEFORE function body.

They act like:
execution guards/wrappers.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Modifiers can:
- validate conditions
- block execution
- run code before function
- run code after function

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most production contracts use modifiers for:

- access control
- pause logic
- validation
- reentrancy protection
- execution restrictions

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Modifiers used in:

- Ownable contracts
- Pausable contracts
- ReentrancyGuard
- DeFi protocols
- governance systems
- staking platforms

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- modifier execution order
- missing modifiers
- bypass possibilities
- modifier side effects
- access-control flaws

=========================================================
*/

contract ModifierExecutionFlow {

    /*
        OWNER ADDRESS
    */
    address public owner;

    /*
        PAUSE STATUS
    */
    bool public paused;

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
        CONSTRUCTOR

        Runs once during deployment.
    */
    constructor() {

        owner = msg.sender;
    }

    /*
    =====================================================
    MODIFIER: ONLY OWNER
    =====================================================
    */

    modifier onlyOwner() {

        /*
            PRE-EXECUTION CHECK

            Runs BEFORE function body.
        */
        require(
            msg.sender == owner,
            "Not owner"
        );

        /*
            SPECIAL SYMBOL: _;

            Represents:
            function body execution point.
        */
        _;
    }

    /*
    =====================================================
    MODIFIER: WHEN NOT PAUSED
    =====================================================
    */

    modifier whenNotPaused() {

        /*
            PRE-EXECUTION VALIDATION
        */
        require(
            paused == false,
            "Contract paused"
        );

        /*
            Continue to function body.
        */
        _;
    }

    /*
    =====================================================
    OWNER-ONLY FUNCTION
    =====================================================
    */

    function setPaused(
        bool _status
    )
        external
        onlyOwner
    {

        /*
            Function body executes ONLY
            after modifier passes.
        */
        paused = _status;
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
        whenNotPaused
    {

        /*
            Function body executes ONLY
            if modifier allows execution.
        */
        require(
            _amount > 0,
            "Invalid amount"
        );

        balances[msg.sender] += _amount;
    }

    /*
    =====================================================
    MULTIPLE MODIFIERS
    =====================================================
    */

    function emergencyReset(
        address _user
    )
        external
        onlyOwner
        whenNotPaused
    {

        /*
            Executes ONLY if:
            - caller is owner
            - contract not paused
        */
        balances[_user] = 0;
    }
}
//patched code
contract ModifierExecutionFlowPatched {

    address public owner;

    bool public paused;

    uint256 public constant MAX_TX = 100;

    uint256 public constant EXECUTION_FEE = 1;

    mapping(address => uint256) public balances;

    mapping(address => bool) public blacklisted;

    mapping(address => uint256) public executionFees;

    event ActionExecuted(
        address indexed user,
        string action,
        uint256 timestamp
    );

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

    modifier whenNotPaused() {
        require(
            !paused,
            "Contract paused"
        );
        _;
    }

    modifier notBlacklisted() {
        require(
            !blacklisted[msg.sender],
            "Blacklisted"
        );
        _;
    }

    modifier withinLimit(
        uint256 _amount
    ) {
        require(
            _amount <= MAX_TX,
            "Transaction limit exceeded"
        );
        _;
    }

    modifier chargeFee() {

        executionFees[msg.sender] +=
            EXECUTION_FEE;

        _;
    }

    modifier logExecution(
        string memory action
    ) {
        _;

        emit ActionExecuted(
            msg.sender,
            action,
            block.timestamp
        );
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

    function deposit(
        uint256 _amount
    )
        external
        whenNotPaused
        notBlacklisted
        withinLimit(_amount)
        chargeFee
        logExecution("Deposit")
    {
        require(
            _amount > 0,
            "Invalid amount"
        );

        balances[msg.sender] += _amount;
    }

    function emergencyReset(
        address _user
    )
        external
        onlyOwner
        whenNotPaused
        logExecution("Reset")
    {
        balances[_user] = 0;
    }
}
/*
Audit Report
Title

Incomplete Modifier-Based Access Control and Execution Monitoring

Severity

Low

Reason

The contract correctly demonstrates modifier execution flow using onlyOwner and whenNotPaused, but it does not implement the additional protections requested in the mini challenge:

No blacklist modifier
No transaction-limit modifier
No post-execution event emission
No execution fee modifier

This is an educational completeness issue rather than a direct exploitable vulnerability.

Location

Contract: ModifierExecutionFlow

Affected Functions:

deposit()
emergencyReset()

Missing Components:

notBlacklisted modifier
withinLimit modifier
Event emission modifier
Execution fee modifier
Vulnerability Description

The contract relies on two modifiers:

onlyOwner
whenNotPaused

While these provide access control and pause protection, they do not demonstrate:

User blacklisting
Deposit size restrictions
Post-execution logic
Fee charging behavior

As a result, important modifier patterns commonly audited in production systems are absent.

Impact

Potential real-world consequences:

Blacklisted users may continue interacting
Large transactions may bypass business limits
Critical actions may not be logged
Fee collection logic may be duplicated
Root Cause

The contract only demonstrates pre-execution modifiers.

Missing:

notBlacklisted
withinLimit
emitAfterExecution
chargeFee

Therefore execution wrapping behavior is only partially illustrated.

Recommendation

Implement additional modifiers to demonstrate:

Blacklist Protection
modifier notBlacklisted() {
    require(
        !blacklisted[msg.sender],
        "Blacklisted"
    );
    _;
}
Transaction Limit Enforcement
modifier withinLimit(
    uint256 _amount
) {
    require(
        _amount <= MAX_TX,
        "Limit exceeded"
    );
    _;
}
Post-Execution Event Modifier
modifier logExecution() {
    _;
    emit ActionExecuted(
        msg.sender,
        block.timestamp
    );
}
Fee Charging Modifier
modifier chargeFee() {
    executionFees[msg.sender] += FEE;
    _;
}
Conclusion

The original contract is functionally correct and demonstrates basic modifier behavior. 
However, it does not fully implement the mini challenge requirements.

The patched version adds:

Blacklist modifier
Transaction-limit modifier
Post-execution event modifier
Execution-fee modifier
Complete modifier execution tracing

making it a stronger example of real-world Solidity modifier architecture and auditor-focused security review.
*/
/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
deposit(50)

=========================================================

STEP 1:
Modifier executes FIRST:

whenNotPaused

---------------------------------------------------------

CHECK:
paused == false

RESULT:
true

---------------------------------------------------------

STEP 2:
_; reached inside modifier.

Execution enters function body.

---------------------------------------------------------

STEP 3:
Function body executes.

require(_amount > 0)

---------------------------------------------------------

STEP 4:
Storage updated.

balances[Alice] += 50

=========================================================
FAILED MODIFIER TRACE
=========================================================

SET:
paused = true

---------------------------------------------------------

CALL:
deposit(50)

---------------------------------------------------------

STEP 1:
Modifier executes FIRST.

CHECK:
paused == false

RESULT:
false

---------------------------------------------------------

TRANSACTION REVERTS

---------------------------------------------------------

FUNCTION BODY NEVER EXECUTES

=========================================================
OWNER MODIFIER TRACE
=========================================================

CALL:
setPaused(true)

FROM:
non-owner account

---------------------------------------------------------

STEP 1:
onlyOwner modifier executes.

CHECK:
msg.sender == owner

RESULT:
false

---------------------------------------------------------

TRANSACTION REVERTS

---------------------------------------------------------

Function body skipped completely.

=========================================================
MULTIPLE MODIFIER FLOW
=========================================================

CALL:
emergencyReset(user)

=========================================================

EXECUTION ORDER:

1. onlyOwner modifier
2. whenNotPaused modifier
3. function body

---------------------------------------------------------

If ANY modifier fails:
execution stops immediately.

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
setPaused(true)

FROM:
owner account

---------------------------------------------------------

STEP 5:
Call:
deposit(10)

EXPECTED:
Revert

---------------------------------------------------------

STEP 6:
Switch Remix account

---------------------------------------------------------

STEP 7:
Call:
setPaused(false)

FROM:
non-owner account

EXPECTED:
Revert

=========================================================
IMPORTANT MODIFIER UNDERSTANDING
=========================================================

Modifier code executes:
AROUND function body.

---------------------------------------------------------

BEFORE _; :
pre-execution logic

---------------------------------------------------------

AFTER _; :
post-execution logic

=========================================================
VERY IMPORTANT SYMBOL
=========================================================

_;

means:

"Insert function body here"

=========================================================
MODIFIER EXECUTION MODEL
=========================================================

modifier check()
{
    require(...);

    _;

    additional logic
}

---------------------------------------------------------

FLOW:

1. require()
2. function body
3. additional logic

=========================================================
COMMON MODIFIER USE CASES
=========================================================

- onlyOwner
- whenNotPaused
- nonReentrant
- onlyAdmin
- onlyValidator

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. MISSING MODIFIER
---------------------------------------------------------

Critical function lacks protection.

---------------------------------------------------------
2. INCORRECT MODIFIER ORDER
---------------------------------------------------------

Execution order may matter.

---------------------------------------------------------
3. SIDE EFFECTS INSIDE MODIFIER
---------------------------------------------------------

Modifiers may unexpectedly:
modify storage.

---------------------------------------------------------
4. ACCESS CONTROL BUGS
---------------------------------------------------------

Improper owner checks
can expose protocol.

=========================================================
GAS OBSERVATION
=========================================================

More modifiers:
More execution cost.

---------------------------------------------------------

Complex modifiers:
increase audit complexity.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Which functions use modifiers?
- Which functions forgot modifiers?
- What executes before _; ?
- Can modifiers be bypassed?
- Do modifiers mutate state?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Developer forgets:
onlyOwner modifier.

Attacker gains admin access.

---------------------------------------------------------

ANOTHER RISK

Modifier updates storage unexpectedly.

Result:
hidden side effects.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Modifier execution order
2. Pre-execution checks
3. Function body flow
4. Post-execution logic
5. Access-control coverage

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add blacklist modifier
2. Add transaction-limit modifier
3. Add post-execution event emission

BONUS:
Create custom modifier:
that charges execution fee.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Modifiers execute before function body
- _; represents function execution point
- Modifiers act as execution guards
- Modifiers commonly enforce access control
- Multiple modifiers execute sequentially
- Failed modifier stops execution
- Modifiers can contain pre/post logic
- Missing modifiers create vulnerabilities
- Auditors inspect modifier coverage carefully
- Modifier execution flow is critical for security

=========================================================
*/