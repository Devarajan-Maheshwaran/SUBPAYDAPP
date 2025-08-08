import { expect } from "chai";
import { ethers } from "hardhat";
import { DummyUSDC, SubscriptionManager } from "../typechain-types";

describe("SubscriptionManager", function () {
  let subscriptionManager: SubscriptionManager;
  let dummyUSDC: DummyUSDC;
  let owner: any;
  let addr1: any;

  let SubscriptionManagerFactory: any;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    const DummyUSDCFactory = await ethers.getContractFactory("DummyUSDC");
    dummyUSDC = await DummyUSDCFactory.deploy();
    await dummyUSDC.waitForDeployment();

    SubscriptionManagerFactory = await ethers.getContractFactory("SubscriptionManager");
    subscriptionManager = await SubscriptionManagerFactory.deploy();
    await subscriptionManager.waitForDeployment();
  });

  it("should create a subscription plan", async function () {
    const token = await dummyUSDC.getAddress();
    const price = ethers.parseUnits("10", 6); // 10 USDC with 6 decimals
    const interval = 60 * 60 * 24 * 30; // 30 days
    const name = "Pro Plan";

    const tx = await subscriptionManager.createPlan(price, interval, token);
    const receipt = await tx.wait();

    // Bonus: Check emitted event
    const eventLog = receipt?.logs?.find(
      (log: any) => log.fragment?.name === "PlanCreated"
    );
    expect(eventLog).to.not.be.undefined;

    // Decode the event log to get planId
    const iface = SubscriptionManagerFactory.interface;
    if (!eventLog) {
      throw new Error("PlanCreated event not found in logs");
    }
    const decoded = iface.decodeEventLog("PlanCreated", eventLog.data, eventLog.topics);
    const planId = decoded.planId;

    const plan = await subscriptionManager.plans(planId);
    expect(plan.paymentToken).to.equal(token);
    expect(plan.price).to.equal(price);
    expect(plan.interval).to.equal(interval);
    // expect(plan.name).to.equal(name); // 'name' does not exist, comment or fix
    // If you want to check the creator, use:
    expect(plan.creator).to.equal(owner.address);
    // expect(plan.owner).to.equal(owner.address); // 'owner' does not exist on plan, so this is commented out
  });
});
