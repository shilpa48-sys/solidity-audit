// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Delete storage variable
CONCEPT: Reset behavior
=========================================================

OBJECTIVE

- Understand delete on storage variables
- Learn default reset values
- Observe how storage is cleared
- Understand delete behavior on arrays
- Think like auditor about reset logic

=========================================================
*/

contract DeleteStorageVariableVul {

    uint256 public number = 100;
    bool public isActive = true;

    address public owner =
        0x1111111111111111111111111111111111111111;

    string public message = "Blockchain";

    uint256[] public numbers;

    constructor() {
        numbers.push(10);
        numbers.push(20);
        numbers.push(30);
    }

    /*
    =====================================================
    DELETE UINT
    =====================================================
    */

    function deleteNumber() public {
        delete number;
    }

    /*
    =====================================================
    DELETE BOOL
    =====================================================
    */

    function deleteBool() public {
        delete isActive;
    }

    /*
    =====================================================
    DELETE ADDRESS
    =====================================================
    */

    function deleteOwner() public {
        delete owner;
    }

    /*
    =====================================================
    DELETE STRING
    =====================================================
    */

    function deleteMessage() public {
        delete message;
    }

    /*
    =====================================================
    DELETE ENTIRE ARRAY
    =====================================================
    */

    function deleteArray() public {
        delete numbers;
    }

    /*
    =====================================================
    DELETE ARRAY INDEX
    =====================================================

    VULNERABILITY:
    Creates array holes.
    Example:
    [10,20,30]
    delete index 1
    =>
    [10,0,30]
    */

    function deleteArrayIndex(uint256 _index) public {
        delete numbers[_index];
    }

    /*
    =====================================================
    VIEW ARRAY
    =====================================================
    */

    function getArray()
        public
        view
        returns (uint256[] memory)
    {
        return numbers;
    }
}

// patched code

contract DeleteStorageVariable {

    uint256 public number = 100;
    bool public isActive = true;

    address public owner;

    string public message = "Blockchain";

    uint256[] public numbers;

    constructor() {
        owner = msg.sender;

        numbers.push(10);
        numbers.push(20);
        numbers.push(30);
    }

    function deleteNumber() public {
        delete number;
    }

    function deleteBool() public {
        delete isActive;
    }

    function deleteOwner() public {
        require(
            msg.sender == owner,
            "Only owner can reset owner"
        );

        delete owner;
    }

    function deleteMessage() public {
        delete message;
    }

    function deleteArray() public {
        delete numbers;
    }

    /*
    =====================================================
    MINI CHALLENGE FIX
    =====================================================

    BEFORE:
    [10,20,30]

    Remove index 1

    AFTER:
    [10,30]

    No holes remain.
    */

    function removeArrayIndex(uint256 _index) public {
        require(
            _index < numbers.length,
            "Invalid index"
        );

        numbers[_index] =
            numbers[numbers.length - 1];

        numbers.pop();
    }

    function getArray()
        public
        view
        returns (uint256[] memory)
    {
        return numbers;
    }
}

/*
audit report content

Title:
Array Hole Creation Through delete Array Index

Severity:
Medium

Reason:
delete array[index] resets value but does not
reduce array length, creating sparse arrays.

Location:

Contract:
DeleteStorageVariableVul

Function:
deleteArrayIndex(uint256)

Vulnerability Description:

The contract removes array elements using:

delete numbers[_index];

This only resets the value to zero while
keeping the original array length.

Example:

Before:
[10,20,30]

After deleting index 1:
[10,0,30]

The array now contains a hole.

Sparse arrays often lead to:
- broken loops
- accounting mistakes
- reward calculation errors
- unexpected zero values

Impact:

An attacker or user can create many empty
slots in the array, causing incorrect
application behavior and faulty accounting.

Proof of Concept:

1. Deploy DeleteStorageVariableVul

2. Call:
getArray()

Result:
[10,20,30]

3. Call:
deleteArrayIndex(1)

4. Call:
getArray()

Result:
[10,0,30]

5. Array length remains 3.

Root Cause:

- Improper use of delete on array elements
- Failure to shrink array after removal

Recommendation:

Use swap-and-pop removal.

Example:

numbers[_index] =
    numbers[numbers.length - 1];

numbers.pop();

This removes the element and shrinks
the array length.

Patched Code:

The DeleteStorageVariable contract
implements swap-and-pop removal through:

function removeArrayIndex(uint256 _index)
public
{
    require(
        _index < numbers.length,
        "Invalid index"
    );

    numbers[_index] =
        numbers[numbers.length - 1];

    numbers.pop();
}

*/