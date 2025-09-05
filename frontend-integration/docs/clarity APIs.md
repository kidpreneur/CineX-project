 Instead, it simply defines **logical API endpoints** that your frontend (built using Stacks.js) or any integration layer can use to interact with the smart contracts — regardless of what backend, if any, is used.

---

### 📄 `docs/APIs.md` (No Node/Express Assumptions)

````markdown
# CineX Contract Interaction API

This document defines the logical API interface for interacting with Clarity smart contracts from the CineX frontend or other dApps. These endpoints represent **conceptual operations**, implemented using **Stacks.js** or similar libraries directly in the frontend or integration layer.

---

## 📦 Contract Modules

- **Crowdfunding Module**
- **Escrow Module**
- **Film Verification Module**
- **Rewards Module**

Each module maps to a Clarity smart contract and exposes core functionality for CineX users.

---

## 🧱 Crowdfunding Module

### `getCampaigns()`
- **Description:** Retrieve all active or expired crowdfunding campaigns.
- **Returns:** Array of campaign metadata
- **Example Return:**
```json
[
  { "id": 1, "creator": "ST3...", "goal": 500000, "pledged": 200000, "deadline": "2025-08-31" }
]
````

---

### `createCampaign({ title, goalAmount, duration, sender })`

* **Description:** Create a new crowdfunding campaign
* **Inputs:**

  * `title`: string
  * `goalAmount`: uint
  * `duration`: number of days
  * `sender`: wallet address
* **On-Chain Function:** `create-campaign`

---

### `pledgeToCampaign({ campaignId, amount, sender })`

* **Description:** Pledge STX to an existing campaign
* **Inputs:**

  * `campaignId`: int
  * `amount`: uint
  * `sender`: wallet address
* **On-Chain Function:** `pledge-funds`

---

## 🧾 Escrow Module

### `initiateEscrow({ campaignId, creator, funder, amount })`

* **Description:** Start escrow for a successful campaign
* **On-Chain Function:** `initiate-escrow`

---

### `releaseEscrow({ escrowId })`

* **Description:** Release escrowed funds to creator
* **On-Chain Function:** `release-escrow`

---

### `refundEscrow({ escrowId })`

* **Description:** Refund pledged funds if campaign fails
* **On-Chain Function:** `refund-escrow`

---

## 🎬 Film Verification Module

### `submitFilm({ filmUrl, sender })`

* **Description:** Submit a film for verification
* **On-Chain Function:** `submit-film`

---

### `getPendingFilms()`

* **Description:** Fetch all unverified films awaiting approval
* **Return Format:**

```json
[
  { "filmId": 1, "submitter": "ST3...", "url": "ipfs://..." }
]
```

---

### `verifyFilm({ filmId, verifier })`

* **Description:** Verify a pending film
* **On-Chain Function:** `verify-film`

---

## 🎁 Rewards Module

### `getAvailableRewards({ wallet })`

* **Description:** Check which rewards are available to a wallet
* **Return Format:**

```json
[
  { "rewardId": 1, "type": "Badge", "status": "claimable" }
]
```

---

### `claimReward({ rewardId, wallet })`

* **Description:** Claim a reward
* **On-Chain Function:** `claim-reward`

---

### `getRewardHistory({ wallet })`

* **Description:** Get past claimed rewards
* **Return Format:**

```json
[
  { "rewardId": 1, "claimedOn": "2025-08-01", "status": "claimed" }
]
```

---

## 🔧 Utility Helpers

### `getContractStatus()`

* **Description:** Read status/config info about deployed Clarity contracts
* **Return Example:**

```json
{
  "network": "testnet",
  "crowdfundingContract": "ST2...::crowdfunding-module",
  "version": "v0.1.0"
}
```

---

## 🛠 Implementation Notes

* All interactions are made using [Stacks.js](https://github.com/hirosystems/stacks.js).
* Function calls can be broadcast using
