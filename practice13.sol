// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Read state after redeploy
CONCEPT: Deployment resets
=========================================================

OBJECTIVE

- Learn what happens when a contract is redeployed
- Understand that each deployment creates NEW storage
- Learn why previous state does not carry forward
- Understand deployment-level state isolation

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Every contract deployment creates:
- new contract address
- new storage
- new blockchain state

Old deployed contract state remains separate.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Redeploying a contract does NOT:
- update old contract
- preserve old storage
- continue previous state

Instead:
A completely NEW contract instance is created.

---------------------------------------------------------
REAL-WORLD IMPORTANCE
---------------------------------------------------------

Critical for understanding:
- upgradeable contracts
- migrations
- proxy patterns
- state persistence
- deployment architecture

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Does redeployment break state?
- Is migration logic safe?
- Is old state lost?
- Are users aware of deployment resets?
- Are upgrade mechanisms secure?

=========================================================
*/

contract DeploymentResetvul {

    uint256 public number;

    function setNumber(uint256 _number) public {

        number = _number;
    }

    function getNumber() public view returns (uint256) {

        return number;
    }
}

// patched code

contract DeploymentReset {

    uint256 public number;

    address public deployer;

    uint256 public deploymentTimestamp;

    constructor() {
        deployer = msg.sender;
        deploymentTimestamp = block.timestamp;
    }

    modifier onlyDeployer() {
        require(
            msg.sender == deployer,
            "Only deployer"
        );
        _;
    }

    function setNumber(uint256 _number)
        public
        onlyDeployer
    {
        number = _number;
    }

    function getNumber()
        public
        view
        returns (uint256)
    {
        return number;
    }
}

/*
audit report 

Title:
Missing Access Control On State Updates

Severity:
Medium

Reason:
Any user can modify the contract state.

Location:

Contract:
DeploymentResetVul

Function:
setNumber()

Vulnerability Description:

The contract allows any user to update
the number state variable.

Because blockchain state persists,
unauthorized users can overwrite values.

Impact:

- State manipulation
- Configuration tampering
- Incorrect protocol behavior
- Unauthorized updates

Proof of Concept:

1. Deploy contract

2. User A calls:
setNumber(100)

3. User B calls:
setNumber(999999)

4. Contract state changes.

Root Cause:

- Missing ownership mechanism
- Missing authorization checks

Recommendation:

Store deployer information during
deployment and restrict updates
to authorized users.

Example:

constructor() {
    deployer = msg.sender;
    deploymentTimestamp = block.timestamp;
}

modifier onlyDeployer() {
    require(
        msg.sender == deployer,
        "Only deployer"
    );
    _;
}

Patched Code:

Use DeploymentReset contract.

*/

/*
=========================================================
EXECUTION FLOW
=========================================================

FIRST DEPLOYMENT

Contract Address:
0xAAA...

INITIAL STATE:

number = 0

---------------------------------------------------------

CALL:
setNumber(500)

STATE NOW:

number = 500

Stored permanently in FIRST contract.

---------------------------------------------------------

REDEPLOY CONTRACT

New Contract Address:
0xBBB...

IMPORTANT:
This is a COMPLETELY NEW contract.

---------------------------------------------------------

NEW CONTRACT STATE

number = 0

Reason:
Fresh deployment = fresh storage

---------------------------------------------------------

IMPORTANT OBSERVATION

Old contract still exists:

0xAAA...
number = 500

New contract:

0xBBB...
number = 0

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

EXPECTED:
number() => 0

---------------------------------------------------------

STEP 2:
Call:
setNumber(123)

EXPECTED:
number() => 123

---------------------------------------------------------

STEP 3:
Deploy SAME contract AGAIN

IMPORTANT:
New contract instance appears below in Remix.

---------------------------------------------------------

STEP 4:
Check number()

EXPECTED:
0

OBSERVE:
Previous state NOT preserved.

---------------------------------------------------------

STEP 5:
Compare BOTH deployed contracts

OLD CONTRACT:
number => 123

NEW CONTRACT:
number => 0

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Deploy contract multiple times

EXPECTED:
Each deployment starts fresh

---------------------------------------------------------

TEST:
Modify first deployment only

EXPECTED:
Second deployment unaffected

---------------------------------------------------------

TEST:
Modify second deployment

EXPECTED:
First deployment remains unchanged

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

CONTRACT STORAGE IS LINKED TO:

Contract Address

---------------------------------------------------------

Each deployment:
- gets unique address
- gets independent storage
- maintains separate state

---------------------------------------------------------

VERY IMPORTANT

Blockchain stores state PER CONTRACT ADDRESS.

Example:

0xAAA... => number = 500

0xBBB... => number = 0

=========================================================
WHY THIS MATTERS
=========================================================

Many beginners wrongly assume:

"Redeploy updates existing contract"

This is FALSE.

Redeploying creates:
an entirely new contract instance.

---------------------------------------------------------

Real protocols use:
- proxy contracts
- upgradeable patterns
- migrations

to preserve state across upgrades.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. STATE LOSS RISKS
---------------------------------------------------------

Redeployment may:
- lose balances
- lose ownership
- lose user funds
- reset protocol configuration

---------------------------------------------------------
2. MIGRATION SAFETY
---------------------------------------------------------

Auditors inspect:
- safe state migration
- upgrade handling
- storage compatibility

---------------------------------------------------------
3. USER CONFUSION
---------------------------------------------------------

Users may interact with:
- old deployment accidentally
- obsolete contracts
- outdated state

---------------------------------------------------------
4. FAKE CONTRACT RISKS
---------------------------------------------------------

Attackers may deploy:
fake versions of protocols.

Users may confuse:
- old contract
- upgraded contract
- malicious clone

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker redeploys fake protocol
with identical code/UI.

Users interact with wrong contract.

Result:
- stolen funds
- fake balances
- phishing attacks

---------------------------------------------------------

ANOTHER RISK

Improper upgrade process may:
- reset critical storage
- erase balances
- destroy protocol state

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Store deployer address
2. Store deployment timestamp

HINT:

Use:
block.timestamp

and

msg.sender

inside constructor.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Each deployment creates new contract address
- Storage belongs to specific contract instance
- Redeployment does NOT preserve state
- Old contracts remain on blockchain
- State persistence is contract-specific
- Deployments are isolated from each other
- Upgrade systems require special architecture
- Migration safety is critical
- Users may confuse deployments
- Auditors inspect upgrade/deployment risks

=========================================================
*/