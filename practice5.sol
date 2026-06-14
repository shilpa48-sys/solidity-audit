// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Store mapping values
CONCEPT: User-specific storage
=========================================================

OBJECTIVE

- Learn how mappings store user-specific data
- Understand key-value storage in Solidity
- Learn how blockchain stores data per address
- Understand mapping security and storage behavior

---------------------------------------------------------
WHAT IS A MAPPING?
---------------------------------------------------------

A mapping is a key-value data structure.

Syntax:

mapping(keyType => valueType)

Example:

mapping(address => uint256)

Meaning:
Each address has its own uint256 value.

---------------------------------------------------------
REAL-WORLD USES
---------------------------------------------------------

Mappings are heavily used in:

- token balances
- user permissions
- staking amounts
- voting systems
- allowances
- whitelist systems

---------------------------------------------------------
IMPORTANT CONCEPT
---------------------------------------------------------

Mappings do NOT store data sequentially like arrays.

Instead:
- each key points directly to a value
- storage is calculated using hashing internally

---------------------------------------------------------
DEFAULT VALUES
---------------------------------------------------------

If value not set:

uint256 => 0
bool => false
address => zero address

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors check:

- Can attacker overwrite another user's data?
- Is msg.sender used correctly?
- Is authorization missing?
- Can mappings be manipulated?
- Are balances updated safely?

=========================================================
*/

contract UserStorage {

    mapping(address => uint256) public balances;

    function storeValue(uint256 _amount) public {
        balances[msg.sender] = _amount;
    }

    function getMyValue() public view returns (uint256) {
        return balances[msg.sender];
    }
}
//patched code 
contract UserStoragePatched {

    mapping(address => uint256) public balances;

    event ValueUpdated(
        address indexed user,
        uint256 oldValue,
        uint256 newValue
    );

    function storeValue(
        uint256 _amount
    )
        external
    {
        require(
            _amount > balances[msg.sender],
            "Value must increase"
        );

        uint256 oldValue =
            balances[msg.sender];

        balances[msg.sender] = _amount;

        emit ValueUpdated(
            msg.sender,
            oldValue,
            _amount
        );
    }

    function getMyValue()
        external
        view
        returns (uint256)
    {
        return balances[msg.sender];
    }
}
/*
Audit Report
Finding 1
Low Severity
Unrestricted Value Overwrite
Location
function storeValue(uint256 _amount) public {
    balances[msg.sender] = _amount;
}
Description

Users can overwrite their stored value with any number, including:

storeValue(100);
storeValue(1);
storeValue(0);

There is no restriction on decreases.

Impact

If the mapping later represents:

reputation
staking score
membership level
reward tier

then accidental or malicious downgrades may occur.

Recommendation

If intended to be monotonic:

require(
    _amount > balances[msg.sender],
    "Value must increase"
);
Status

Fixed in patched version.

Finding 2
Low Severity
Missing Event Emission
Description

Storage changes occur silently.

balances[msg.sender] = _amount;

No event is emitted.

Impact

Off-chain systems cannot efficiently track updates.

Recommendation
event ValueUpdated(
    address indexed user,
    uint256 oldValue,
    uint256 newValue
);

Emit after successful update.

Status

Fixed in patched version.

Finding 3
Informational
Correct Use of msg.sender
Observation
balances[msg.sender] = _amount;

The caller can only modify their own storage slot.

Security Impact

Prevents direct modification of another user's balance.

Status

✅ No issue identified.

Finding 4
Informational
Mapping Defaults to Zero
Observation

For any address that has never interacted:

balances[user] == 0

This is Solidity's expected behavior.

Status

No issue.

Finding 5
Informational
Mapping Is Not Iterable
Observation

The contract provides no way to enumerate all users.

This is not a vulnerability but an architectural limitation of mappings.

Example

The contract cannot answer:

How many users exist?
Who has stored values?

without additional data structures.

Recommendation

Maintain an array of users if enumeration is required.

Gas Review
Good
Single mapping lookup.
O(1) read and write complexity.
No loops.
No external calls.
No reentrancy surface.
Optimization

Use external instead of public:

function storeValue(uint256 _amount)
    external
function getMyValue()
    external
    view

This slightly reduces gas for external calls. 
*/
/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

No values explicitly stored yet.

For every address:

balances[address] => 0

because uint256 default value is zero.

---------------------------------------------------------

CALL:
storeValue(100)

Suppose caller:

0xAAA...

EVM ACTIONS:

1. Transaction reaches contract
2. _amount arrives through calldata
3. msg.sender identified
4. Mapping storage slot calculated internally
5. balances[msg.sender] updated
6. Value stored permanently

RESULT:

balances[0xAAA...] = 100

---------------------------------------------------------

ANOTHER USER CALLS:
storeValue(500)

Suppose second user:

0xBBB...

RESULT:

balances[0xBBB...] = 500

IMPORTANT:
Each user has separate storage value.

---------------------------------------------------------

CALL:
getMyValue()

EVM:
1. Reads mapping using msg.sender key
2. Returns stored value for caller only

=========================================================
REMIX TESTING
=========================================================

NORMAL FLOW

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Using Account 1

Call:
storeValue(100)

EXPECTED:
balances(Account1) => 100

---------------------------------------------------------

STEP 3:
Switch to Account 2

Call:
storeValue(999)

EXPECTED:
balances(Account2) => 999

---------------------------------------------------------

STEP 4:
Check Account 1 again

EXPECTED:
balances(Account1) still equals 100

OBSERVE:
Each address has isolated storage.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Store zero

Call:
storeValue(0)

EXPECTED:
Value updated to zero

---------------------------------------------------------

TEST:
Overwrite existing value

Call:
storeValue(500)
storeValue(700)

EXPECTED:
Latest value = 700

Old value overwritten.

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

Mappings use HASH-BASED STORAGE.

Internally:

keccak256(key + slot)

is used to determine storage location.

This allows:
- efficient lookups
- isolated user storage
- scalable data organization

---------------------------------------------------------

IMPORTANT:
Mappings are NOT iterable.

You cannot:
- loop through all keys
- get total mapping size directly

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. USER ISOLATION
---------------------------------------------------------

Using:

msg.sender

ensures users update only THEIR data.

This is critical.

---------------------------------------------------------
2. OVERWRITE RISKS
---------------------------------------------------------

Current logic allows users to overwrite
their own values anytime.

Auditors ask:
- Is overwrite intended?
- Should updates be restricted?
- Should values only increase?

---------------------------------------------------------
3. AUTHORIZATION ISSUES
---------------------------------------------------------

Dangerous example:

balances[_user] = _amount;

without validation may allow attackers
to modify other users' data.

---------------------------------------------------------
4. STORAGE MANIPULATION
---------------------------------------------------------

Mappings often hold:
- token balances
- rewards
- ownership
- permissions

Incorrect updates can cause:
- theft
- balance corruption
- privilege escalation

=========================================================
ATTACK THINKING
=========================================================

SAFE PART:
Using msg.sender prevents direct overwrite
of another user's value.

---------------------------------------------------------

DANGEROUS VERSION

If contract had:

function update(address user, uint amount)

without access control,

attacker could modify ANY user's data.

---------------------------------------------------------

REAL-WORLD IMPACT

Incorrect mapping handling may lead to:
- token theft
- balance inflation
- unauthorized access
- reward manipulation

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Users can only INCREASE value
2. Decreasing value should fail

HINT:

Use:
require(_amount > balances[msg.sender])

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Mappings store key-value pairs
- address => uint256 is common pattern
- Each user gets isolated storage
- msg.sender identifies caller
- Mapping values persist on blockchain
- Default uint value is zero
- Mapping values can be overwritten
- Mappings use hash-based storage internally
- Mappings are not iterable
- Incorrect mapping logic causes major vulnerabilities

=========================================================
*/