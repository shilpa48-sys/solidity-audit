// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call multiple state updates
CONCEPT: Order dependency
=========================================================

OBJECTIVE

- Learn how multiple storage updates execute
- Understand order dependency in Solidity
- Learn why update sequence matters
- Understand state consistency risks

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

State updates execute:
line-by-line in exact order.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Changing execution order can:
completely change final state.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Incorrect update ordering causes:

- accounting bugs
- balance corruption
- reentrancy vulnerabilities
- invariant violations

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Order dependency matters in:

- ERC20 transfers
- DeFi lending
- staking systems
- liquidation engines
- AMMs
- vault accounting

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- update sequencing
- external-call ordering
- invariant preservation
- partial state assumptions
- race-condition risks

=========================================================
*/

contract OrderDependencyExample {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
        GLOBAL TOTAL
    */
    uint256 public totalSupply;

    /*
        REWARD TRACKER
    */
    mapping(address => uint256) public rewards;

    /*
    =====================================================
    CORRECT ORDER EXAMPLE
    =====================================================
    */

    function depositCorrect(
        uint256 _amount
    )
        external
    {

        /*
            STEP 1:
            Validate input FIRST.
        */
        require(
            _amount > 0,
            "Invalid amount"
        );

        /*
            STEP 2:
            Update user balance.
        */
        balances[msg.sender] += _amount;

        /*
            STEP 3:
            Update total supply.

            Depends on balance update.
        */
        totalSupply += _amount;

        /*
            STEP 4:
            Reward based on NEW balance.
        */
        rewards[msg.sender] =
            balances[msg.sender] / 10;
    }

    /*
    =====================================================
    BAD ORDER EXAMPLE
    =====================================================
    */

    function depositWrong(
        uint256 _amount
    )
        external
    {

        /*
            STEP 1:
            Reward calculated BEFORE
            balance update.
        */
        rewards[msg.sender] =
            balances[msg.sender] / 10;

        /*
            STEP 2:
            Balance updated later.
        */
        balances[msg.sender] += _amount;

        /*
            STEP 3:
            Total updated.
        */
        totalSupply += _amount;
    }

    /*
    =====================================================
    TRANSFER EXAMPLE
    =====================================================
    */

    function transfer(
        address _to,
        uint256 _amount
    )
        external
    {

        /*
            Validate sender balance FIRST.
        */
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            CORRECT ORDER:
            subtract sender first.
        */
        balances[msg.sender] -= _amount;

        /*
            Then add receiver.
        */
        balances[_to] += _amount;
    }
}
//patched code 
contract OrderDependencyExamplePatched {

    mapping(address => uint256) public balances;
    uint256 public totalSupply;
    mapping(address => uint256) public rewards;

    event Deposit(address indexed user, uint256 amount);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Invalid amount");

        // EFFECTS
        balances[msg.sender] += _amount;
        totalSupply += _amount;

        // Calculate reward using updated balance
        rewards[msg.sender] = balances[msg.sender] / 10;

        emit Deposit(msg.sender, _amount);
    }

    function transfer(
        address _to,
        uint256 _amount
    ) external {

        require(_to != address(0), "Invalid receiver");
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        // CEI pattern
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        emit Transfer(
            msg.sender,
            _to,
            _amount
        );
    }

    function getReward(
        address _user
    )
        external
        view
        returns (uint256)
    {
        return rewards[_user];
    }
}
/* 
Audit Report 
Finding 1
Medium Severity
Incorrect Reward Calculation Due To Order Dependency
Location
function depositWrong(uint256 _amount) external {

    rewards[msg.sender] =
        balances[msg.sender] / 10;

    balances[msg.sender] += _amount;

    totalSupply += _amount;
}
Description

Reward is calculated before updating the user's balance.

The reward uses stale state and therefore does not reflect the latest deposit.

Example

Initial:

balance = 100
reward = 0

Call:

depositWrong(50);

Execution:

reward = 100 / 10 = 10
balance = 150

Expected reward:

150 / 10 = 15

Actual reward:

10
Impact
Incorrect accounting
Inconsistent state
Potential reward distribution errors
Recommendation

Move reward calculation after balance update.

balances[msg.sender] += _amount;

rewards[msg.sender] =
    balances[msg.sender] / 10;
Status

Fixed in patched version.

Finding 2
Low Severity
Missing Input Validation In depositWrong()
Location
function depositWrong(uint256 _amount)
Description

Unlike depositCorrect(), this function does not validate:

_amount > 0

Users can call:

depositWrong(0)

and still execute unnecessary state logic.

Impact
Wasted gas
Inconsistent validation policy
Recommendation
require(_amount > 0, "Invalid amount");
Finding 3
Low Severity
Missing Receiver Address Validation
Location
function transfer(address _to, uint256 _amount)
Description

Transfer allows:

_to == address(0)

which may unintentionally burn balances.

Impact

Potential loss of funds.

Recommendation
require(
    _to != address(0),
    "Invalid receiver"
);
Finding 4
Informational
No Event Emission
Description

State-changing operations are not logged.

Missing events:

Deposit
Transfer
Impact

Poor off-chain monitoring.

Recommendation

Emit events for all critical actions.

Finding 5
Informational
Duplicate Deposit Logic
Description

depositCorrect() and depositWrong() contain nearly identical logic.

Recommendation

Create a shared internal function:

function _deposit(uint256 amount)
    internal
{
    ...
}
Finding 6
Informational
CEI Pattern Awareness
Description

Current transfer() follows:

Checks
Effects
Interactions

which is the recommended Solidity pattern.

Status

No issue identified.

Gas Review
Good
Uses mappings for O(1) lookups.
No loops.
Solidity 0.8 overflow checks provide safety.
Possible Optimization

Cache balance locally if performing multiple reads:

uint256 balance =
    balances[msg.sender];

Not required here.
*/
/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

balances[Alice] = 100

rewards[Alice] = 0

=========================================================
TRACE:
depositCorrect(50)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

require(50 > 0)

RESULT:
true

---------------------------------------------------------
STEP 2
---------------------------------------------------------

balances[Alice] += 50

NEW VALUE:
150

---------------------------------------------------------
STEP 3
---------------------------------------------------------

totalSupply += 50

---------------------------------------------------------
STEP 4
---------------------------------------------------------

rewards[Alice] =
balances[Alice] / 10

150 / 10 = 15

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

balances[Alice] = 150

rewards[Alice] = 15

=========================================================
BAD ORDER TRACE
=========================================================

INITIAL:

balances[Alice] = 100

---------------------------------------------------------

CALL:
depositWrong(50)

---------------------------------------------------------
STEP 1
---------------------------------------------------------

rewards[Alice] =
balances[Alice] / 10

100 / 10 = 10

---------------------------------------------------------
STEP 2
---------------------------------------------------------

balances[Alice] += 50

NEW VALUE:
150

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

balances[Alice] = 150

rewards[Alice] = 10

---------------------------------------------------------

IMPORTANT:
Reward incorrect because
order was wrong.

=========================================================
IMPORTANT EXECUTION UNDERSTANDING
=========================================================

Solidity executes:
TOP -> DOWN

---------------------------------------------------------

Every storage update affects:
future lines immediately.

=========================================================
ORDER DEPENDENCY
=========================================================

Later logic depends on:
earlier state changes.

---------------------------------------------------------

Changing line order may:
change protocol behavior.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
depositCorrect(100)

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
100

---------------------------------------------------------

STEP 4:
Call:
rewards(your_address)

EXPECTED:
10

---------------------------------------------------------

STEP 5:
Deploy fresh contract

---------------------------------------------------------

STEP 6:
Call:
depositWrong(100)

---------------------------------------------------------

STEP 7:
Call:
rewards(your_address)

EXPECTED:
0

---------------------------------------------------------

OBSERVE:
Reward used OLD balance.

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

Incorrect update order can create:

- stale reads
- broken accounting
- exploit opportunities

=========================================================
CHECKS-EFFECTS-INTERACTIONS
=========================================================

BEST PRACTICE:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

Known as:
CEI pattern.

=========================================================
WHY CEI MATTERS
=========================================================

Correct ordering helps prevent:
reentrancy vulnerabilities.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. STALE STATE READS
---------------------------------------------------------

Logic reads old values accidentally.

---------------------------------------------------------
2. EXTERNAL CALL BEFORE UPDATE
---------------------------------------------------------

Major reentrancy risk.

---------------------------------------------------------
3. INVARIANT BREAKAGE
---------------------------------------------------------

Incorrect order corrupts accounting.

---------------------------------------------------------
4. DOUBLE-SPEND RISKS
---------------------------------------------------------

Incorrect balance sequencing dangerous.

=========================================================
GAS OBSERVATION
=========================================================

More state updates:
higher gas usage.

---------------------------------------------------------

Repeated storage reads/writes:
especially expensive.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- What updates happen first?
- Which values depend on prior state?
- Are stale reads possible?
- Are invariants preserved?
- Does execution order prevent exploits?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

External call before balance reduction.

Attacker reenters repeatedly.

Result:
fund theft.

---------------------------------------------------------

ANOTHER RISK

Reward calculated before update.

Attacker gains incorrect rewards.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Exact execution order
2. Storage reads/writes
3. Dependency chains
4. External-call timing
5. Invariant preservation

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add withdraw function
2. Intentionally place external call
   before balance update
3. Observe vulnerability risk
4. Fix using CEI pattern

BONUS:
Track previousBalance and newBalance.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Solidity executes line-by-line
- State updates affect later execution immediately
- Execution order changes final behavior
- Incorrect ordering creates vulnerabilities
- CEI pattern improves security
- Stale reads are dangerous
- External-call ordering is critical
- Auditors trace exact state-update sequence
- Dependency chains matter heavily
- Order dependency is fundamental in smart contracts

=========================================================
*/