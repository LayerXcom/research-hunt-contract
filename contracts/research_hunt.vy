# @dev Implementation of Research Hunt Contracts.
# @author Jun Katagiri (@akinama)

#
# Structs
#
struct ResearchRequest:
    owner: address
    deposit: wei_value
    payout: wei_value
    createdAt: timestamp
    applicationEndAt: timestamp
    submissionEndAt: timestamp
    distributionAt: timestamp
    refundableAt: timestamp
    isCompleted: bool

#
# Events
#
RequestCreated: event({owner: indexed(address), weiAmount: wei_value, createdAt: timestamp, applicationEndAt: timestamp, submissionEndAt: timestamp, distributionAt: timestamp, refundableAt: timestamp})
Deposited: event({payee: indexed(address), weiAmount: wei_value})
Withdrawn: event({payee: indexed(address), weiAmount: wei_value})
OwnerTransferred: event({transfer: address})
ApplicationMinimumTimespanChanged: event({applicationMinimumTimespan: timedelta})
SubmissionMinimumTimespanChanged: event({submissionMinimumTimespan: timedelta})
RefundableTimespanChanged: event({refundableTimespan: timedelta})
DistributionEndTimespanChanged: event({distributionTimespan: timedelta})

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
deposits: map(uint256, map(address, wei_value))

# Research Hunt Struct Mappings
requests: map(uint256, ResearchRequest)

# Distribution timespan
distributionTimespan: timedelta

# Refundable timespan
refundableTimespan: timedelta

# Minimum timespan of application
applicationMinimumTimespan: timedelta

# Minimum timespan of application
submissionMinimumTimespan: timedelta

#
# Constructor
#
@public
def __init__():
    # Assign msg.sender to owner
    self.owner = msg.sender

    # Application Minimum Timespan is 1 day
    self.applicationMinimumTimespan = 1 * 24 * 60 * 60

    # Submission Minimum Timespan is 1 day
    self.submissionMinimumTimespan = 1 * 24 * 60 * 60

    # DistributionTimespan is 3 Days
    self.distributionTimespan = 3 * 24 * 60 * 60

    # RefundableTimespan is 14 Days
    self.refundableTimespan = 14 * 24 * 60 * 60

#
# Research Hunt Functions
#
@public
@payable
def createResearchRequest(_requestId: uint256, _applicationEndAt: timestamp, _submissionEndAt: timestamp):
    # Guard 1: whether the deposit amount is greater than 0 wei
    assert msg.value > 0

    # Guard 2: whether the timestamps are correctly
    assert block.timestamp <= _applicationEndAt - self.applicationMinimumTimespan

    # Guard 3: whether the timestamps are correctly
    assert _applicationEndAt <= _submissionEndAt - self.submissionMinimumTimespan

    # Guard 4: whether the request ID has already created
    assert self.requests[_requestId].owner == ZERO_ADDRESS

    # Create research request
    self.requests[_requestId] = ResearchRequest({
        owner: msg.sender,
        deposit: msg.value,
        payout: 0,
        createdAt: block.timestamp,
        applicationEndAt: _applicationEndAt,
        submissionEndAt: _submissionEndAt,
        distributionAt: _submissionEndAt + self.distributionTimespan,
        refundableAt: block.timestamp + self.refundableTimespan,
        isCompleted: False
    })

    # Escrow
    self.deposits[_requestId][msg.sender] = self.deposits[_requestId][msg.sender] + msg.value

    # Event
    log.RequestCreated(
        self.requests[_requestId].owner,
        self.requests[_requestId].deposit,
        self.requests[_requestId].createdAt,
        self.requests[_requestId].applicationEndAt,
        self.requests[_requestId].submissionEndAt,
        self.requests[_requestId].distributionAt,
        self.requests[_requestId].refundableAt)

@public
@payable
def addDepositToRequest(_requestId: uint256):
    # Guard 1: whether the deposit amount is greater than 0 wei
    assert msg.value > 0

    # Guard 2: whether the request ID is same as sender address
    assert self.requests[_requestId].owner == msg.sender

    # Update the research request deposited amount
    self.requests[_requestId].deposit = self.requests[_requestId].deposit + msg.value

    # Escrow
    self.deposits[_requestId][msg.sender] = self.deposits[_requestId][msg.sender] + msg.value

    # Event
    log.Deposited(msg.sender, self.requests[_requestId].deposit)

@public
@payable
def distribute(_requestId: uint256, _receiver: address, _amount: wei_value):
    # Guard 1: whether the distributing amount is greater than 0 wei
    assert _amount > 0

    # Guard 2: whether the address is not sender address
    assert not msg.sender == _receiver

    # Guard 3: whether the current timestamp has gone over the submission end at
    assert block.timestamp > self.requests[_requestId].submissionEndAt

    # Guard 4: whether the request ID is same as sender address
    assert self.requests[_requestId].owner == msg.sender

    # Guard 5: whether the deposited amount is greater than or equal the distributed
    assert _amount <= self.requests[_requestId].deposit - self.requests[_requestId].payout

    # Guard 6: whether the total deposited amount is greater than or equal the distributed
    assert _amount <= self.deposits[_requestId][msg.sender]

    # Update the deposits amount
    self.deposits[_requestId][msg.sender] = self.deposits[_requestId][msg.sender] - _amount

    # Update the research request paid out amount
    self.requests[_requestId].payout = self.requests[_requestId].payout + _amount

    # Update the research request completed flag
    self.requests[_requestId].isCompleted = True

    # Send the amount to the receiver address
    send(_receiver, _amount)

    # Event
    log.Withdrawn(msg.sender, self.requests[_requestId].deposit)

@public
@payable
def refund(_requestId: uint256):
    # Guard 1: whether the address is not sender address
    assert msg.sender == self.requests[_requestId].owner

    # Guard 2: whether the current timestamp has gone over the submission end at
    assert self.requests[_requestId].refundableAt <= block.timestamp
 
    # Culculate remain wei_value
    amount: wei_value = self.requests[_requestId].deposit - self.requests[_requestId].payout

    # Update the deposits amount
    self.deposits[_requestId][msg.sender] = self.deposits[_requestId][msg.sender] - amount

    # Update the research request payout
    self.requests[_requestId].payout = self.requests[_requestId].payout + amount

    # Update the research request completed flag
    self.requests[_requestId].isCompleted = True

    # Send the amount to the receiver address
    send(msg.sender, amount)

    # Event
    log.Withdrawn(msg.sender, amount)

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
def setApplicationTimespan(_applicationMinimumTimespan: timedelta):
    # Guard 1: only owner
    assert self.owner == msg.sender

    # Set application minimum timespan
    self.applicationMinimumTimespan = _applicationMinimumTimespan

    # Event
    log.ApplicationMinimumTimespanChanged(self.applicationMinimumTimespan)

@public
def setSubmissionTimespan(_submissionMinimumTimespan: timedelta):
    # Guard 1: only owner
    assert self.owner == msg.sender

    # Set submission timespan
    self.submissionMinimumTimespan = _submissionMinimumTimespan

    # Event
    log.SubmissionMinimumTimespanChanged(self.submissionMinimumTimespan)

@public
def setDistributionEndTimespan(_distributionTimespan: timedelta):
    # Guard 1: only owner
    assert self.owner == msg.sender

    # Set distribution timespan
    self.distributionTimespan = _distributionTimespan

    # Event
    log.DistributionEndTimespanChanged(self.refundableTimespan)


@public
def setRefundableTimespan(_refundableTimespan: timedelta):
    # Guard 1: only owner
    assert self.owner == msg.sender

    # Set refundable timespan
    self.refundableTimespan = _refundableTimespan

    # Event
    log.RefundableTimespanChanged(self.refundableTimespan)
