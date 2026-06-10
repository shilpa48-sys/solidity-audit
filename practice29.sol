// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Try modifying calldata
CONCEPT: Read-only restriction
=========================================================

OBJECTIVE

- Learn why calldata is immutable
- Understand read-only restrictions
- Learn difference between calldata and memory
- Understand Solidity compiler protections

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

calldata is READ-ONLY.

You can read values from calldata,
but cannot modify them directly.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Calldata represents:
external transaction input data.

It is not writable memory.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Understanding calldata immutability is critical for:

- gas optimization
- secure input handling
- Solidity auditing
- memory vs calldata behavior

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Calldata commonly used for:

- router inputs
- swap parameters
- token transfers
- batch operations
- governance proposals

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is calldata used correctly?
- Are developers misunderstanding immutability?
- Are unnecessary memory copies used?
- Is gas optimization possible?
- Are inputs validated safely?

=========================================================
*/

contract CalldataRestriction {

    /*
        STORAGE VARIABLE

        Permanent blockchain state.
    */
    uint256 public savedValue;

    function readCalldata(
        uint256 _number
    )
        external
        pure
        returns (uint256)
    {

        /*
            _number arrives through calldata.

            Reading is allowed.
        */
        return _number;
    }

    function workingMemoryExample(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256[] memory)
    {

        /*
            CREATE MEMORY COPY

            Memory is mutable.
        */
        uint256[] memory tempArray = _numbers;

        /*
            MODIFY MEMORY COPY

            Allowed.
        */
        tempArray[0] = 999;

        return tempArray;
    }

    /*
    =====================================================
    THIS FUNCTION INTENTIONALLY FAILS
    =====================================================

    Uncomment to observe compiler error.

    function failModification(
        uint256[] calldata _numbers
    )
        external
        pure
    {

        // ERROR:
        // calldata is read-only

        _numbers[0] = 999;
    }

    =====================================================
    COMPILER ERROR EXPLANATION
    =====================================================

    Solidity prevents modification because:
    calldata is immutable.

    =====================================================
    */
}

//patched code
contract ReadCalldataValuesPatched {

    uint256 public constant MAX_ARRAY_SIZE = 100;

    function findLargest(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {
        require(
            _numbers.length > 0,
            "Empty array"
        );

        require(
            _numbers.length <= MAX_ARRAY_SIZE,
            "Array too large"
        );

        uint256 largest = _numbers[0];

        for (uint256 i = 1; i < _numbers.length; i++) {

            if (_numbers[i] > largest) {

                largest = _numbers[i];
            }
        }

        return largest;
    }
}

/*
Audit Report
Title

Unbounded Calldata Array Processing

Severity

Low

Reason

The function processes a user-supplied calldata array using a loop without enforcing a maximum size.

Location

Contract: ReadCalldataValuesVul

Function: findLargest()

Vulnerability Description

The contract iterates through an attacker-controlled calldata array to determine the largest value.

Because no maximum array length is enforced, 
an attacker can supply excessively large arrays that significantly increase gas consumption.

Impact
Increased transaction costs
Gas exhaustion risk
Potential denial-of-service conditions
Reduced contract scalability
Proof of Concept
Deploy contract
Call findLargest([1,2,3])
Observe normal execution
Call findLargest() with a very large array
Observe substantial gas increase
Extremely large arrays may cause transaction failure
Root Cause
Missing array length validation
Loop execution depends entirely on attacker-controlled input
No upper bound on calldata processing
Recommendation

Validate calldata array size before processing.

Example:

require(
    _numbers.length <= 100,
    "Array too large"
);

Also reject empty arrays:

require(
    _numbers.length > 0,
    "Empty array"
);
Patched Code
function findLargest(
    uint256[] calldata _numbers
)
    external
    pure
    returns (uint256)
{
    require(
        _numbers.length > 0,
        "Empty array"
    );

    require(
        _numbers.length <= 100,
        "Array too large"
    );

    uint256 largest = _numbers[0];

    for (uint256 i = 1; i < _numbers.length; i++) {

        if (_numbers[i] > largest) {

            largest = _numbers[i];
        }
    }

    return largest;
}
*/

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
readCalldata(50)

EVM ACTIONS:

1. External input arrives in calldata
2. Value read directly
3. Returned successfully
4. Calldata discarded after execution

---------------------------------------------------------

IMPORTANT

No modification occurs.

=========================================================

CALL:
workingMemoryExample([1,2,3])

EVM ACTIONS:

1. Array arrives in calldata
2. Copied into mutable memory
3. Memory array modified
4. Modified memory returned
5. Memory destroyed after execution

---------------------------------------------------------

RETURN VALUE:

[999,2,3]

---------------------------------------------------------

ORIGINAL CALLDATA:
Never changed.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
readCalldata(123)

EXPECTED:
123

---------------------------------------------------------

STEP 3:
Call:
workingMemoryExample([1,2,3])

EXPECTED:
[999,2,3]

---------------------------------------------------------

STEP 4:
Uncomment failModification()

---------------------------------------------------------

STEP 5:
Compile contract

EXPECTED:
Compiler error

=========================================================
EXPECTED COMPILER ERROR
=========================================================

Typical error:

TypeError:
Calldata arrays are read-only.

---------------------------------------------------------

IMPORTANT

Solidity protects calldata automatically.

=========================================================
IMPORTANT CALLDATA UNDERSTANDING
=========================================================

CALLDATA IS:

- temporary
- external input
- immutable
- read-only

---------------------------------------------------------

YOU CAN:
- read calldata
- loop through calldata
- copy calldata to memory

---------------------------------------------------------

YOU CANNOT:
- modify calldata directly

=========================================================
WHY CALLDATA IS IMMUTABLE
=========================================================

Reason 1:
Gas efficiency

---------------------------------------------------------

Reason 2:
External transaction integrity

---------------------------------------------------------

Reason 3:
Avoid unnecessary memory writes

=========================================================
CALLDATA VS MEMORY
=========================================================

---------------------------------------------------------
CALLDATA
---------------------------------------------------------

Read-only

Cheapest

External input

Immutable

---------------------------------------------------------
MEMORY
---------------------------------------------------------

Mutable

Temporary

Can be modified

More expensive

=========================================================
HOW TO MODIFY CALLDATA SAFELY
=========================================================

STEP 1:
Copy calldata into memory

Example:

uint256[] memory temp = _numbers;

---------------------------------------------------------

STEP 2:
Modify memory copy

temp[0] = 999;

---------------------------------------------------------

IMPORTANT

Original calldata remains unchanged.

=========================================================
GAS OBSERVATION
=========================================================

READING CALLDATA:
Cheap

---------------------------------------------------------

COPYING TO MEMORY:
Costs additional gas

---------------------------------------------------------

MODIFYING MEMORY:
Allowed

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. IMMUTABILITY ASSUMPTIONS
---------------------------------------------------------

Auditors verify developers understand:
calldata cannot be modified.

---------------------------------------------------------
2. UNNECESSARY MEMORY COPIES
---------------------------------------------------------

Copying calldata unnecessarily
wastes gas.

---------------------------------------------------------
3. LARGE INPUT DOS
---------------------------------------------------------

Huge calldata arrays may:
- increase gas usage
- create DOS conditions

---------------------------------------------------------
4. INPUT VALIDATION
---------------------------------------------------------

All calldata is attacker-controlled.

Never trust external inputs.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker sends huge calldata arrays.

Contract copies everything into memory.

Result:
- excessive gas usage
- DOS risk

---------------------------------------------------------

ANOTHER RISK

Developer incorrectly assumes:
calldata modifications persist.

Logic silently fails.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Accept calldata string
2. Copy into memory
3. Return modified version safely

BONUS:
Compare gas:
calldata vs memory inputs

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Calldata is read-only
- Calldata cannot be modified
- Solidity enforces immutability
- Memory copies are mutable
- Copying calldata costs gas
- Calldata is temporary
- External inputs are attacker-controlled
- Memory/storage/calldata behave differently
- Gas optimization matters
- Auditors inspect data-location behavior carefully

=========================================================
*/