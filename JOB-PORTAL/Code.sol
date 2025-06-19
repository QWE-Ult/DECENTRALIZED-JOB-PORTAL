// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

contract JobPortal {
    address public admin;

    // CHANGES: initialize admin and emit transfer event
    constructor() {
        admin = msg.sender;
        emit AdminTransferred(address(0), admin); // CHANGES
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not the admin");
        _;
    }

    // CHANGES: restrict functions to applicant owner
    modifier onlyApplicant(uint _applicantID) {
        require(applicantAddresses[_applicantID] == msg.sender, "Not your applicant profile");
        _;
    }

    struct Applicant {
        string name;
        string location;
        uint age;
        uint rating;
        bool isSkilled;
        bool exists; // CHANGES: validation flag
    }
    Applicant[] private applicants;
    mapping(uint => address) public applicantAddresses; // CHANGES: link applicant to address

    struct Job {
        uint jobID;
        string title;
        bool exists; // CHANGES: validation flag
    }
    Job[] private jobs;

    struct Application {
        uint applicantID;
        uint jobID;
        string additionalInfo;
        bool exists; // CHANGES: validation flag
    }
    Application[] private applications;

    // CHANGES: event definitions
    event ApplicantAdded(uint indexed applicantID, address indexed owner);
    event ApplicantUpdated(uint indexed applicantID);
    event ApplicantRemoved(uint indexed applicantID);
    event JobAdded(uint indexed jobID);
    event JobUpdated(uint indexed jobID);
    event JobRemoved(uint indexed jobID);
    event ApplicationSubmitted(uint indexed applicantID, uint indexed jobID);
    event ApplicationWithdrawn(uint indexed applicantID, uint indexed jobID);
    event RatingGiven(uint indexed applicantID, uint8 rating);
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);

    /*** CHANGES: ADMIN FUNCTIONS ***/
    function transferAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Zero address");
        emit AdminTransferred(admin, _newAdmin); // CHANGES
        admin = _newAdmin;
    }

    function addNewApplicant(
        string calldata _name,
        string calldata _location,
        uint _age,
        bool _isSkilled
    ) external onlyAdmin returns (uint) { // UPDATED: removed applicantID argument
        uint applicantID = applicants.length;
        applicants.push(Applicant({
            name: _name,
            location: _location,
            age: _age,
            rating: 0,
            isSkilled: _isSkilled,
            exists: true // CHANGES
        }));
        applicantAddresses[applicantID] = msg.sender; // CHANGES
        emit ApplicantAdded(applicantID, msg.sender); // CHANGES
        return applicantID;
    }

    function updateApplicant(
        uint _applicantID,
        string calldata _name,
        string calldata _location,
        uint _age,
        bool _isSkilled
    ) external onlyAdmin {
        require(applicants[_applicantID].exists, "No such applicant");
        Applicant storage a = applicants[_applicantID];
        a.name = _name;
        a.location = _location;
        a.age = _age;
        a.isSkilled = _isSkilled;
        emit ApplicantUpdated(_applicantID); // CHANGES
    }

    function removeApplicant(uint _applicantID) external onlyAdmin {
        require(applicants[_applicantID].exists, "No such applicant");
        delete applicants[_applicantID]; // UPDATED: soft-delete
        delete applicantAddresses[_applicantID]; // CHANGES
        emit ApplicantRemoved(_applicantID); // CHANGES
    }

    function addNewJob(uint _jobID, string calldata _title) external onlyAdmin {
        jobs.push(Job({ jobID: _jobID, title: _title, exists: true })); // UPDATED
        emit JobAdded(_jobID); // CHANGES
    }

    function updateJob(uint _index, uint _jobID, string calldata _title) external onlyAdmin {
        require(jobs[_index].exists, "No such job");
        Job storage j = jobs[_index];
        j.jobID = _jobID;
        j.title = _title;
        emit JobUpdated(_jobID); // CHANGES
    }

    function removeJob(uint _index) external onlyAdmin {
        require(jobs[_index].exists, "No such job");
        uint removedID = jobs[_index].jobID;
        delete jobs[_index]; // UPDATED
        emit JobRemoved(removedID); // CHANGES
    }

    function giveRating(uint _applicantID, uint8 _rating) external onlyAdmin {
        require(applicants[_applicantID].exists, "No such applicant");
        require(_rating <= 10, "Max 10");
        applicants[_applicantID].rating = _rating;
        emit RatingGiven(_applicantID, _rating); // CHANGES
    }

    /*** CHANGES: APPLICANT FUNCTIONS ***/
    function applyForJob(
        uint _applicantID,
        uint _jobIndex,
        string calldata _info
    ) external onlyApplicant(_applicantID) {
        require(applicants[_applicantID].exists, "Invalid applicant");
        require(jobs[_jobIndex].exists, "Invalid job");
        applications.push(Application({
            applicantID: _applicantID,
            jobID: jobs[_jobIndex].jobID,
            additionalInfo: _info,
            exists: true
        }));
        emit ApplicationSubmitted(_applicantID, jobs[_jobIndex].jobID); // CHANGES
    }

    function withdrawApplication(uint _applicantID, uint _appIndex) external onlyApplicant(_applicantID) {
        Application storage app = applications[_appIndex];
        require(app.exists, "No such application");
        require(app.applicantID == _applicantID, "Not your application");
        app.exists = false;
        emit ApplicationWithdrawn(_applicantID, app.jobID); // CHANGES
    }

    function updateMyProfile(
        uint _applicantID,
        string calldata _name,
        string calldata _location,
        uint _age,
        bool _isSkilled
    ) external onlyApplicant(_applicantID) {
        Applicant storage a = applicants[_applicantID];
        a.name = _name;
        a.location = _location;
        a.age = _age;
        a.isSkilled = _isSkilled;
        emit ApplicantUpdated(_applicantID); // CHANGES
    }

    /*** UPDATED: VIEW FUNCTIONS ***/
    function getApplicant(uint _applicantID) external view returns (Applicant memory) {
        require(applicants[_applicantID].exists, "No such applicant");
        return applicants[_applicantID];
    }

    function getJob(uint _index) external view returns (Job memory) {
        require(jobs[_index].exists, "No such job");
        return jobs[_index];
    }

    function getApplication(uint _index) external view returns (Application memory) {
        require(applications[_index].exists, "No such application");
        return applications[_index];
    }

    function listAllApplicants() external view returns (Applicant[] memory) { // CHANGES
        return applicants;
    }

    function listAllJobs() external view returns (Job[] memory) { // CHANGES
        return jobs;
    }

    function applicationsByApplicant(uint _applicantID) external view returns (Application[] memory) { // CHANGES
        uint count;
        for (uint i; i < applications.length; i++) {
            if (applications[i].exists && applications[i].applicantID == _applicantID) count++;
        }
        Application[] memory result = new Application[](count);
        uint j;
        for (uint i; i < applications.length; i++) {
            if (applications[i].exists && applications[i].applicantID == _applicantID) {
                result[j++] = applications[i];
            }
        }
        return result;
    }

    function applicationsByJob(uint _jobID) external view returns (Application[] memory) { // CHANGES
        uint count;
        for (uint i; i < applications.length; i++) {
            if (applications[i].exists && applications[i].jobID == _jobID) count++;
        }
        Application[] memory result = new Application[](count);
        uint j;
        for (uint i; i < applications.length; i++) {
            if (applications[i].exists && applications[i].jobID == _jobID) {
                result[j++] = applications[i];
            }
        }
        return result;
    }

    function getApplicantType(uint _applicantID) external view returns (string memory) {
        uint r = applicants[_applicantID].rating;
        if (r >= 8) return "Pro";
        if (r >= 6) return "Experienced";
        if (r >= 4) return "Good";
        return "Newbie";
    }
}
