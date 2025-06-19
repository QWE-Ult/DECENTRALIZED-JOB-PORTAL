// SPDX-License-Identifier: MIT
 pragma solidity >=0.8.12;  // Declaring the compiler version 
contract JobPortal {   
     address public admin;
     
     
     
 constructor() {             
        admin = msg.sender;  
    }
    modifier onlyAdmin() {
        require(msg.sender == admin, "You are not the admin"); 
        _;
    }
    struct Applicant {
        string name;
        string location;
        uint age;
        uint rating; // Assuming ratings are out of 10
        uint applicantID;
        bool isSkilled;
    }
    Applicant[] private applicants;
    struct Job {
        uint jobID;
        string jobTitle;
    }
        Job[] private jobs;
    // Mapping to store applicant ratings
    mapping(uint => uint8) private applicantRatings;

    struct Application {
        uint applicantID;
        uint jobID;
        string additionalInfo; // Additional information if needed
    }
      Application[] private applications;
    // Function to add applicant by admin
    function addNewApplicant(string memory _name, string memory _location, uint _age, uint _applicantID, bool _isSkilled) public onlyAdmin {
        applicants.push(Applicant({
            name: _name,
            location: _location,
            age: _age,
            applicantID: _applicantID,
            isSkilled: _isSkilled,
            rating: 0 // Initialize rating to 0
        }));
    }
    // Function to get applicant's details
    function getApplicantDetails(uint _applicantID) public view returns (Applicant memory) {
         require(_applicantID < applicants.length, "Applicant ID does not exist");
        return applicants[_applicantID];
    }

    // Function to add new job by admin
    function addNewJob(uint _jobID, string memory _jobTitle) public onlyAdmin {
jobs.push(Job(_jobID,_jobTitle))  ;
  }
    // Function to get job details
    function getJobDetails(uint _jobID) public view returns (Job memory) {
        require(_jobID < jobs.length, "Job ID does not exist");
        return jobs[_jobID];
    }
    // Function for admin to give rating to an applicant
    function giveRating(uint _applicantID, uint8 _rating) public onlyAdmin {
        require(_rating <= 10, "Maximum rating is 10");
        applicantRatings[_applicantID] = _rating;
    }
    // Function to fetch applicant rating
    function fetchApplicantRating(uint _applicantID) public view returns (uint) 
{
        return applicantRatings[_applicantID];
    }
    // Function for applicants to apply for a job
    function applyForJob(uint _applicantID, uint _jobID, string memory _additionalInfo) public {
        applications.push(Application({
            applicantID: _applicantID,
            jobID: _jobID,
            additionalInfo: _additionalInfo
        }));
    }
    // Function to fetch application type how good the worker is  based on applicant's rating so that other knows to give job accordingly
    function getApplicantType(uint _applicantID) public view returns (string memory) {
        uint8 rating = applicantRatings[_applicantID];
        if (rating >= 8) {
            return "Pro";
        } else if (rating >= 6) {
            return "Experienced";
        } else if (rating >= 4) {
            return "Good";
        } else {
            return "Newbie"
            ;
        }
    }
 }