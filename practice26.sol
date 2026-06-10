// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Create calldata uint input
CONCEPT: External immutable input
=========================================================

OBJECTIVE

- Learn how external function inputs work
- Understand calldata in Solidity
- Learn immutable input behavior
- Understand difference between calldata, memory, and storage

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

calldata:
- temporary input area
- read-only
- immutable
- cheaper than memory

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Function arguments from external calls
arrive through calldata.

Calldata exists only during execution.

---------------------------------------------------------
WHY CALLDATA MATTERS
---------------------------------------------------------

Using calldata correctly:
- saves gas
- prevents unnecessary copying
- improves efficiency

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Calldata used heavily in:

- external function parameters
- DeFi protocols
- routers
- token transfers
- governance systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is calldata used efficiently?
- Are unnecessary memory copies present?
- Are inputs validated?
- Can attacker abuse external inputs?
- Is immutability understood?

=========================================================
*/

contract CalldataUintInput {

    /*
        STATE VARIABLE

        Stored permanently on blockchain.
    */
    uint256 public storedNumber;

    function readInput(
        uint256 _number
    )
        external
        pure
        returns (uint256)
    {

        /*
            _number arrives through calldata.

            uint256 is value type,
            so Solidity handles it efficiently.

            Input exists temporarily
            during execution only.
        */

        return _number;
    }

    function saveInput(
        uint256 _number
    )
        external
    {

        /*
            INPUT READ FROM CALLDATA

            Then copied into storage.
        */
        storedNumber = _number;
    }

    function doubleInput(
        uint256 _number
    )
        external
        pure
        returns (uint256)
    {

        /*
            Using immutable external input
            for temporary calculation.
        */
        uint256 result = _number * 2;

        return result;
    }
}

//patched code
contract CalldataUintInputPatched {

    uint256 public storedNumber;

    function readInput(
        uint256 _number
    )
        external
        pure
        returns (uint256)
    {
        return _number;
    }

    function saveInput(
        uint256 _number
    )
        external
    {
        storedNumber = _number;
    }

    function doubleInput(
        uint256 _number
    )
        external
        pure
        returns (uint256)
    {
        return _number * 2;
    }

    /*
        MINI CHALLENGE SOLUTION

        Uses calldata array directly.
    */
    function sumArray(
        uint256[] calldata numbers
    )
        external
        pure
        returns (uint256 total)
    {
        for (uint256 i = 0; i < numbers.length; i++) {
            total += numbers[i];
        }
    }
}
/*
audit report
Title

Inefficient Memory Usage for External Array Input

Severity

Informational

Reason

The contract can be implemented using a memory array parameter for externally supplied data, causing unnecessary copying from calldata into memory.

While not a security vulnerability, it increases gas costs and reduces execution efficiency.

Location

Contract: CalldataUintInput

Function: Array processing function (Mini Challenge implementation)

Vulnerability Description

A common implementation pattern is:

function sumArray(
    uint256[] memory numbers
)
    external
    pure
    returns (uint256)
{
    ...
}

Because the function is external, the input initially arrives in calldata.

Using memory forces Solidity to:

Allocate memory.
Copy every array element from calldata.
Process the copied array.

This additional copy consumes unnecessary gas.

Impact
Increased gas consumption.
Reduced execution efficiency.
Higher transaction costs.
Scalability impact for large arrays.
Proof of Concept

Vulnerable version:

function sumArray(
    uint256[] memory numbers
)
    external
    pure
    returns (uint256 total)
{
    for (uint256 i = 0; i < numbers.length; i++) {
        total += numbers[i];
    }
}

Execution flow:

User sends array through calldata.
Solidity copies entire array into memory.
Loop processes copied data.
Additional gas consumed.
Root Cause
External input already exists in calldata.
Function unnecessarily creates a memory copy.
Read-only processing does not require mutable memory.
Recommendation

Use calldata directly:

function sumArray(
    uint256[] calldata numbers
)
    external
    pure
    returns (uint256 total)
{
    for (uint256 i = 0; i < numbers.length; i++) {
        total += numbers[i];
    }
}

Benefits:

No memory copy.
Lower gas usage.
Better scalability.
More efficient external calls.
Patched Code
function sumArray(
    uint256[] calldata numbers
)
    external
    pure
    returns (uint256 total)
{
    for (uint256 i = 0; i < numbers.length; i++) {
        total += numbers[i];
    }
}
Conclusion

The issue is a gas-efficiency concern rather than a security vulnerability. 
Using calldata for read-only external array parameters eliminates unnecessary memory allocation and results in a more optimized implementation.
*/

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
readInput(50)

EVM ACTIONS:

1. External transaction sent
2. Input encoded into calldata
3. _number read from calldata
4. Value returned
5. Calldata discarded after execution

---------------------------------------------------------

IMPORTANT

Nothing stored permanently.

=========================================================

CALL:
saveInput(777)

EVM ACTIONS:

1. Input arrives through calldata
2. _number read
3. storedNumber updated in storage
4. Blockchain state changes permanently

---------------------------------------------------------

FINAL STORAGE:

storedNumber = 777

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
readInput(50)

EXPECTED:
50

---------------------------------------------------------

STEP 3:
Call:
doubleInput(10)

EXPECTED:
20

---------------------------------------------------------

STEP 4:
Call:
saveInput(999)

---------------------------------------------------------

STEP 5:
Call:
storedNumber()

EXPECTED:
999

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Pass zero

EXPECTED:
Works correctly

---------------------------------------------------------

TEST:
Pass max uint256

EXPECTED:
Works unless arithmetic overflow occurs

---------------------------------------------------------

TEST:
Repeated calls

OBSERVE:
Calldata recreated every execution

=========================================================
IMPORTANT CALLDATA UNDERSTANDING
=========================================================

CALLDATA IS:

- temporary
- read-only
- external input data

---------------------------------------------------------

AFTER FUNCTION ENDS:
Calldata disappears automatically.

---------------------------------------------------------

VERY IMPORTANT

You cannot permanently modify calldata.

=========================================================
CALLDATA VS MEMORY VS STORAGE
=========================================================

---------------------------------------------------------
CALLDATA
---------------------------------------------------------

Temporary

Read-only

Cheapest

External inputs

---------------------------------------------------------
MEMORY
---------------------------------------------------------

Temporary

Mutable

More expensive than calldata

---------------------------------------------------------
STORAGE
---------------------------------------------------------

Permanent

Most expensive

Persists on blockchain

=========================================================
IMMUTABILITY CONCEPT
=========================================================

CALLDATA INPUTS ARE IMMUTABLE

Meaning:
they cannot be modified directly.

---------------------------------------------------------

THIS FAILS:

_number = 100;

(for reference-type calldata variables)

---------------------------------------------------------

Reason:
calldata is read-only.

=========================================================
GAS OBSERVATION
=========================================================

CALLDATA:
Cheaper than memory

---------------------------------------------------------

Reason:
No unnecessary copying.

---------------------------------------------------------

STORAGE WRITES:
Most expensive operations.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. INPUT VALIDATION
---------------------------------------------------------

External calldata is attacker-controlled.

Always validate inputs.

---------------------------------------------------------
2. GAS OPTIMIZATION
---------------------------------------------------------

Auditors check:
whether calldata should replace memory.

---------------------------------------------------------
3. IMMUTABILITY ASSUMPTIONS
---------------------------------------------------------

Developers must understand:
calldata cannot be modified.

---------------------------------------------------------
4. LARGE INPUT DOS
---------------------------------------------------------

Huge calldata inputs may:
increase gas consumption.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker sends malicious input values.

Without validation:
protocol logic may break.

---------------------------------------------------------

ANOTHER RISK

Large attacker-controlled calldata arrays
may create DOS via gas exhaustion.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Accept calldata uint array
2. Loop through values
3. Return total sum

BONUS:
Compare gas:
memory array vs calldata array

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Calldata stores external input data
- Calldata is temporary
- Calldata is read-only
- Calldata cheaper than memory
- Storage persists permanently
- External inputs are attacker-controlled
- Storage writes consume most gas
- Calldata improves gas efficiency
- Inputs disappear after execution
- Auditors inspect input handling carefully

=========================================================
*/