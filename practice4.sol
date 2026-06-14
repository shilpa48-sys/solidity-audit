// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Store bool in state
CONCEPT: Boolean storage
=========================================================

OBJECTIVE

- Learn how Solidity stores boolean values
- Understand true/false state handling
- Learn how bool variables control contract logic
- Understand security implications of boolean flags

---------------------------------------------------------
WHAT IS A BOOLEAN?
---------------------------------------------------------

Boolean values can only be:

- true
- false

Solidity type:
bool

---------------------------------------------------------
COMMON REAL-WORLD USES
---------------------------------------------------------

Boolean variables are heavily used for:

- pause/unpause systems
- access permissions
- voting status
- transaction execution tracking
- reentrancy locks
- feature enable/disable switches

---------------------------------------------------------
IMPORTANT CONCEPT
---------------------------------------------------------

State bool variables are stored permanently
inside blockchain storage.

Their values persist across transactions.

---------------------------------------------------------
DEFAULT VALUE
---------------------------------------------------------

bool default value = false

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors check:

- Who can change boolean flags?
- Can attackers bypass restrictions?
- Is pause mechanism secure?
- Can critical flags be manipulated?
- Are flags reset correctly?

=========================================================
*/

contract StoreBoolean {

    bool public isActive;

    function setStatus(bool _status) public {
        isActive = _status;
    }

    function getStatus() public view returns (bool) {
        return isActive;
    }
}
//patched code
contract StoreBooleanPatched {

    bool public isActive;

    address public owner;

    error NotOwner();

    constructor() {
        owner = msg.sender;
    }

    function setStatus(
        bool _status
    )
        external
    {
        if (msg.sender != owner)
            revert NotOwner();

        isActive = _status;
    }

    function toggleStatus()
        external
    {
        if (msg.sender != owner)
            revert NotOwner();

        /*
            MINI CHALLENGE FIX

            Reverse current state.
        */
        isActive = !isActive;
    }

    function getStatus()
        external
        view
        returns (bool)
    {
        return isActive;
    }
}
/*
Report
Title:

Missing Access Control on Boolean State Modification

Severity:

Low

Reason:

The contract allows any user to modify the isActive boolean state through setStatus(). 
Since boolean flags commonly control critical application behavior such as 
pausing, permissions, and feature activation, unrestricted modification can lead to unintended contract behavior.

Location:

Contract: StoreBoolean
Function: setStatus(bool _status)

Vulnerability Description:

The contract stores a persistent boolean flag (isActive) and exposes 
a public function allowing arbitrary users to change its value.

A common Solidity security issue occurs when critical state variables can be modified without authorization checks.

If isActive were later integrated into business logic (withdrawals, deposits, governance actions, etc.), an attacker could freely enable or disable functionality.

Impact:

Possible consequences include:

Unauthorized protocol activation
Unauthorized protocol deactivation
Bypass of pause mechanisms
Manipulation of contract state
Unexpected application behavior

In the current educational example the impact is limited, but the pattern becomes dangerous when reused in production contracts.

Proof of Concept:
Deploy contract
Verify:
isActive = false
Attacker calls:
setStatus(true)
Verify:
isActive = true
Attacker calls:
setStatus(false)
Verify:
isActive = false
Observation:

Any address can modify the contract's boolean state.

Root Cause:

No access-control validation exists before updating storage.

Vulnerable pattern:

function setStatus(bool _status) public {
    isActive = _status;
}

Issues:

No owner check
No authorization logic
State modification exposed to everyone
Recommendation:

Restrict modification of critical boolean flags to authorized users only.

Example:

require(
    msg.sender == owner,
    "Not owner"
);

Additionally, implement the Mini Challenge requirement using a secure toggle function.
Patched Code Explanation:

The patched contract:

Adds owner-based access control
Prevents arbitrary users from modifying boolean state
Implements the Mini Challenge toggleStatus() function
Uses the recommended Solidity pattern:
isActive = !isActive;

Behavior:

false -> true
true  -> false

This preserves the original educational structure while 
demonstrating secure boolean state management and proper authorization controls that 
auditors expect in production smart contracts.
*/

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

isActive = false

Reason:
Default bool value is false.

---------------------------------------------------------

CALL:
setStatus(true)

EVM ACTIONS:

1. Transaction reaches contract
2. Boolean value arrives through calldata
3. Storage slot updated
4. isActive becomes true
5. Gas consumed

---------------------------------------------------------

CALL:
setStatus(false)

RESULT:
Storage updated again

isActive becomes false

Old value overwritten.

---------------------------------------------------------

CALL:
getStatus()

EVM reads storage value
and returns current boolean state.

=========================================================
REMIX TESTING
=========================================================

NORMAL FLOW

STEP 1:
Deploy contract

EXPECTED:
isActive() => false

---------------------------------------------------------

STEP 2:
Call:
setStatus(true)

EXPECTED:
isActive() => true

---------------------------------------------------------

STEP 3:
Call:
setStatus(false)

EXPECTED:
isActive() => false

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Repeated toggling

Call:
setStatus(true)
setStatus(false)
setStatus(true)

EXPECTED:
Latest value stored successfully

---------------------------------------------------------

OBSERVE:
Boolean state changes permanently
after each transaction.

=========================================================
STORAGE OBSERVATION
=========================================================

Storage example:

Initial:
slot0 => false

After:
setStatus(true)

slot0 => true

After:
setStatus(false)

slot0 => false

Only latest value exists in storage.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

IMPORTANT SECURITY FACT

Boolean flags often control CRITICAL LOGIC.

Example uses:
- contract paused?
- user verified?
- transaction executed?
- admin approved?
- reentrancy locked?

---------------------------------------------------------
1. MISSING ACCESS CONTROL
---------------------------------------------------------

Current issue:
ANYONE can change status.

Real-world danger:
Attacker may:
- pause protocol
- unpause protocol
- bypass protections
- manipulate system behavior

---------------------------------------------------------
2. BOOLEAN MISUSE
---------------------------------------------------------

Incorrect boolean handling can cause:
- stuck funds
- bypassed validations
- repeated execution
- double spending

---------------------------------------------------------
3. STATE DESYNCHRONIZATION
---------------------------------------------------------

Auditors verify:
- flags updated correctly
- flags reset properly
- logic cannot become inconsistent

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Suppose:

isActive controls withdrawals.

Logic:
- true => withdrawals allowed
- false => withdrawals blocked

Attacker calls:

setStatus(true)

Impact:
Restricted functionality becomes enabled.

---------------------------------------------------------

ANOTHER REAL-WORLD ISSUE

Reentrancy guards use booleans.

If boolean reset fails:
- contract may lock forever
OR
- reentrancy protection may fail

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add toggleStatus() function
2. Function should reverse current state

Example:
true -> false
false -> true

HINT:

Use:
isActive = !isActive;

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- bool stores true/false values
- Default bool value is false
- Boolean state persists on blockchain
- Storage updates overwrite old values
- Boolean flags often control critical logic
- Access control is essential
- Incorrect flag handling causes vulnerabilities
- Reentrancy guards commonly use booleans

=========================================================
*/