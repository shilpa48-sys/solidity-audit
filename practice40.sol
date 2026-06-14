// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Add nested if conditions
CONCEPT: Branching logic
=========================================================

OBJECTIVE

- Learn nested if-condition execution
- Understand branching logic in Solidity
- Learn multi-level decision flow
- Understand auditor-style path tracing

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Nested if statements create:
multiple execution branches.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Different inputs cause:
different execution paths.

Auditors must trace:
EVERY possible branch.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Many vulnerabilities hide inside:
rare execution branches.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Nested branching appears in:

- access control
- DeFi fee systems
- staking rewards
- liquidation logic
- governance rules
- NFT minting limits

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- unreachable branches
- incorrect conditions
- missing else logic
- privilege escalation
- inconsistent state updates

=========================================================
*/

contract NestedIfConditions {

    /*
        OWNER ADDRESS
    */
    address public owner;

    /*
        USER SCORES
    */
    mapping(address => uint256) public scores;

    /*
        USER LEVELS
    */
    mapping(address => string) public levels;

    /*
        CONSTRUCTOR
    */
    constructor() {

        owner = msg.sender;
    }

    /*
    =====================================================
    NESTED IF LOGIC
    =====================================================
    */

    function evaluateUser(
        uint256 _score,
        bool _premium
    )
        external
    {

        /*
            FIRST BRANCH

            Check minimum score.
        */
        if (_score >= 50) {

            /*
                SECOND BRANCH

                Check premium status.
            */
            if (_premium == true) {

                /*
                    THIRD BRANCH

                    Check elite score.
                */
                if (_score >= 90) {

                    levels[msg.sender] =
                        "Elite Premium";

                } else {

                    levels[msg.sender] =
                        "Premium";
                }

            } else {

                /*
                    NON-PREMIUM USER
                */
                levels[msg.sender] =
                    "Standard";
            }

            /*
                SAVE SCORE
            */
            scores[msg.sender] = _score;

        } else {

            /*
                LOW SCORE BRANCH
            */
            levels[msg.sender] =
                "Rejected";
        }
    }

    /*
    =====================================================
    OWNER BONUS FUNCTION
    =====================================================
    */

    function ownerBonus(
        address _user
    )
        external
    {

        /*
            FIRST CONDITION:
            owner check
        */
        if (msg.sender == owner) {

            /*
                SECOND CONDITION:
                user must exist
            */
            if (scores[_user] > 0) {

                /*
                    THIRD CONDITION:
                    high score required
                */
                if (scores[_user] >= 80) {

                    scores[_user] += 20;
                }
            }
        }
    }
}
//patched code
contract NestedIfConditionsPatched {

    address public owner;

    bool public paused;

    mapping(address => uint256) public scores;

    mapping(address => string) public levels;

    mapping(address => bool) public blacklist;

    mapping(address => bool) public vipUsers;

    constructor() {
        owner = msg.sender;
    }

    function setPaused(bool _status)
        external
    {
        require(
            msg.sender == owner,
            "Not owner"
        );

        paused = _status;
    }

    function setBlacklist(
        address _user,
        bool _status
    )
        external
    {
        require(
            msg.sender == owner,
            "Not owner"
        );

        blacklist[_user] = _status;
    }

    function setVIP(
        address _user,
        bool _status
    )
        external
    {
        require(
            msg.sender == owner,
            "Not owner"
        );

        vipUsers[_user] = _status;
    }

    function evaluateUser(
        uint256 _score,
        bool _premium
    )
        external
    {
        /*
            PAUSED BRANCH
        */
        if (paused) {

            levels[msg.sender] =
                "Paused";

            return;
        }

        /*
            BLACKLIST BRANCH
        */
        if (blacklist[msg.sender]) {

            levels[msg.sender] =
                "Blacklisted";

            return;
        }

        /*
            VIP BRANCH
        */
        if (vipUsers[msg.sender]) {

            levels[msg.sender] =
                "VIP";

            scores[msg.sender] =
                _score;

            return;
        }

        /*
            ORIGINAL LOGIC
        */
        if (_score >= 50) {

            if (_premium) {

                if (_score >= 90) {

                    levels[msg.sender] =
                        "Elite Premium";

                } else {

                    levels[msg.sender] =
                        "Premium";
                }

            } else {

                levels[msg.sender] =
                    "Standard";
            }

            scores[msg.sender] =
                _score;

        } else {

            levels[msg.sender] =
                "Rejected";
        }
    }

    function ownerBonus(
        address _user
    )
        external
    {
        if (msg.sender == owner) {

            if (!blacklist[_user]) {

                if (scores[_user] >= 80) {

                    scores[_user] += 20;
                }
            }
        }
    }
}
/*
Report
Title:

Missing Blacklist and Pause Validation in Nested Branching Logic

Severity:

Low

Reason:

The contract relies heavily on nested if conditions to determine user eligibility and score updates. The Mini Challenge requires additional branching for:

Blacklisted users
VIP users
Paused contract state

Without these branches, restricted users can still access functionality and the contract cannot be administratively paused during emergencies.

Location:

Contract: NestedIfConditionsPatched
Functions: evaluateUser() and ownerBonus()

Vulnerability Description:

The original implementation evaluates users based only on score and premium status.

Missing security branches may allow:

Blacklisted users to receive levels
User evaluations while protocol is paused
VIP users receiving the same treatment as regular users

This creates incomplete branching logic and fails to enforce intended protocol rules.

Impact:

Possible consequences include:

Unauthorized participation by blacklisted users
Inability to stop evaluations during emergencies
Incorrect user classification
Inconsistent business logic execution

Although educational, this pattern becomes dangerous when reused in production authorization systems.

Proof of Concept
Scenario 1 — Blacklisted User
User added to blacklist
User calls:
evaluateUser(95, true)
User receives:
Elite Premium

Expected:

Blacklisted

or execution blocked.

Scenario 2 — Contract Paused
Owner pauses contract
User calls:
evaluateUser(95, true)
Evaluation succeeds

Expected:

Execution should stop.

Scenario 3 — VIP User
VIP user submits:
evaluateUser(75, false)
User receives:
Standard

Expected:

VIP
Root Cause

The original branching tree does not account for additional business-rule states.

Original execution tree:

Score >= 50?
    |
    +-- Premium?
           |
           +-- Elite?

Missing branches:

Paused?
Blacklisted?
VIP?
Recommendation

Introduce early validation branches before score processing:

Paused check
Blacklist check
VIP branch
Existing premium logic

This simplifies auditing and prevents unauthorized execution paths.
Patched Code Explanation

The patched version completes the Mini Challenge by:

Adding blacklist logic
Adding VIP user logic
Adding paused-contract logic
Using early-return branching to reduce nesting
Preserving the original educational structure
Making execution paths easier to audit and trace

This demonstrates how auditors simplify complex nested conditions into clearly separated execution branches.
*/

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
evaluateUser(95, true)

=========================================================

STEP 1:
if (_score >= 50)

CHECK:
95 >= 50

RESULT:
true

---------------------------------------------------------

STEP 2:
if (_premium == true)

CHECK:
true == true

RESULT:
true

---------------------------------------------------------

STEP 3:
if (_score >= 90)

CHECK:
95 >= 90

RESULT:
true

---------------------------------------------------------

EXECUTION PATH:

Elite Premium branch

---------------------------------------------------------

FINAL STORAGE:

levels[user] = "Elite Premium"

scores[user] = 95

=========================================================
ANOTHER TRACE
=========================================================

CALL:
evaluateUser(60, false)

---------------------------------------------------------

STEP 1:
60 >= 50

RESULT:
true

---------------------------------------------------------

STEP 2:
premium == true

RESULT:
false

---------------------------------------------------------

EXECUTION PATH:

Standard branch

---------------------------------------------------------

FINAL STATE:

levels[user] = "Standard"

=========================================================
LOW SCORE TRACE
=========================================================

CALL:
evaluateUser(20, true)

---------------------------------------------------------

STEP 1:
20 >= 50

RESULT:
false

---------------------------------------------------------

EXECUTION JUMPS TO:

else branch

---------------------------------------------------------

FINAL STATE:

levels[user] = "Rejected"

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
evaluateUser(95, true)

---------------------------------------------------------

STEP 3:
Call:
levels(your_address)

EXPECTED:
"Elite Premium"

---------------------------------------------------------

STEP 4:
Call:
evaluateUser(60, false)

EXPECTED:
"Standard"

---------------------------------------------------------

STEP 5:
Call:
evaluateUser(20, true)

EXPECTED:
"Rejected"

---------------------------------------------------------

STEP 6:
Call:
ownerBonus(your_address)

FROM:
owner account

---------------------------------------------------------

STEP 7:
Call:
scores(your_address)

OBSERVE:
Bonus added if conditions met

=========================================================
IMPORTANT BRANCHING UNDERSTANDING
=========================================================

Nested if statements create:
multiple execution paths.

---------------------------------------------------------

Every branch may:
- modify state differently
- skip logic
- create vulnerabilities

=========================================================
EXECUTION TREE
=========================================================

Example:

IF score >= 50
    |
    +-- premium?
          |
          +-- elite?
          |
          +-- standard

---------------------------------------------------------

Auditors mentally trace:
ALL branches.

=========================================================
WHY NESTED LOGIC IS DANGEROUS
=========================================================

Complex branching may cause:

- forgotten edge cases
- inconsistent updates
- bypass conditions
- privilege escalation

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. MISSING ELSE BRANCH
---------------------------------------------------------

State may remain unchanged unexpectedly.

---------------------------------------------------------
2. UNREACHABLE CODE
---------------------------------------------------------

Incorrect condition order
may block execution paths.

---------------------------------------------------------
3. INCONSISTENT STATE
---------------------------------------------------------

Different branches may:
update state differently.

---------------------------------------------------------
4. PRIVILEGE ESCALATION
---------------------------------------------------------

Incorrect nested checks
may bypass authorization.

=========================================================
GAS OBSERVATION
=========================================================

More branching:
More execution complexity.

---------------------------------------------------------

Deeper nesting:
Harder auditing.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Can attacker reach hidden branch?
- Are all paths validated?
- Does every path maintain invariants?
- Are branches mutually exclusive?
- Is state updated consistently?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Developer forgets else branch.

Attacker triggers unexpected path.

Result:
stale or corrupted state.

---------------------------------------------------------

ANOTHER RISK

Incorrect nested access-control logic
may allow unauthorized execution.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Every condition
2. Every branch
3. Every state update
4. Every revert path
5. Every skipped operation

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add blacklist logic
2. Add VIP user branch
3. Add paused-contract branch

Then manually trace:
ALL execution paths.

BONUS:
Convert nested ifs into:
require() + early returns.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Nested if creates multiple execution paths
- Branching changes execution flow
- Auditors must trace every branch
- Missing branches create vulnerabilities
- Complex logic increases audit difficulty
- State updates differ across branches
- Incorrect nesting may bypass checks
- Edge cases matter heavily
- Branch analysis is critical in auditing
- Execution tracing is essential for security reviews

=========================================================
*/