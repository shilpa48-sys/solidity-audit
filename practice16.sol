// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Create local uint variable
CONCEPT: Temporary execution memory
=========================================================

OBJECTIVE

- Learn how local variables work in Solidity
- Understand temporary execution memory
- Learn difference between local variables and storage
- Understand variable lifetime during execution

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Local variables exist ONLY during
function execution.

After function completes:
local variables disappear.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Local variables are NOT stored permanently
on blockchain storage.

They usually live in:
- stack
- memory

---------------------------------------------------------
STATE VARIABLE VS LOCAL VARIABLE
---------------------------------------------------------

STATE VARIABLE:
- stored permanently
- lives in storage
- persists across transactions

LOCAL VARIABLE:
- temporary
- exists only during execution
- disappears after function ends

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Local variables are used for:

- calculations
- temporary values
- loop counters
- intermediate logic
- gas optimization

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is temporary data handled correctly?
- Is storage used unnecessarily?
- Are local variables initialized?
- Can uninitialized variables cause bugs?
- Is memory usage efficient?

=========================================================
*/

contract LocalUintVariablevul {

    uint256 public storedValue;

    function calculateSum(uint256 _a, uint256 _b)
        public
        pure
        returns (uint256)
    {

        /*
            LOCAL VARIABLE

            sum exists ONLY during execution.

            It is NOT stored permanently
            on blockchain storage.
        */
        uint256 sum = _a + _b;

        return sum;
    }

    function storeCalculatedValue(
        uint256 _x,
        uint256 _y
    ) public {

        /*
            TEMPORARY LOCAL VARIABLE

            Used for intermediate computation.
        */
        uint256 result = _x + _y;

        /*
            STORAGE WRITE

            Only this line modifies blockchain state.
        */
        storedValue = result;
    }

    function demonstrateLocalVariable()
        public
        pure
        returns (uint256)
    {

        /*
            Local variable created
        */
        uint256 temp = 100;

        /*
            temp exists only during this function call
        */
        temp = temp + 50;

        return temp;
    }
}

//patched code
contract LocalUintVariable {

    uint256 public storedValue;

    function calculateSum(
        uint256 _a,
        uint256 _b
    )
        public
        pure
        returns (uint256)
    {
        uint256 sum = _a + _b;

        return sum;
    }

    function storeCalculatedValue(
        uint256 _x,
        uint256 _y
    )
        public
    {
        uint256 result = _x + _y;

        storedValue = result;
    }

    function demonstrateLocalVariable()
        public
        pure
        returns (uint256)
    {
        uint256 temp = 100;

        temp = temp + 50;

        return temp;
    }

    /*
        MINI CHALLENGE

        Local multiplication variable.

        Does NOT modify storage.
    */
    function calculateMultiplication(
        uint256 _a,
        uint256 _b
    )
        public
        pure
        returns (uint256)
    {
        uint256 multiplication = _a * _b;

        return multiplication;
    }
}

/*
audit report 

Title:
Unrestricted Storage Modification

Severity:
Low

Reason:
Any user can modify storedValue.

Location:

Contract:
LocalUintVariableVul

Function:
storeCalculatedValue()

Vulnerability Description:

The contract allows any user to update
storedValue.

Although the example is educational,
real-world contracts should restrict
important storage mutations.

Impact:

- Unauthorized state updates
- Unexpected value changes
- Configuration manipulation

Proof of Concept:

1. Deploy contract

2. User A calls:
storeCalculatedValue(5,7)

storedValue = 12

3. User B calls:
storeCalculatedValue(100,200)

storedValue = 300

Root Cause:

- Missing access control
- Unrestricted storage mutation

Recommendation:

Restrict sensitive storage updates
using ownership checks.

Example:

address public owner;

modifier onlyOwner() {
    require(
        msg.sender == owner,
        "Only owner"
    );
    _;
}

Patched Code:

Use LocalUintVariable contract.

*/

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
calculateSum(10, 20)

EVM ACTIONS:

1. _a and _b arrive through calldata
2. Local variable sum created
3. Addition performed
4. sum temporarily stores result
5. Result returned
6. sum destroyed after execution

---------------------------------------------------------

IMPORTANT

sum does NOT persist on blockchain.

---------------------------------------------------------

CALL:
storeCalculatedValue(5, 7)

EVM ACTIONS:

1. Local variable result created
2. result = 12
3. storedValue updated in storage
4. result destroyed after execution
5. storedValue persists permanently

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
calculateSum(10,20)

EXPECTED:
30

---------------------------------------------------------

STEP 3:
Call:
storedValue()

EXPECTED:
0

OBSERVE:
calculateSum did NOT modify storage.

---------------------------------------------------------

STEP 4:
Call:
storeCalculatedValue(5,7)

---------------------------------------------------------

STEP 5:
Call:
storedValue()

EXPECTED:
12

---------------------------------------------------------

STEP 6:
Call:
demonstrateLocalVariable()

EXPECTED:
150

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Use zero values

calculateSum(0,0)

EXPECTED:
0

---------------------------------------------------------

TEST:
Use large uint256 values

EXPECTED:
Solidity ^0.8.x prevents overflow

---------------------------------------------------------

TEST:
Call functions repeatedly

OBSERVE:
Local variables recreated every execution.

=========================================================
IMPORTANT MEMORY UNDERSTANDING
=========================================================

LOCAL VARIABLES ARE TEMPORARY

They exist only during:
single function execution.

---------------------------------------------------------

AFTER FUNCTION ENDS

Local variables are destroyed.

---------------------------------------------------------

VERY IMPORTANT

This does NOT persist:

uint256 temp = 100;

---------------------------------------------------------

THIS PERSISTS:

storedValue = 100;

because storage is modified.

=========================================================
STACK VS STORAGE
=========================================================

LOCAL UINT VARIABLES

Usually stored in:
EVM stack

---------------------------------------------------------

STATE VARIABLES

Stored in:
blockchain storage

---------------------------------------------------------

STACK:
- temporary
- cheap
- fast

STORAGE:
- permanent
- expensive
- persistent

=========================================================
GAS OBSERVATION
=========================================================

LOCAL VARIABLES:
Cheap

---------------------------------------------------------

STORAGE WRITES:
Expensive

---------------------------------------------------------

Reason:
Storage modifies blockchain state permanently.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. UNINITIALIZED VARIABLES
---------------------------------------------------------

Auditors verify:
all local variables initialized properly.

---------------------------------------------------------
2. STORAGE MISUSE
---------------------------------------------------------

Developers sometimes use storage
when temporary variable sufficient.

This wastes gas.

---------------------------------------------------------
3. OVERFLOW RISKS
---------------------------------------------------------

Math on local variables still matters.

Solidity ^0.8.x checks overflow automatically.

---------------------------------------------------------
4. TEMPORARY LOGIC VALIDATION
---------------------------------------------------------

Auditors inspect:
- intermediate calculations
- temporary computation correctness
- execution flow consistency

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Incorrect temporary calculations may:
- manipulate balances
- break reward logic
- corrupt protocol state

---------------------------------------------------------

ANOTHER RISK

Developer may incorrectly assume:
local variable persists after execution.

This creates logic bugs.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Create local multiplication variable
2. Return multiplication result
3. Do NOT modify storage

BONUS:
Compare gas between:
- local calculation
- storage write

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Local variables are temporary
- Local variables do not persist
- State variables use storage
- Local uint variables usually use stack
- Storage writes consume more gas
- Local variables disappear after execution
- Temporary variables useful for calculations
- view/pure functions avoid storage modification
- Solidity ^0.8.x protects from overflow
- Auditors inspect temporary logic carefully

=========================================================
*/