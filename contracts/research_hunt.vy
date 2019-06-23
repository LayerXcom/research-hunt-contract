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
    distributionAt: timestamp
    refundableAt: timestamp
    reports: bytes32[16]
    reporters: address[16]
    reporterApprovements: bool[16]
    reporterRewards: wei_value[16]
    reportersCount: int128
    isCompleted: bool

#
# Events
#
# RequestCreated: event({uuid: indexed(bytes32), owner: indexed(address), weiAmount: wei_value, createdAt: timestamp, applicationEndAt: timestamp, submissionEndAt: timestamp, distributionAt: timestamp, refundableAt: timestamp})
RequestCreated: event({uuid: bytes32, owner: address, deposit: wei_value, minimumReward: wei_value, createdAt: timestamp, applicationEndAt: timestamp, submissionEndAt: timestamp, distributionAt: timestamp, refundableAt: timestamp})
Deposited: event({uuid: indexed(bytes32), payer: indexed(address), weiAmount: wei_value})
AddedMinimumRewardToRequest: event({uuid: indexed(bytes32), payer: indexed(address), weiAmount: wei_value})
Distributed: event({uuid: indexed(bytes32), payee: indexed(address), weiAmount: wei_value})
Refunded: event({uuid: indexed(bytes32), payee: indexed(address), weiAmount: wei_value})
Applied: event({uuid: indexed(bytes32), applicant: indexed(address)})
Approved: event({uuid: indexed(bytes32), applicant: indexed(address)})
Submitted: event({uuid: indexed(bytes32), applicant: indexed(address), ipfsHash: bytes32})
OwnerTransferred: event({transfer: address})
ApplicationMinimumTimespanChanged: event({applicationMinimumTimespan: timedelta})
SubmissionMinimumTimespanChanged: event({submissionMinimumTimespan: timedelta})
RefundableTimespanChanged: event({refundableTimespan: timedelta})
DistributionEndTimespanChanged: event({distributionEndTimespan: timedelta})

#
# Constants
#
# 14 days
# DEFAULT_REFUNDABLE_TIMESPAN: constant(uint256(sec)) = 1209600

#
# State Variables
#
# The EOA of this contract owner
owner: address

# Deposits
deposits: map(bytes32, map(address, wei_value))

# Research Hunt Struct Mappings
requests: map(bytes32, ResearchRequest)

# Distribution timespan
distributionEndTimespan: timedelta

# Refundable timespan
refundableTimespan: timedelta

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

    # DistributionTimespan is 3 Days
    self.distributionEndTimespan = 5 * 60
    # self.distributionEndTimespan = 3 * 24 * 60 * 60

    # RefundableTimespan is 14 Days
    self.refundableTimespan = 1 * 60
    # self.refundableTimespan = 14 * 24 * 60 * 60

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
        distributionAt: _submissionEndAt + self.distributionEndTimespan,
        refundableAt: _submissionEndAt + self.refundableTimespan,
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
        self.requests[_uuid].submissionEndAt,
        self.requests[_uuid].distributionAt,
        self.requests[_uuid].refundableAt)

@public
def applyResearchReport(_uuid: bytes32):
    # Guard 1: whether the timestamps are correctly
    assert block.timestamp < self.requests[_uuid].applicationEndAt

    # Guard 2: whether the request ID has not already created
    assert not self.requests[_uuid].owner == ZERO_ADDRESS

    # Guard 3: whether the request owner is not the sender
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
    # Guard 1: whether the timestamps are correctly
    assert block.timestamp < self.requests[_uuid].submissionEndAt

    # Guard 2: whether the request owner is the sender
    assert self.requests[_uuid].owner == msg.sender 

    # Approvement Flag
    hasApproved: bool = False

    # Get sender index
    for index in range(16):
        if self.requests[_uuid].reporters[index] == _reporter:
            self.requests[_uuid].reporterApprovements[index] = True
            hasApproved = True
            break

    # Guard 4: whether the sender has been approved
    assert hasApproved

    # Event
    log.Approved(_uuid, _reporter)

@public
def submitResearchReport(_uuid: bytes32, _ipfsHash: bytes32):
    # Guard 1: whether the timestamps are correctly
    assert self.requests[_uuid].applicationEndAt < block.timestamp and block.timestamp < self.requests[_uuid].submissionEndAt

    # Sender including flag
    hasSubmitted: bool = False

    # Sender index
    senderIndex: int128 = 0

    # Get sender index
    for index in range(16):
        if self.requests[_uuid].reporters[index] == msg.sender:
            senderIndex = index
            hasSubmitted = True
            break
    
    # Guard 2: Sender has submitted
    assert hasSubmitted 

    # Add reporter
    self.requests[_uuid].reports[senderIndex] = _ipfsHash

    # Event
    log.Submitted(_uuid, msg.sender, _ipfsHash)

@public
@payable
def addDepositToRequest(_uuid: bytes32):
    # Guard 1: whether the deposit amount is greater than 0 wei
    assert msg.value > 0

    # Guard 2: whether the request ID is same as sender address
    assert self.requests[_uuid].owner == msg.sender

    # Update the research request deposited amount
    self.requests[_uuid].deposit = self.requests[_uuid].deposit + msg.value

    # Escrow
    self.deposits[_uuid][msg.sender] = self.deposits[_uuid][msg.sender] + msg.value

    # Event
    log.Deposited(_uuid, msg.sender, self.requests[_uuid].deposit)

@public
@payable
def addMinimumRewardToRequest(_uuid: bytes32, _minimumRewardAddition: wei_value):
    # Guard 1: whether the minimumRewardAddition amount is greater than 0 wei
    assert _minimumRewardAddition > 0

    # Guard 2: whether the updated minimumReward amount is less than deposit amount
    assert self.requests[_uuid].minimumReward + _minimumRewardAddition < self.requests[_uuid].deposit

    # Guard 3: whether the request ID is same as sender address
    assert self.requests[_uuid].owner == msg.sender

    # Update the research request deposited amount
    self.requests[_uuid].minimumReward = self.requests[_uuid].minimumReward + _minimumRewardAddition

    # Event
    log.AddedMinimumRewardToRequest(_uuid, msg.sender, self.requests[_uuid].minimumReward)

@public
@payable
def distribute(_uuid: bytes32, _receiver: address, _amount: wei_value):
    # Guard 1: whether the distributing amount is greater than 0 wei
    assert _amount > 0

    # Guard 2: whether the address is not sender address
    assert not msg.sender == _receiver

    # Guard 3: whether the current timestamp has gone over the submission end at
    assert block.timestamp > self.requests[_uuid].submissionEndAt

    # Guard 4: whether the request ID is same as sender address
    assert self.requests[_uuid].owner == msg.sender

    # Guard 5: whether the deposited amount is greater than or equal the distributed
    assert _amount <= self.requests[_uuid].deposit - self.requests[_uuid].payout

    # Guard 6: whether the total deposited amount is greater than or equal the distributed
    assert _amount <= self.deposits[_uuid][msg.sender]

    # Update the deposits amount
    self.deposits[_uuid][msg.sender] = self.deposits[_uuid][msg.sender] - _amount

    # Update the research request paid out amount
    self.requests[_uuid].payout = self.requests[_uuid].payout + _amount

    # Update the research request completed flag
    self.requests[_uuid].isCompleted = True

    # Send the amount to the receiver address
    send(_receiver, _amount)

    # Event
    log.Distributed(_uuid, _receiver, self.requests[_uuid].deposit)

@public
@payable
def refund(_uuid: bytes32):
    # Guard 1: whether the address is not sender address
    assert msg.sender == self.requests[_uuid].owner

    # Guard 2: whether the current timestamp has gone over the submission end at
    assert self.requests[_uuid].refundableAt <= block.timestamp
 
    # Culculate remain wei_value
    amount: wei_value = self.requests[_uuid].deposit - self.requests[_uuid].payout

    # Update the deposits amount
    self.deposits[_uuid][msg.sender] = self.deposits[_uuid][msg.sender] - amount

    # Update the research request payout
    self.requests[_uuid].payout = self.requests[_uuid].payout + amount

    # Update the research request completed flag
    self.requests[_uuid].isCompleted = True

    # Send the amount to the receiver address
    send(msg.sender, amount)

    # Event
    log.Refunded(_uuid, msg.sender, amount)

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

@public
def setDistributionEndTimespan(_distributionEndTimespan: timedelta):
    # Guard 1: only owner
    assert self.owner == msg.sender

    # Guard 2: Positive value
    assert _distributionEndTimespan > 0

    # Set distribution timespan
    self.distributionEndTimespan = _distributionEndTimespan

    # Event
    log.DistributionEndTimespanChanged(self.distributionEndTimespan)

@public
def setRefundableTimespan(_refundableTimespan: timedelta):
    # Guard 1: only owner
    assert self.owner == msg.sender

    # Guard 2: Positive value
    assert _refundableTimespan > 0

    # Set refundable timespan
    self.refundableTimespan = _refundableTimespan

    # Event
    log.RefundableTimespanChanged(self.refundableTimespan)
