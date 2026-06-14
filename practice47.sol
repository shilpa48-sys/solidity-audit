// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Emit events during execution
CONCEPT: Execution tracking
=========================================================

OBJECTIVE

- Learn how Solidity events work
- Understand execution tracking through logs
- Learn event emission flow
- Understand off-chain monitoring architecture

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Events create blockchain logs.

These logs help:
- frontend apps
- indexers
- explorers
- monitoring systems

track contract activity.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Events are NOT contract storage.

They are stored inside:
transaction logs.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Without events:
off-chain systems cannot efficiently
track contract activity.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Events used in:

- ERC20 transfers
- NFT minting
- swaps
- staking
- governance voting
- liquidations

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- missing events
- incorrect event ordering
- misleading logs
- sensitive-data leakage
- inconsistent state vs event emission

=========================================================
*/

contract EventExecutionTracking {

    /*
        STORAGE VARIABLES
    */
    mapping(address => uint256) public balances;

    uint256 public totalDeposits;

    /*
    =====================================================
    EVENT DEFINITIONS
    =====================================================

    Events create blockchain logs.
    */

    event DepositStarted(
        address indexed user,
        uint256 amount
    );

    event BalanceUpdated(
        address indexed user,
        uint256 newBalance
    );

    event DepositCompleted(
        address indexed user,
        uint256 amount,
        uint256 totalDeposits
    );

    event ExecutionFailed(
        address indexed user,
        string reason
    );

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
            Emit execution-start event.
        */
        emit DepositStarted(
            msg.sender,
            _amount
        );

        /*
            STEP 2:
            Validate input.
        */
        require(
            _amount > 0,
            "Amount must be > 0"
        );

        require(
            _amount <= 100,
            "Amount too large"
        );

        /*
            STEP 3:
            Update storage.
        */
        balances[msg.sender] += _amount;

        /*
            STEP 4:
            Emit balance-update event.
        */
        emit BalanceUpdated(
            msg.sender,
            balances[msg.sender]
        );

        /*
            STEP 5:
            Update global storage.
        */
        totalDeposits += _amount;

        /*
            STEP 6:
            Emit completion event.
        */
        emit DepositCompleted(
            msg.sender,
            _amount,
            totalDeposits
        );
    }

    /*
    =====================================================
    MANUAL FAILURE TRACKING
    =====================================================
    */

    function validateNumber(
        uint256 _number
    )
        external
    {

        /*
            Emit failure event before revert.
        */
        if (_number > 10) {

            emit ExecutionFailed(
                msg.sender,
                "Number too large"
            );

            revert("Validation failed");
        }
    }
}
//patched code 
contract EventExecutionTrackingPatched {

    mapping(address => uint256) public balances;
    uint256 public totalDeposits;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // =====================================================
    // EVENTS
    // =====================================================

    event DepositStarted(
        address indexed user,
        uint256 amount
    );

    event DepositCompleted(
        address indexed user,
        uint256 amount,
        uint256 totalDeposits
    );

    event BalanceUpdated(
        address indexed user,
        uint256 newBalance
    );

    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 remainingBalance
    );

    event AdminAction(
        address indexed admin,
        string action
    );

    event TokenTracked(
        address indexed user,
        uint256 indexed tokenId
    );

    // ERC20-style transfer event
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    error InvalidAmount();
    error AmountTooLarge();
    error InsufficientBalance();
    error NotOwner();

    // =====================================================
    // MODIFIER
    // =====================================================

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }

        _;

        emit AdminAction(
            msg.sender,
            "Owner function executed"
        );
    }

    // =====================================================
    // DEPOSIT
    // =====================================================

    function deposit(
        uint256 _amount
    )
        external
    {
        emit DepositStarted(
            msg.sender,
            _amount
        );

        if (_amount == 0) {
            revert InvalidAmount();
        }

        if (_amount > 100) {
            revert AmountTooLarge();
        }

        balances[msg.sender] += _amount;

        emit BalanceUpdated(
            msg.sender,
            balances[msg.sender]
        );

        totalDeposits += _amount;

        emit DepositCompleted(
            msg.sender,
            _amount,
            totalDeposits
        );
    }

    // =====================================================
    // WITHDRAW
    // =====================================================

    function withdraw(
        uint256 _amount
    )
        external
    {
        if (balances[msg.sender] < _amount) {
            revert InsufficientBalance();
        }

        balances[msg.sender] -= _amount;
        totalDeposits -= _amount;

        emit Withdraw(
            msg.sender,
            _amount,
            balances[msg.sender]
        );
    }

    // =====================================================
    // ADMIN FUNCTION
    // =====================================================

    function emergencyReset(
        address _user
    )
        external
        onlyOwner
    {
        balances[_user] = 0;
    }

    // =====================================================
    // TOKEN TRACKING
    // =====================================================

    function trackToken(
        uint256 tokenId
    )
        external
    {
        emit TokenTracked(
            msg.sender,
            tokenId
        );
    }

    // =====================================================
    // ERC20 STYLE TRANSFER
    // =====================================================

    function transferBalance(
        address _to,
        uint256 _amount
    )
        external
    {
        if (balances[msg.sender] < _amount) {
            revert InsufficientBalance();
        }

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        emit Transfer(
            msg.sender,
            _to,
            _amount
        );
    }
}

/* 
Audit Report 
Medium Finding
M-01: emergencyReset() Breaks Accounting Invariant
Code
balances[_user] = 0;
Issue

User balance is reset but:

totalDeposits

is not reduced.

Example:

Alice balance = 100
totalDeposits = 100

emergencyReset(Alice)

Alice balance = 0
totalDeposits = 100

Accounting becomes inconsistent.

Recommendation
totalDeposits -= balances[_user];
balances[_user] = 0;
Low Finding
L-01: Missing Zero Address Check
Code
transferBalance(address _to, uint256 _amount)

No validation:

_to != address(0)
Impact

Balances can be sent to zero address.

Fix
if (_to == address(0))
    revert InvalidReceiver();
L-02: AdminAction Event Is Generic

Current event:

"Owner function executed"

All admin actions look identical.

Better
event AdminAction(
    address indexed admin,
    string action,
    address target
);
L-03: No Event For emergencyReset()

Critical balance-changing action lacks dedicated event.

Recommended:

event BalanceReset(
    address indexed user,
    uint256 oldBalance
);
Informational Findings
I-01: Correct Use of Indexed Parameters

Good examples:

address indexed user
address indexed from
address indexed to
uint256 indexed tokenId

Allows efficient log filtering.

I-02: Custom Errors Reduce Gas

Good implementation:

error InvalidAmount();
error InsufficientBalance();
error NotOwner();

Cheaper than revert strings.

I-03: Post-Modifier Event Emission Works

Modifier:

_;
emit AdminAction(...);

Correctly demonstrates post-execution behavior.

I-04: Events Follow State Changes

Pattern:

Validate
↓
Update Storage
↓
Emit Event

This prevents misleading logs.
*/
/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
deposit(50)

=========================================================

STEP 1:
emit DepositStarted()

---------------------------------------------------------

LOG CREATED:

user = Alice
amount = 50

---------------------------------------------------------

STEP 2:
Validation checks pass.

---------------------------------------------------------

STEP 3:
Storage updated.

balances[Alice] += 50

---------------------------------------------------------

STEP 4:
emit BalanceUpdated()

---------------------------------------------------------

LOG CREATED:

newBalance = 50

---------------------------------------------------------

STEP 5:
totalDeposits += 50

---------------------------------------------------------

STEP 6:
emit DepositCompleted()

---------------------------------------------------------

LOG CREATED:

amount = 50
totalDeposits = 50

---------------------------------------------------------

TRANSACTION SUCCEEDS

=========================================================
IMPORTANT EVENT UNDERSTANDING
=========================================================

Events are stored in:
transaction logs.

---------------------------------------------------------

NOT inside contract storage.

=========================================================
EVENTS VS STORAGE
=========================================================

---------------------------------------------------------
STORAGE
---------------------------------------------------------

- readable on-chain
- expensive
- persistent state

---------------------------------------------------------
EVENTS
---------------------------------------------------------

- cheaper
- optimized for off-chain reading
- not readable by contracts

=========================================================
IMPORTANT REVERT BEHAVIOR
=========================================================

If transaction reverts:

ALL emitted events disappear.

---------------------------------------------------------

Very important EVM property.

=========================================================
REVERT TRACE
=========================================================

CALL:
validateNumber(50)

=========================================================

STEP 1:
emit ExecutionFailed()

---------------------------------------------------------

Temporary log created.

---------------------------------------------------------

STEP 2:
revert()

---------------------------------------------------------

TRANSACTION REVERTS

---------------------------------------------------------

EVENT LOG ALSO REMOVED

---------------------------------------------------------

FINAL RESULT:

NO event persists on-chain.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Open:
Deployed Contracts panel

---------------------------------------------------------

STEP 3:
Call:
deposit(50)

---------------------------------------------------------

STEP 4:
Open transaction log section

---------------------------------------------------------

OBSERVE EVENTS:

- DepositStarted
- BalanceUpdated
- DepositCompleted

---------------------------------------------------------

STEP 5:
Call:
deposit(500)

EXPECTED:
Revert

---------------------------------------------------------

OBSERVE:
No events persist after revert.

---------------------------------------------------------

STEP 6:
Call:
validateNumber(50)

EXPECTED:
Revert

---------------------------------------------------------

OBSERVE:
ExecutionFailed event disappears too.

=========================================================
IMPORTANT INDEXED UNDERSTANDING
=========================================================

indexed parameters:

allow efficient filtering/searching.

---------------------------------------------------------

Example:

event Deposit(
    address indexed user,
    uint amount
)

---------------------------------------------------------

Frontend can efficiently search:
all events for specific user.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. MISSING EVENTS
---------------------------------------------------------

Critical actions not trackable.

---------------------------------------------------------
2. MISLEADING EVENTS
---------------------------------------------------------

Event says success,
but state update failed.

---------------------------------------------------------
3. EVENT BEFORE EXTERNAL CALL
---------------------------------------------------------

May create misleading logs.

---------------------------------------------------------
4. SENSITIVE DATA LEAKAGE
---------------------------------------------------------

Events are publicly visible forever.

=========================================================
GAS OBSERVATION
=========================================================

Events:
cost less gas than storage.

---------------------------------------------------------

Indexed fields:
slightly more expensive.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Are critical actions logged?
- Do events match state changes?
- Can events mislead monitoring systems?
- Is sensitive data exposed?
- Are events emitted in correct order?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Malformed event emitted before revert.

Off-chain bots incorrectly react.

---------------------------------------------------------

ANOTHER RISK

Missing liquidation event
prevents monitoring systems
from detecting dangerous activity.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Event emission order
2. State updates
3. Revert behavior
4. Off-chain monitoring assumptions
5. Event consistency

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add Withdraw event
2. Add AdminAction event
3. Emit event AFTER modifier execution
4. Add indexed tokenId field

BONUS:
Build mini ERC20-style Transfer event.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Events create blockchain logs
- Events help off-chain tracking
- Events are not contract storage
- Events disappear if transaction reverts
- indexed enables efficient searching
- Event ordering matters heavily
- Incorrect events may mislead systems
- Events are cheaper than storage
- Auditors verify event consistency
- Execution tracking is critical in smart contracts

=========================================================
*/