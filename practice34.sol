// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Pass nested calldata array
CONCEPT: Complex input handling
=========================================================

OBJECTIVE

- Learn how nested calldata arrays work
- Understand complex ABI input decoding
- Learn handling of multi-dimensional arrays
- Understand gas/scaling risks of nested structures

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Nested arrays are arrays inside arrays.

Example:

[
    [1,2],
    [3,4],
    [5,6]
]

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Nested calldata arrays:
- are read-only
- are externally supplied
- require ABI decoding
- can become expensive at scale

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Complex nested structures appear in:

- batch DeFi operations
- governance systems
- Merkle proofs
- routing paths
- advanced multicalls

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Nested arrays used in:

- Uniswap swap paths
- batch execution systems
- matrix-style computations
- grouped transactions
- multi-user operations

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Input complexity
- Nested loop gas risks
- ABI decoding correctness
- DOS vulnerabilities
- Scalability failures

=========================================================
*/

contract NestedCalldataArray {

    /*
        STORAGE VARIABLE

        Permanent blockchain state.
    */
    uint256 public totalSum;

    /*
    =====================================================
    READ NESTED CALLDATA ARRAY
    =====================================================
    */

    function readNestedArray(
        uint256[][] calldata _matrix
    )
        external
        pure
        returns (uint256[][] memory)
    {

        /*
            Returning nested calldata array.

            Solidity ABI-encodes nested structure.
        */
        return _matrix;
    }

    /*
    =====================================================
    CALCULATE TOTAL SUM
    =====================================================
    */

    function calculateNestedSum(
        uint256[][] calldata _matrix
    )
        external
        pure
        returns (uint256)
    {

        uint256 total = 0;

        /*
            OUTER LOOP

            Iterates outer arrays.
        */
        for (uint256 i = 0; i < _matrix.length; i++) {

            /*
                INNER LOOP

                Iterates inner arrays.
            */
            for (
                uint256 j = 0;
                j < _matrix[i].length;
                j++
            ) {

                total += _matrix[i][j];
            }
        }

        return total;
    }

    /*
    =====================================================
    SAVE COMPUTED TOTAL
    =====================================================
    */

    function processAndStore(
        uint256[][] calldata _matrix
    )
        external
    {

        uint256 total = 0;

        /*
            Nested loop processing.
        */
        for (uint256 i = 0; i < _matrix.length; i++) {

            for (
                uint256 j = 0;
                j < _matrix[i].length;
                j++
            ) {

                total += _matrix[i][j];
            }
        }

        /*
            Store result permanently.
        */
        totalSum = total;
    }

    /*
    =====================================================
    GET DIMENSIONS
    =====================================================
    */

    function getOuterLength(
        uint256[][] calldata _matrix
    )
        external
        pure
        returns (uint256)
    {

        return _matrix.length;
    }
    //patched code
    function findLargestNumber(
    uint256[][] calldata _matrix
)
    external
    pure
    returns (uint256)
{
    require(
        _matrix.length > 0,
        "Empty matrix"
    );

    require(
        _matrix.length <= 50,
        "Outer array too large"
    );

    uint256 largest = 0;
    bool foundValue = false;

    for (uint256 i = 0; i < _matrix.length; i++) {

        require(
            _matrix[i].length <= 50,
            "Inner array too large"
        );

        for (
            uint256 j = 0;
            j < _matrix[i].length;
            j++
        ) {

            if (
                !foundValue ||
                _matrix[i][j] > largest
            ) {
                largest = _matrix[i][j];
                foundValue = true;
            }
        }
    }

    require(
        foundValue,
        "No values found"
    );

    return largest;
}
}
/*
Audit Report
Finding 1: Unbounded Outer Array Length
Severity

Medium

Issue

The contract accepts:

uint256[][] calldata _matrix

without restricting:

_matrix.length
Impact

An attacker can submit a very large outer array causing excessive gas consumption.

Recommendation

Add a limit:

require(
    _matrix.length <= 50,
    "Outer array too large"
);
Finding 2: Unbounded Inner Array Length
Severity

Medium

Issue

Each inner array can grow without restriction:

_matrix[i].length
Impact

Nested loops may consume excessive gas and become uncallable.

Recommendation

Validate every inner array:

require(
    _matrix[i].length <= 50,
    "Inner array too large"
);
Finding 3: DOS Risk from Nested Loops
Severity

Medium

Issue

The contract performs:

O(n × m)

operations.

Gas consumption grows rapidly as nested array sizes increase.

Impact
Out-of-gas failures
Denial of service
Poor scalability
Recommendation

Apply size limits and consider pagination for very large datasets.

Result

The patch:

Finds the largest number in the nested calldata array
Rejects outer arrays larger than 50
Rejects inner arrays larger than 50
Reduces DOS and scalability risks
Preserves the original educational structure of the contract with minimal changes
*/

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:

calculateNestedSum(
[
    [1,2],
    [3,4]
]
)

=========================================================

EVM ACTIONS

1. Nested array arrives in calldata
2. Solidity ABI-decodes structure
3. Outer loop processes rows
4. Inner loop processes elements
5. Total computed
6. Result returned
7. Calldata discarded

---------------------------------------------------------

CALCULATION:

1 + 2 + 3 + 4 = 10

---------------------------------------------------------

RESULT:
10

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
readNestedArray()

INPUT:

[
    [1,2],
    [3,4]
]

EXPECTED:
Same nested array returned

---------------------------------------------------------

STEP 3:
Call:
calculateNestedSum()

INPUT:

[
    [1,2],
    [3,4]
]

EXPECTED:
10

---------------------------------------------------------

STEP 4:
Call:
processAndStore()

INPUT:

[
    [5,5],
    [10]
]

---------------------------------------------------------

STEP 5:
Call:
totalSum()

EXPECTED:
20

---------------------------------------------------------

STEP 6:
Call:
getOuterLength()

INPUT:

[
    [1],
    [2],
    [3]
]

EXPECTED:
3

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Empty outer array

INPUT:
[]

EXPECTED:
0

---------------------------------------------------------

TEST:
Empty inner arrays

INPUT:
[
    [],
    []
]

EXPECTED:
0

---------------------------------------------------------

TEST:
Very large nested arrays

OBSERVE:
Extremely high gas usage

=========================================================
IMPORTANT NESTED ARRAY UNDERSTANDING
=========================================================

TYPE:

uint256[][] calldata

---------------------------------------------------------

MEANS:

Array of uint256 arrays.

---------------------------------------------------------

STRUCTURE:

[
    [row1],
    [row2],
    [row3]
]

=========================================================
NESTED LOOP RISK
=========================================================

THIS IS IMPORTANT:

Nested loops scale badly.

---------------------------------------------------------

OUTER LOOP:
N iterations

INNER LOOP:
M iterations

---------------------------------------------------------

TOTAL OPERATIONS:
N × M

=========================================================
CALLDATA IMMUTABILITY
=========================================================

Nested calldata arrays are:
READ-ONLY.

---------------------------------------------------------

THIS FAILS:

_matrix[0][0] = 999;

---------------------------------------------------------

Reason:
calldata is immutable.

=========================================================
ABI DECODING COMPLEXITY
=========================================================

Nested arrays require:
complex ABI decoding.

---------------------------------------------------------

LARGER STRUCTURES:
More decoding cost.

=========================================================
GAS OBSERVATION
=========================================================

SMALL NESTED ARRAYS:
Cheap

---------------------------------------------------------

LARGE NESTED ARRAYS:
Very expensive

---------------------------------------------------------

NESTED LOOPS:
Multiply gas consumption rapidly

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. DOS VIA NESTED LOOPS
---------------------------------------------------------

Most important risk.

Nested attacker-controlled arrays
can exhaust gas quickly.

---------------------------------------------------------
2. UNBOUNDED INPUTS
---------------------------------------------------------

Large nested structures may:
- exceed block gas limit
- break protocol usability

---------------------------------------------------------
3. ABI DECODING RISKS
---------------------------------------------------------

Complex nested structures
increase decoding complexity.

---------------------------------------------------------
4. SCALABILITY FAILURES
---------------------------------------------------------

Functions may become unusable
as input size grows.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker submits huge nested arrays.

Nested loops explode computational cost.

Result:
- out-of-gas
- DOS condition
- protocol unusability

---------------------------------------------------------

REAL-WORLD ISSUE

Improper batch-processing logic
has caused scalability failures
in production contracts.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Find largest number
inside nested array

2. Reject arrays larger than:
- outer length > 50
- inner length > 50

BONUS:
Add pagination support.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Nested arrays contain arrays inside arrays
- Nested calldata arrays are read-only
- ABI decoding handles complex structures
- Nested loops scale poorly
- Large nested inputs increase gas heavily
- Unbounded loops create DOS risks
- External inputs are attacker-controlled
- Scalability is critical in Solidity
- Complex structures require careful auditing
- Auditors inspect nested-loop behavior carefully

=========================================================
*/