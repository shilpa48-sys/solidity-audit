// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Pass large calldata array
CONCEPT: Input scaling
=========================================================

OBJECTIVE

- Learn how large calldata arrays behave
- Understand input scaling risks
- Learn gas impact of large external inputs
- Understand DOS risks from unbounded arrays

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Calldata arrays are efficient,
but VERY LARGE arrays still consume gas.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Even though calldata avoids memory copying:

Loops over huge arrays still:
- consume gas
- increase execution time
- may exceed block gas limit

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Many real-world smart contract failures happen because:
functions cannot scale with large inputs.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Large calldata arrays appear in:

- batch token transfers
- multicall systems
- governance voting
- Merkle proofs
- NFT batch minting
- swap routers

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Can attacker pass massive arrays?
- Are loops bounded safely?
- Can function become unusable?
- Is pagination needed?
- Are gas limits considered?

=========================================================
*/

contract LargeCalldataArray {

    /*
        STORAGE VARIABLE

        Permanent blockchain state.
    */
    uint256 public totalProcessed;

    /*
    =====================================================
    PROCESS LARGE CALLDATA ARRAY
    =====================================================
    */

    function processLargeArray(
        uint256[] calldata _numbers
    )
        external
        returns (uint256)
    {

        uint256 total = 0;

        /*
            LOOP OVER CALLDATA ARRAY

            Even though calldata is efficient,
            loop iterations still cost gas.
        */
        for (uint256 i = 0; i < _numbers.length; i++) {

            total += _numbers[i];
        }

        /*
            Save final result permanently.
        */
        totalProcessed = total;

        return total;
    }

    /*
    =====================================================
    RETURN ARRAY SIZE
    =====================================================
    */

    function getArraySize(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {

        return _numbers.length;
    }

    /*
    =====================================================
    SAFE INPUT LIMIT EXAMPLE
    =====================================================
    */

    function safeProcessing(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {

        /*
            INPUT LIMIT PROTECTION

            Prevent excessively large arrays.
        */
        require(
            _numbers.length <= 100,
            "Array too large"
        );

        uint256 total = 0;

        for (uint256 i = 0; i < _numbers.length; i++) {

            total += _numbers[i];
        }

        return total;
    }
}

//patched data
contract LargeCalldataArrayPatched {

    uint256 public totalProcessed;

    uint256 public constant MAX_BATCH_SIZE = 100;

    function processBatch(
        uint256[] calldata _numbers,
        uint256 _start,
        uint256 _limit
    )
        external
        returns (uint256)
    {
        require(
            _limit > 0 &&
            _limit <= MAX_BATCH_SIZE,
            "Invalid batch size"
        );

        require(
            _start < _numbers.length,
            "Invalid start index"
        );

        uint256 end = _start + _limit;

        if (end > _numbers.length) {
            end = _numbers.length;
        }

        uint256 total;

        for (uint256 i = _start; i < end; i++) {
            total += _numbers[i];
        }

        totalProcessed = total;

        return total;
    }

    function safeProcessing(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {
        require(
            _numbers.length <= MAX_BATCH_SIZE,
            "Array too large"
        );

        uint256 total;

        for (uint256 i = 0; i < _numbers.length; i++) {
            total += _numbers[i];
        }

        return total;
    }

    function getArraySize(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {
        return _numbers.length;
    }
}

/*
Audit Report
Title:

Unbounded Calldata Array Processing

Severity:

Medium

Reason:

The contract processes attacker-controlled calldata arrays using an unbounded loop. Large arrays can significantly increase gas consumption and eventually make the function impractical or unusable.

Location:

Contract: LargeCalldataArray

Function:

processLargeArray()
Vulnerability Description:

The contract iterates through every element of a user-supplied calldata array without enforcing a maximum size.

for (uint256 i = 0; i < _numbers.length; i++) {
    total += _numbers[i];
}

Since array length is controlled by external callers, an attacker can submit extremely large arrays.

Although calldata is more gas-efficient than memory, loop execution still scales linearly with array size.

Impact:
Excessive gas consumption
Transaction failures
Denial of Service (DoS)
Poor scalability
Functions may become unusable under heavy input sizes
Proof of Concept
Deploy contract
Call:
processLargeArray([1,2,3,...10000 elements])
Observe:
Extremely high gas usage
Potential out-of-gas revert
Repeat with larger arrays.
Observe increasing execution costs and reduced usability.
Root Cause
Missing array size validation
Unbounded iteration over user-controlled data
No batching or pagination mechanism
Lack of scalability controls
Recommendation

Implement pagination and batch-size restrictions.

Example:

uint256 public constant MAX_BATCH_SIZE = 100;

require(
    _limit <= MAX_BATCH_SIZE,
    "Invalid batch size"
);

Process large datasets across multiple transactions instead of a single call.

Patched Code
function processBatch(
    uint256[] calldata _numbers,
    uint256 _start,
    uint256 _limit
)
    external
    returns (uint256)
{
    require(
        _limit <= MAX_BATCH_SIZE,
        "Invalid batch size"
    );

    uint256 end = _start + _limit;

    if (end > _numbers.length) {
        end = _numbers.length;
    }

    uint256 total;

    for (uint256 i = _start; i < end; i++) {
        total += _numbers[i];
    }

    return total;
}
Security Outcome

After patching:

Processing becomes bounded
Gas costs become predictable
DoS risk is reduced
Large datasets can be handled safely
Scalability improves significantly
*/

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
processLargeArray([1,2,3])

EVM ACTIONS:

1. Array arrives in calldata
2. Loop reads values directly
3. No memory copy created
4. Gas consumed per iteration
5. Result stored permanently

---------------------------------------------------------

FINAL STORAGE:

totalProcessed = 6

=========================================================

CALL:
processLargeArray(VERY LARGE ARRAY)

OBSERVE:

- many loop iterations
- much higher gas usage
- possible out-of-gas failure

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
processLargeArray([1,2,3])

EXPECTED:
6

---------------------------------------------------------

STEP 3:
Call:
totalProcessed()

EXPECTED:
6

---------------------------------------------------------

STEP 4:
Call:
getArraySize([10,20,30,40])

EXPECTED:
4

---------------------------------------------------------

STEP 5:
Pass larger arrays

OBSERVE:
Gas usage increases significantly

---------------------------------------------------------

STEP 6:
Call:
safeProcessing()

WITH:
More than 100 elements

EXPECTED:
Transaction reverts

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Pass empty array

EXPECTED:
Returns 0

---------------------------------------------------------

TEST:
Pass single-element array

EXPECTED:
Handled correctly

---------------------------------------------------------

TEST:
Pass extremely large array

OBSERVE:
Possible:
- out-of-gas
- transaction failure
- scalability issue

=========================================================
IMPORTANT SCALING UNDERSTANDING
=========================================================

CALLDATA IS EFFICIENT,
BUT NOT FREE.

---------------------------------------------------------

LOOP COST STILL EXISTS.

---------------------------------------------------------

EACH ITERATION:
Consumes gas.

=========================================================
WHY LARGE INPUTS ARE DANGEROUS
=========================================================

ATTACKERS CAN SUBMIT:
Very large arrays.

---------------------------------------------------------

RESULT:
- excessive gas usage
- DOS conditions
- unusable functions

=========================================================
CALLDATA VS MEMORY COST
=========================================================

CALLDATA:
Cheaper than memory

---------------------------------------------------------

BUT:
Huge calldata arrays still expensive
when heavily processed.

=========================================================
INPUT LIMITING
=========================================================

THIS IS IMPORTANT:

require(_numbers.length <= 100)

---------------------------------------------------------

WHY?

Prevents:
- gas exhaustion
- scalability failures
- DOS attacks

=========================================================
GAS OBSERVATION
=========================================================

SMALL ARRAYS:
Cheap

---------------------------------------------------------

LARGE ARRAYS:
Expensive

---------------------------------------------------------

VERY LARGE ARRAYS:
Possible out-of-gas failure

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. DOS VIA LARGE INPUTS
---------------------------------------------------------

Most important concern.

Huge arrays may:
- exceed gas limit
- break protocol functions

---------------------------------------------------------
2. UNBOUNDED LOOPS
---------------------------------------------------------

Loops over attacker-controlled input
are dangerous.

---------------------------------------------------------
3. INPUT LIMITING
---------------------------------------------------------

Auditors check for:
- max array size
- pagination
- batching protections

---------------------------------------------------------
4. SCALABILITY FAILURES
---------------------------------------------------------

Functions may work initially,
then fail as usage grows.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker sends massive calldata array.

Loop consumes excessive gas.

Result:
- transaction failure
- DOS condition
- unusable protocol logic

---------------------------------------------------------

REAL-WORLD IMPACT

Many smart contracts became:
- permanently unusable
- too expensive to call

because loops were unbounded.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add pagination support
2. Process only partial array ranges
3. Add max gas-safe batch size

BONUS:
Measure gas for:
10 vs 100 vs 1000 elements

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Calldata arrays are efficient
- Large inputs still consume gas
- Loops scale linearly with size
- Unbounded loops create DOS risks
- Gas exhaustion can break protocols
- Input limiting improves safety
- External inputs are attacker-controlled
- Scalability matters in Solidity
- Pagination prevents large-loop failures
- Auditors inspect scaling behavior carefully

=========================================================
*/