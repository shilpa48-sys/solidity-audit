// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Read calldata values
CONCEPT: Input handling
=========================================================

OBJECTIVE

- Learn how calldata inputs are read
- Understand external input handling
- Learn how Solidity processes function arguments
- Understand calldata lifecycle and behavior

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

When external functions are called:

Input data arrives through calldata.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Calldata is:
- temporary
- read-only
- efficient
- external-input storage area

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Every external interaction uses calldata.

Understanding calldata is critical for:
- smart contract auditing
- gas optimization
- security analysis
- ABI decoding understanding

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Calldata used in:

- token transfers
- DeFi swaps
- governance voting
- NFT minting
- routers
- multicall systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Are inputs validated?
- Are attacker-controlled values sanitized?
- Is calldata used efficiently?
- Are loops bounded safely?
- Can malicious input break logic?

=========================================================
*/

contract ReadCalldataValues {

    /*
        STATE VARIABLES

        Persist permanently.
    */
    uint256 public lastNumber;

    string public lastMessage;

    function readUint(
        uint256 _number
    )
        external
        pure
        returns (uint256)
    {

        /*
            _number arrives through calldata.

            Solidity reads value directly
            from external transaction data.
        */

        return _number;
    }

    function readMultipleInputs(
        uint256 _age,
        bool _active,
        address _user
    )
        external
        pure
        returns (
            uint256,
            bool,
            address
        )
    {

        /*
            Multiple calldata inputs handled.

            All values come from:
            external transaction calldata.
        */

        return (
            _age,
            _active,
            _user
        );
    }

    function readString(
        string calldata _message
    )
        external
        pure
        returns (string memory)
    {

        /*
            Dynamic type stored in calldata.

            calldata keyword required
            for external dynamic data.
        */

        return _message;
    }

    function saveInput(
        uint256 _number,
        string calldata _message
    )
        external
    {

        /*
            Read calldata values
            and store permanently.
        */

        lastNumber = _number;

        lastMessage = _message;
    }
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

Because no maximum array length is enforced, an attacker can supply excessively large arrays that significantly increase gas consumption.

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
readUint(50)

EVM ACTIONS:

1. External transaction sent
2. Input encoded into calldata
3. Solidity decodes calldata
4. _number loaded
5. Value returned
6. Calldata discarded after execution

---------------------------------------------------------

IMPORTANT

No permanent storage modified.

=========================================================

CALL:
readString("Hello")

EVM ACTIONS:

1. Dynamic string stored in calldata
2. _message references calldata directly
3. String returned
4. Calldata cleared after execution

=========================================================

CALL:
saveInput(100, "Blockchain")

EVM ACTIONS:

1. Inputs arrive through calldata
2. Values decoded
3. Data copied into storage
4. Blockchain state updated permanently

---------------------------------------------------------

FINAL STORAGE:

lastNumber = 100

lastMessage = "Blockchain"

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
readUint(123)

EXPECTED:
123

---------------------------------------------------------

STEP 3:
Call:
readMultipleInputs(
25,
true,
<your_address>
)

EXPECTED:
25, true, address

---------------------------------------------------------

STEP 4:
Call:
readString("Solidity")

EXPECTED:
"Solidity"

---------------------------------------------------------

STEP 5:
Call:
saveInput(999, "Audit")

---------------------------------------------------------

STEP 6:
Call:
lastNumber()

EXPECTED:
999

---------------------------------------------------------

STEP 7:
Call:
lastMessage()

EXPECTED:
"Audit"

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Pass zero values

EXPECTED:
Handled correctly

---------------------------------------------------------

TEST:
Pass empty string

EXPECTED:
Handled correctly

---------------------------------------------------------

TEST:
Pass huge string

OBSERVE:
Higher gas consumption

---------------------------------------------------------

TEST:
Pass invalid assumptions

Example:
unexpected address values

OBSERVE:
Need validation in real protocols

=========================================================
IMPORTANT CALLDATA UNDERSTANDING
=========================================================

CALLDATA STORES:

External transaction input data.

---------------------------------------------------------

CALLDATA EXISTS ONLY:
during function execution.

---------------------------------------------------------

AFTER EXECUTION:
Calldata disappears automatically.

=========================================================
STATIC VS DYNAMIC TYPES
=========================================================

---------------------------------------------------------
STATIC TYPES
---------------------------------------------------------

Examples:
- uint256
- bool
- address

Efficient fixed-size encoding.

---------------------------------------------------------
DYNAMIC TYPES
---------------------------------------------------------

Examples:
- string
- bytes
- arrays

Require explicit calldata/memory location.

=========================================================
CALLDATA IS READ-ONLY
=========================================================

You cannot modify calldata directly.

---------------------------------------------------------

THIS FAILS:

_message = "Hack";

---------------------------------------------------------

Reason:
calldata is immutable.

=========================================================
GAS OBSERVATION
=========================================================

READING CALLDATA:
Cheap

---------------------------------------------------------

COPYING TO STORAGE:
Expensive

---------------------------------------------------------

LARGE DYNAMIC INPUTS:
Increase gas usage

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. ATTACKER-CONTROLLED INPUTS
---------------------------------------------------------

ALL calldata inputs are untrusted.

Never assume:
- correctness
- safety
- validation

---------------------------------------------------------
2. DOS RISK
---------------------------------------------------------

Huge calldata inputs may:
- consume excessive gas
- break loops
- create DOS conditions

---------------------------------------------------------
3. INPUT VALIDATION
---------------------------------------------------------

Auditors inspect:
- bounds checking
- address validation
- access control
- logic assumptions

---------------------------------------------------------
4. ABI DECODING RISKS
---------------------------------------------------------

Improper input decoding may:
- corrupt logic
- break execution
- create vulnerabilities

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker sends:
- massive arrays
- huge strings
- malicious values

Result:
- gas exhaustion
- broken logic
- DOS condition

---------------------------------------------------------

ANOTHER RISK

Developer trusts calldata blindly.

Attacker manipulates protocol behavior.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Accept calldata uint array
2. Read every value using loop
3. Return largest number

BONUS:
Reject arrays larger than 100 elements.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Calldata stores external inputs
- Calldata is temporary
- Calldata is read-only
- External inputs are attacker-controlled
- Dynamic types require data location
- Storage persists permanently
- Large calldata increases gas
- Input validation is critical
- ABI decoding powers function calls
- Auditors inspect calldata handling carefully

=========================================================
*/