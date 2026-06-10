// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Use storage reference variable
CONCEPT: Direct storage pointer
=========================================================

OBJECTIVE

- Learn how storage reference variables work
- Understand direct pointers to storage
- Learn difference between storage and memory
- Understand how modifying storage references
  directly changes blockchain state

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

A storage reference variable points directly
to an existing storage location.

Example:

User storage user = users[id];

This does NOT create copy.

Instead:
user becomes POINTER to storage.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Modifying storage reference:

user.age = 50;

directly updates blockchain storage.

---------------------------------------------------------
STORAGE VS MEMORY
---------------------------------------------------------

STORAGE:
- permanent
- expensive
- modifies blockchain state
- acts like pointer/reference

MEMORY:
- temporary copy
- disappears after execution
- modifying memory does NOT update storage

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Storage references are heavily used in:

- DeFi protocols
- staking systems
- NFT marketplaces
- governance contracts
- user profile systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Are storage references intentional?
- Is accidental mutation possible?
- Are references pointing correctly?
- Is storage corruption possible?
- Is memory/storage confusion present?

=========================================================
*/

contract StorageReferencevul {

    struct User {

        uint256 age;

        bool active;
    }

    mapping(address => User) public users;

    function createUser(uint256 _age) public {

        users[msg.sender] = User(_age, true);
    }

    function updateAge(uint256 _newAge) public {

        /*
            STORAGE REFERENCE VARIABLE

            This creates POINTER to actual storage.

            user is NOT copy.

            user directly references:
            users[msg.sender]
        */
        User storage user = users[msg.sender];

        /*
            DIRECT STORAGE MUTATION

            Since user points to storage,
            this updates blockchain state directly.
        */
        user.age = _newAge;
    }

    function deactivateUser() public {

        /*
            Another storage reference example
        */
        User storage user = users[msg.sender];

        user.active = false;
    }

    function getMyData()
        public
        view
        returns (uint256, bool)
    {
        User storage user = users[msg.sender];

        return (user.age, user.active);
    }
}

//patched code
contract StorageReference {

    struct User {
        uint256 age;
        bool active;
    }

    mapping(address => User) public users;

    function createUser(uint256 _age) public {
        users[msg.sender] = User(_age, true);
    }

    function updateAge(uint256 _newAge) public {

        User storage user = users[msg.sender];

        user.age = _newAge;
    }

    function deactivateUser() public {

        User storage user = users[msg.sender];

        user.active = false;
    }

    /*
        MINI CHALLENGE

        MEMORY COPY EXAMPLE

        Changes made here DO NOT affect storage.
    */
    function testMemoryCopy()
        public
        view
        returns(uint256,bool)
    {
        User memory user = users[msg.sender];

        user.age = 999;
        user.active = false;

        return (user.age, user.active);
    }

    function getMyData()
        public
        view
        returns (uint256, bool)
    {
        User storage user = users[msg.sender];

        return (user.age, user.active);
    }
}

/*
audit report content

Title:
Storage Reference Can Cause Direct State Mutation

Severity:
Low

Reason:
Storage references modify blockchain state directly.

Location:

Contract:
StorageReferenceVul

Functions:
updateAge()
deactivateUser()

Vulnerability Description:

The contract uses storage reference variables.

Example:

User storage user = users[msg.sender];

This creates a direct pointer to storage.

Any modification through the reference
immediately changes blockchain state.

Developers may mistakenly assume a copy
is being modified.

Impact:

- Accidental state changes
- Unexpected side effects
- Corrupted protocol data
- Memory/storage confusion bugs

Proof of Concept:

1. createUser(25)

2. updateAge(99)

3. Storage immediately changes

4. getMyData()

Result:
99, true

Root Cause:

- Direct storage references
- Developer misunderstanding of
  storage vs memory semantics

Recommendation:

Use memory copies when modifications
should not affect blockchain storage.

Example:

User memory user = users[msg.sender];

Patched Code:

Use StorageReference contract.

*/

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

users[msg.sender]:

age = 0
active = false

---------------------------------------------------------

CALL:
createUser(25)

RESULT:

users[msg.sender]:
age = 25
active = true

---------------------------------------------------------

CALL:
updateAge(40)

EVM ACTIONS:

1. Mapping storage slot located
2. Storage reference created
3. user points directly to storage
4. user.age updated
5. Blockchain state mutated

---------------------------------------------------------

FINAL STATE

users[msg.sender]:
age = 40
active = true

---------------------------------------------------------

IMPORTANT

No copy created.

Storage reference directly modifies storage.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
createUser(25)

---------------------------------------------------------

STEP 3:
Call:
getMyData()

EXPECTED:
25, true

---------------------------------------------------------

STEP 4:
Call:
updateAge(99)

---------------------------------------------------------

STEP 5:
Call:
getMyData()

EXPECTED:
99, true

OBSERVE:
Storage updated permanently.

---------------------------------------------------------

STEP 6:
Call:
deactivateUser()

EXPECTED:
99, false

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Update before createUser()

EXPECTED:
Works on default struct values

---------------------------------------------------------

TEST:
Repeated updates

EXPECTED:
Latest storage state persists

---------------------------------------------------------

TEST:
Different Remix accounts

EXPECTED:
Each address has isolated struct storage

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

THIS LINE:

User storage user = users[msg.sender];

creates STORAGE POINTER.

---------------------------------------------------------

VERY IMPORTANT

This is NOT copy:

User memory user = users[msg.sender];

would create temporary copy instead.

---------------------------------------------------------

STORAGE REFERENCE

Changes affect blockchain storage immediately.

---------------------------------------------------------

MEMORY COPY

Changes affect temporary copy only.

=========================================================
STORAGE VS MEMORY EXAMPLE
=========================================================

---------------------------------------------------------
STORAGE
---------------------------------------------------------

User storage user = users[msg.sender];

user.age = 50;

RESULT:
Blockchain storage updated.

---------------------------------------------------------
MEMORY
---------------------------------------------------------

User memory user = users[msg.sender];

user.age = 50;

RESULT:
Only temporary copy changes.

Original storage unchanged.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. ACCIDENTAL STORAGE MUTATION
---------------------------------------------------------

Developers may accidentally modify
real storage when expecting copy.

This causes unintended state changes.

---------------------------------------------------------
2. MEMORY/STORAGE CONFUSION
---------------------------------------------------------

Very common Solidity bug source.

Auditors carefully inspect:
- reference types
- assignment behavior
- mutation side effects

---------------------------------------------------------
3. UNEXPECTED SIDE EFFECTS
---------------------------------------------------------

Changing storage references may:
- alter protocol state unexpectedly
- corrupt accounting
- bypass assumptions

---------------------------------------------------------
4. GAS CONSIDERATIONS
---------------------------------------------------------

Storage writes are expensive.

Unnecessary mutations waste gas.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Improper storage references may allow:
- accidental balance updates
- corrupted staking records
- unintended ownership changes

---------------------------------------------------------

REAL-WORLD RISK

Many Solidity bugs happen because:
developers expect copy
but receive storage reference instead.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add function using MEMORY copy
2. Change memory values
3. Observe storage remains unchanged

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- storage creates direct reference/pointer
- Storage references mutate blockchain state
- memory creates temporary copy
- Storage persists permanently
- Storage writes consume gas
- Reference types behave differently
- Memory/storage confusion causes bugs
- Structs inside mappings commonly use storage refs
- Storage references can create side effects
- Auditors inspect pointer behavior carefully

=========================================================
*/