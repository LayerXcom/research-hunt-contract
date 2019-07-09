# @dev Implementation of Research Hunt Contracts.
# @author Jun Katagiri (@akinama)

#
# The purpose of this contract is 
#


#
# Structs
#
struct ResearchRequest:
    owner: address
    uuid: bytes32
    deposit: wei_value
    minimumReward: wei_value
    payout: wei_value
    createdAt: timestamp
    applicationEndAt: timestamp
    submissionEndAt: timestamp
    reports: bytes32[16]
    reporters: address[16]
    reporterApprovements: bool[16]
    reporterRewards: wei_value[16]
    reportersCount: int128
    isCompleted: bool

#
# Events
#
RequestCreated: event({uuid: bytes32, owner: address, deposit: wei_value, minimumReward: wei_value, createdAt: timestamp, applicationEndAt: timestamp, submissionEndAt: timestamp})
Deposited: event({uuid: bytes32, payer: address, weiAmount: wei_value})
AddedMinimumRewardToRequest: event({uuid: bytes32, payer: address, weiAmount: wei_value})
# For Bugs
# Distributed: event({uuid: indexed(bytes32), payees: address[16], weiAmounts: wei_value[16]})
Distributed: event({uuid: bytes32, payee: address, weiAmount: wei_value})
Applied: event({uuid: bytes32, applicant: address})
Approved: event({uuid: bytes32, applicant: address})
Submitted: event({uuid: bytes32, applicant: address, ipfsHash: bytes32})
OwnerTransferred: event({transfer: address})
ApplicationMinimumTimespanChanged: event({applicationMinimumTimespan: timedelta})
SubmissionMinimumTimespanChanged: event({submissionMinimumTimespan: timedelta})

#
# State Variables
#
# The EOA of this contract owner
owner: address

# Deposits
deposits: map(bytes32, map(address, wei_value))

# Research Hunt Struct Mappings
requests: map(bytes32, ResearchRequest)

# Minimum timespan of application
applicationMinimumTimespan: timedelta

# Minimum timespan of submission 
submissionMinimumTimespan: timedelta

#
# Constructor
#
@public
def __init__():
    # Assign msg.sender to owner
    self.owner = msg.sender

    # Application Minimum Timespan is 1 day
    self.applicationMinimumTimespan = 1 * 60
    # self.applicationMinimumTimespan = 1 * 24 * 60 * 60

    # Submission Minimum Timespan is 1 day
    self.submissionMinimumTimespan = 1 * 60
    # self.submissionMinimumTimespan = 1 * 24 * 60 * 60

#
# Research Hunt Functions
#
@public
@payable
def createResearchRequest(_uuid: bytes32, _applicationEndAt: timestamp, _submissionEndAt: timestamp, _minimumReward: wei_value):
    # Guard 1: whether the deposit amount is greater than 0 wei
    assert msg.value > 0

    # Guard 2: whether the timestamps are correctly
    assert block.timestamp + self.applicationMinimumTimespan <= _applicationEndAt

    # Guard 3: whether the timestamps are correctly
    assert _applicationEndAt + self.submissionMinimumTimespan <= _submissionEndAt

    # Guard 4: whether the request ID has already created
    assert self.requests[_uuid].owner == ZERO_ADDRESS

    # Guard 5: whether the minimumReward amount is over 0 wei
    assert _minimumReward >= 0

    # Guard 6: whether the minimumReward amount is less than deposit amount
    assert _minimumReward < msg.value

    # Create research request
    self.requests[_uuid] = ResearchRequest({
        owner: msg.sender,
        uuid: _uuid,
        deposit: msg.value,
        minimumReward: _minimumReward,
        payout: 0,
        createdAt: block.timestamp,
        applicationEndAt: _applicationEndAt,
        submissionEndAt: _submissionEndAt,
        reports: [EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32, EMPTY_BYTES32],
        reporters: [ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
        reporterApprovements: [False, False, False, False, False, False, False, False, False, False, False, False, False, False, False, False],
        reporterRewards: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        reportersCount: 0,
        isCompleted: False })

    # Escrow
    self.deposits[_uuid][msg.sender] = self.deposits[_uuid][msg.sender] + msg.value

    # Event
    log.RequestCreated(
        self.requests[_uuid].uuid,
        self.requests[_uuid].owner,
        self.requests[_uuid].deposit,
        self.requests[_uuid].minimumReward,
        self.requests[_uuid].createdAt,
        self.requests[_uuid].applicationEndAt,
        self.requests[_uuid].submissionEndAt)

@public
def applyResearchReport(_uuid: bytes32):
    # Guard 1: whether this request has been completed
    assert self.requests[_uuid].isCompleted == False

    # Guard 2: whether the timestamps are correctly
    assert block.timestamp < self.requests[_uuid].applicationEndAt

    # Guard 3: whether the request ID has not already created
    assert not self.requests[_uuid].owner == ZERO_ADDRESS

    # Guard 4: whether the request owner is not the sender
    assert not self.requests[_uuid].owner == msg.sender 

    # Sender including flag
    hasApplied: bool = False

    # Get sender index
    for index in range(16):
        if self.requests[_uuid].reporters[index] == msg.sender:
            hasApplied = True
            break

    # Guard 4: whether the sender already applicated
    assert not hasApplied

    # Add reporter
    self.requests[_uuid].reporters[self.requests[_uuid].reportersCount] = msg.sender

    # Increment reportersCount
    self.requests[_uuid].reportersCount = self.requests[_uuid].reportersCount + 1

    # Event
    log.Applied(_uuid, msg.sender)

@public
def approveResearchReport(_uuid: bytes32, _reporter: address):
    # Guard 1: whether this request has been completed
    assert self.requests[_uuid].isCompleted == False

    # Guard 2: whether the timestamps are correctly
    assert block.timestamp < self.requests[_uuid].submissionEndAt

    # Guard 3: whether the request owner is the sender
    assert self.requests[_uuid].owner == msg.sender 

    # Reporter including Flag
    hasApplied: bool = False

    # reporter index
    reporterIndex: int128 = 0

    # Get sender index
    for index in range(16):
        if self.requests[_uuid].reporters[index] == _reporter:
            reporterIndex = index
            hasApplied = True
            break

    # Guard 4: whether reporter has applied
    assert hasApplied

    # Guard 5: Reporter has not Approved
    assert self.requests[_uuid].reporterApprovements[reporterIndex] == False

    self.requests[_uuid].reporterApprovements[reporterIndex] = True

    # Event
    log.Approved(_uuid, _reporter)

@public
def submitResearchReport(_uuid: bytes32, _ipfsHash: bytes32):
    # Guard 1: whether this request has been completed
    assert self.requests[_uuid].isCompleted == False

    # Guard 2: whether the timestamps are correctly
    assert block.timestamp < self.requests[_uuid].submissionEndAt

    # Sender including flag
    hasApplied: bool = False

    # Sender index
    senderIndex: int128 = 0

    # Get sender index
    for index in range(16):
        if self.requests[_uuid].reporters[index] == msg.sender:
            senderIndex = index
            hasApplied = True
            break

    # Guard 3: Sender has Applied
    assert hasApplied

    # Guard 4: Sender has Approved
    assert self.requests[_uuid].reporterApprovements[senderIndex] == True

    # Guard 5: ipfsHash is not blank
    assert not _ipfsHash == EMPTY_BYTES32

    # Add reporter
    self.requests[_uuid].reports[senderIndex] = _ipfsHash

    # Event
    log.Submitted(_uuid, msg.sender, _ipfsHash)

@public
@payable
def addDepositToRequest(_uuid: bytes32):
    # Guard 1: whether this request has been completed
    assert self.requests[_uuid].isCompleted == False

    # Guard 2: whether the deposit amount is greater than 0 wei
    assert msg.value > 0

    # Guard 3: whether the request ID is same as sender address
    assert self.requests[_uuid].owner == msg.sender

    # Update the research request deposited amount
    self.requests[_uuid].deposit = self.requests[_uuid].deposit + msg.value

    # Escrow
    self.deposits[_uuid][msg.sender] = self.deposits[_uuid][msg.sender] + msg.value

    # Event
    log.Deposited(_uuid, msg.sender, self.requests[_uuid].deposit)

@public
def addMinimumRewardToRequest(_uuid: bytes32, _minimumRewardAddition: wei_value):
    # Guard 1: whether this request has been completed
    assert self.requests[_uuid].isCompleted == False

    # Guard 2: whether the minimumRewardAddition amount is greater than 0 wei
    assert _minimumRewardAddition > 0

    # Guard 3: whether the updated minimumReward amount is less than deposit amount
    assert self.requests[_uuid].minimumReward + _minimumRewardAddition < self.requests[_uuid].deposit

    # Guard 4: whether the request ID is same as sender address
    assert self.requests[_uuid].owner == msg.sender

    # Update the research request deposited amount
    self.requests[_uuid].minimumReward = self.requests[_uuid].minimumReward + _minimumRewardAddition

    # Event
    log.AddedMinimumRewardToRequest(_uuid, msg.sender, self.requests[_uuid].minimumReward)


@public
def distribute(_uuid: bytes32, _amounts: wei_value[16]):
    # Guard 1: whether this request has been completed
    assert self.requests[_uuid].isCompleted == False

    # Guard 2: whether the request ID is same as sender address
    assert self.requests[_uuid].owner == msg.sender

    # Total amounts of arguments
    total: wei_value

    # Total reward counts
    totalReportersCount: uint256

    # Verifications
    for index in range(16):
        if self.requests[_uuid].reports[index] == EMPTY_BYTES32:
            continue
        
        totalReportersCount = totalReportersCount + 1

        # Check the sender, approvement and submission
        if _amounts[index] > 0:
            # Guard 3: whether the reporter is not owner
            assert not self.requests[_uuid].reporters[index] == msg.sender
            # Guard 4: whether the reporter has been approved
            assert self.requests[_uuid].reporterApprovements[index]
            # Guard 5: whether the report has been submitted
            assert not self.requests[_uuid].reports[index] == EMPTY_BYTES32

        # Add the amount to total value
        total = total + _amounts[index]

    # Calculate minimum reward per reporter
    minimumRewardPerReporter: wei_value = self.requests[_uuid].minimumReward / totalReportersCount

    # Guard 6: whether the total deposition is same as arguments
    assert self.requests[_uuid].deposit == total + self.requests[_uuid].minimumReward

    # Send the amount to the receiver address
    for index in range(16):
        if self.requests[_uuid].reports[index] == EMPTY_BYTES32:
            continue

        # only if do not send the reward to reports yet
        if self.requests[_uuid].reporterRewards[index] == 0:
            self.requests[_uuid].reporterRewards[index] = _amounts[index] + minimumRewardPerReporter
            send(self.requests[_uuid].reporters[index], self.requests[_uuid].reporterRewards[index])
    
    # Completion
    self.requests[_uuid].isCompleted = True

    reporters: address[16] = self.requests[_uuid].reporters
    rewards: wei_value[16] = self.requests[_uuid].reporterRewards

    for index in range(16):
        if reporters[index] == ZERO_ADDRESS:
            continue
        reporter: address = reporters[index]
        reward: wei_value = rewards[index]
        # Events
        log.Distributed(_uuid, reporter, reward)

    # For Bugs
    # log.Distributed(_uuid, reporters, rewards)

#
# OwnerOnly Functions
#
@public
def transferOwner(_transferTo: address):
    # Guard 1: only owner
    assert self.owner == msg.sender

    # the owner make change to transfer address
    self.owner = _transferTo

    # Event
    log.OwnerTransferred(_transferTo)

@public
def setApplicationMinimumTimespan(_applicationMinimumTimespan: timedelta):
    # Guard 1: only owner
    assert self.owner == msg.sender

    # Guard 2: Positive value
    assert _applicationMinimumTimespan > 0

    # Set application minimum timespan
    self.applicationMinimumTimespan = _applicationMinimumTimespan

    # Event
    log.ApplicationMinimumTimespanChanged(self.applicationMinimumTimespan)

@public
def setSubmissionMinimumTimespan(_submissionMinimumTimespan: timedelta):
    # Guard 1: only owner
    assert self.owner == msg.sender

    # Guard 2: Positive value
    assert _submissionMinimumTimespan > 0

    # Set submission timespan
    self.submissionMinimumTimespan = _submissionMinimumTimespan

    # Event
    log.SubmissionMinimumTimespanChanged(self.submissionMinimumTimespan)