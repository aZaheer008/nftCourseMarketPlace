// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract CourseMarketPlace {
    enum State {
        Purchased,
        Activated,
        Deactivated
    }

    struct Course {
        uint id;
        uint price;
        bytes32 proof;
        address owner;
        State state;
    }

    bool public isStopped = false;

    // mapping of courseHash to Course data
    mapping(bytes32 => Course) private ownedCourses;

    // mapping of courseID to courseHash
    mapping(uint => bytes32) private ownedCourseHash;

    //number of all courses + id of the course
    uint private totalOwnedCourses;

    address payable private owner;

    constructor () {
        setContractOwner(msg.sender);
    }

    modifier onlyOwner() {
        if (msg.sender != getContractOwner()) {
            revert("only owner has an accesss!");
        }
        _;
    }

    modifier onlyWhenNotStopped {
        require(!isStopped);
        _;
    }

    modifier onlyWhenStopped {
        require(isStopped);
        _;
    }

    receive() external payable {}

    function emergencyWithdraw ()
        external
        onlyWhenStopped
        onlyOwner
    {
        (bool success,) = owner.call{value : address(this).balance}("");
        require(success,"Transfer failed.");
    }

    function selfDestruct ()
        external
        onlyWhenStopped
        onlyOwner
    {
        selfdestruct(owner);
    }

    function withdraw (uint amount)
        external
        onlyOwner
    {
        (bool success,) = owner.call{value : amount}("");
        require(success,"Transfer failed.");
    }

    function stopContract() 
        external
        onlyOwner
    {
        isStopped = true;
    }

    function resumeContract() 
        external
        onlyOwner
    {
        isStopped = false;
    }

    function purchaseCourse (
        bytes16 courseId,
        bytes32 proof
    )
        external
        payable
        onlyWhenNotStopped
    {
        bytes32 courseHash = keccak256(abi.encodePacked(courseId, msg.sender));

        if (hasCourseOwnership(courseHash)){
            revert("Course has already a Owner!");
        }

        uint id = totalOwnedCourses++;
        ownedCourseHash[id] = courseHash;
        ownedCourses[courseHash] = Course({
            id : id,
            price : msg.value,
            proof : proof,
            state : State.Purchased,
            owner : msg.sender
        });
    }

    function repurchaseCourse(bytes32 courseHash)
        external
        payable
        onlyWhenNotStopped
    {
        if (!isCourseCreated(courseHash)) {
            revert("Course Is not Created Yet!");
        }

        if (!hasCourseOwnership(courseHash)) {
            revert("Sender is not course Owner");
        }

        Course storage course = ownedCourses[courseHash];

        if (course.state != State.Deactivated) {
            revert("Course has Invalid State");
        }

        course.state = State.Purchased;
        course.price = msg.value;

    }

    function activateCourse(
        bytes32 courseHash
    )
        external
        onlyWhenNotStopped
        onlyOwner
    {
        if (!isCourseCreated(courseHash)) {
            revert("Course is not Created!");
        }

        Course storage course = ownedCourses[courseHash];

        if ( course.state != State.Purchased ){
            revert("Course has Invalid State");
        }
        course.state = State.Activated;
    }

        function deactivateCourse(
        bytes32 courseHash
    )
        external
        onlyWhenNotStopped
        onlyOwner
    {
        if (!isCourseCreated(courseHash)) {
            revert("Course is not Created!");
        }

        Course storage course = ownedCourses[courseHash];

        if ( course.state != State.Purchased ){
            revert("Course has Invalid State");
        }

        (bool success,) = course.owner.call{ value : course.price}("");
        require(success, "Transfer failed!");

        course.state = State.Deactivated;
        course.price = 0;
    }

    function transferOwnership (address newOwner)
        external
        onlyOwner
    {
        setContractOwner(newOwner);
    }

    function getCourseCount()
        external
        view
        returns (uint)
        {
            return totalOwnedCourses;
        }

    function getCourseHashAtIndex(uint index) 
        external
        view 
        returns (bytes32)
        {
            return ownedCourseHash[index];
        }

    function getCourseByHash(bytes32 courseHash)
        external
        view
        returns (Course memory)
        {
            return ownedCourses[courseHash];
        }

    function getContractOwner()
        public
        view
        returns (address)
        {
            return owner;
        }

    function setContractOwner(address newOwner) 
        private 
        {
            owner = payable(newOwner);
        }

    function isCourseCreated(bytes32 courseHash)
        private
        view
        returns (bool)
    {
        return ownedCourses[courseHash].owner != 0x0000000000000000000000000000000000000000;
    }
    
    function hasCourseOwnership (bytes32 courseHash)
        private
        view
        returns (bool)
        {
            return ownedCourses[courseHash].owner == msg.sender;
        }
}