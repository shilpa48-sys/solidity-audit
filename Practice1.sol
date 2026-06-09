// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Store uint in state variable
CONCEPT: Persistent blockchain state
=========================================================

OBJECTIVE

- Learn how Solidity stores data permanently on-chain
- Understand state variables and storage
- Learn how storage updates consume gas
- Understand why unrestricted writes are dangerous

---------------------------------------------------------
STORAGE UNDERSTANDING
---------------------------------------------------------

STATE VARIABLE:
- Stored permanently on blockchain
- Lives in contract storage
- Costs gas to modify
- Persists across transactions

DEFAULT VALUE:
uint256 => 0

AUDITOR FOCUS:
- Who can modify storage?
- Is access control missing?
- Can attackers overwrite values?
- Are unnecessary storage writes happening?

=========================================================
*/

contract StoreUintVul {

    uint256 public number;

    // Vulnerable: anyone can update number
    function storeNumber(uint256 _newNumber) public {
        number = _newNumber;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL: storeNumber(100)

1. Transaction sent to blockchain
2. _newNumber arrives through calldata
3. EVM executes storage write
4. Storage slot updated permanently
5. Gas consumed
6. Blockchain state changes

---------------------------------------------------------

CALL: getNumber()

1. EVM reads value from storage
2. Returns current value
3. No state modification
4. No transaction required for external read

=========================================================
REMIX TESTING
=========================================================

NORMAL FLOW

1. Deploy contract
2. Call number()
   EXPECTED => 0

3. Call:
   storeNumber(100)

4. Call:
   number()

   EXPECTED => 100

---------------------------------------------------------

EDGE CASES

Test:
storeNumber(0)

EXPECTED:
Works correctly

---------------------------------------------------------

Test:
storeNumber(type(uint256).max)

EXPECTED:
Largest uint256 stored successfully

=========================================================
FAILURE / SECURITY OBSERVATION
=========================================================

PROBLEM:
Anyone can modify number.

ATTACK:
Another wallet can call:
storeNumber(999999)

REAL-WORLD RISK:
If this variable controlled:
- token price
- protocol config
- treasury amount

then attacker could manipulate protocol behavior.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so only owner can update number.

HINT:
- Create owner variable
- Use constructor
- Add require(msg.sender == owner)

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- State variables use storage
- Storage is persistent
- Storage writes cost gas
- view functions only read data
- Public variables create getter functions
- calldata stores function inputs
- Missing access control is dangerous

=========================================================
*/

// patched code

contract StoreUint {

    uint256 public number;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function storeNumber(uint256 _newNumber) public {
        require(msg.sender == owner, "You are not the owner");
        number = _newNumber;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }
}

/*
audit report content

Title:
Missing Access Control on State Variable Update

Severity:
Medium

Reason:
Any user can overwrite the stored value because no authorization check exists.

Location:
Contract: StoreUintVul
Function: storeNumber()

Vulnerability Description:
The function storeNumber() allows any address to update the
number state variable. Since no ownership or role-based
access control is implemented, unauthorized users can
modify important contract data.

Impact:
An attacker can:
- Change stored values
- Manipulate application state
- Override values set by legitimate users
- Cause unexpected behavior in systems relying on this value

Proof of Concept:

1. Deploy StoreUintVul
2. Account A calls storeNumber(100)
3. number() returns 100
4. Switch to Account B
5. Account B calls storeNumber(999999)
6. number() now returns 999999

Root Cause:
- Missing ownership mechanism
- Missing authorization check before storage write

Recommendation:
Restrict updates to authorized users only.
Store the deployer as owner and validate msg.sender
before allowing storage modifications.

Example:

address public owner;

constructor() {
    owner = msg.sender;
}

function storeNumber(uint256 _newNumber) public {
    require(msg.sender == owner, "Not owner");
    number = _newNumber;
}

Patched Code:
StoreUint contract shown above.
*/
