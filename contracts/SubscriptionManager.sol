// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract SubscriptionManager {
    address public owner;
    uint256 public planCount;

    struct Plan {
        uint256 id;
        uint256 price; // in tokens
        uint256 interval; // seconds
        address paymentToken; // e.g., USDC
        address creator;
    }

    struct Subscription {
        uint256 start;
        uint256 nextPaymentTime;
        bool active;
    }

    mapping(uint256 => Plan) public plans;
    mapping(address => mapping(uint256 => Subscription)) public subscriptions;

    event PlanCreated(uint256 indexed planId, uint256 price, uint256 interval, address token, address creator);
    event Subscribed(address indexed user, uint256 indexed planId, uint256 startTime);
    event Cancelled(address indexed user, uint256 indexed planId);

    constructor() {
        owner = msg.sender;
    }

    function createPlan(uint256 price, uint256 interval, address token) external {
        require(price > 0, "Price must be > 0");
        require(interval >= 1 days, "Interval too short");

        planCount += 1;
        plans[planCount] = Plan({
            id: planCount,
            price: price,
            interval: interval,
            paymentToken: token,
            creator: msg.sender
        });

        emit PlanCreated(planCount, price, interval, token, msg.sender);
    }

    function subscribe(uint256 planId) external {
        Plan memory plan = plans[planId];
        require(plan.id != 0, "Invalid plan");

        IERC20(plan.paymentToken).transferFrom(msg.sender, plan.creator, plan.price);

        subscriptions[msg.sender][planId] = Subscription({
            start: block.timestamp,
            nextPaymentTime: block.timestamp + plan.interval,
            active: true
        });

        emit Subscribed(msg.sender, planId, block.timestamp);
    }

    function cancelSubscription(uint256 planId) external {
        require(subscriptions[msg.sender][planId].active, "Not subscribed");

        subscriptions[msg.sender][planId].active = false;

        emit Cancelled(msg.sender, planId);
    }

    function isSubscribed(address user, uint256 planId) public view returns (bool) {
        Subscription memory sub = subscriptions[user][planId];
        return sub.active && sub.nextPaymentTime > block.timestamp;
    }
}
