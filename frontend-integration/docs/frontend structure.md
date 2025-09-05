Here is the **updated frontend structure** (`frontend-structure.md`) for our **Vite + React + TypeScript** project, grouped into **Basic**, **Medium**, and **Complex** stages, and reflecting your use of `module.css` files organized under a central `styles/` directory.

---

# 📁 Frontend Project Structure (Vite + React + TypeScript + Stacks.js + CSS Modules)

This structure assumes:

* You’re communicating with Clarity contracts via `@stacks/connect`, `@stacks/transactions`, and `@stacks/network`
* You're using `module.css` for styling, organized under `/src/styles/`
* You don't use Node/Express backend — only direct blockchain interaction via Hiro API + Clarity

---

## 🟢 Basic (MVP Layout + Wallet Connection)

```
src/
├── assets/
│   └── logo.svg
│
├── components/
│   ├── Wallet/
│   │   └── ConnectWallet.tsx
│   └── Layout/
│       ├── Header.tsx
│       └── Footer.tsx
│
├── pages/
│   ├── Home.tsx
│   └── NotFound.tsx
│
├── styles/
│   ├── Wallet/
│   │   └── ConnectWallet.module.css
│   └── Layout/
│       ├── Header.module.css
│       └── Footer.module.css
│
├── App.tsx
├── main.tsx
├── vite-env.d.ts
└── index.css
```

✅ **Focus**: Basic routing, wallet connect (Stacks.js), layout structure, and page switch.

---

## 🟡 Medium (Campaign, Escrow, Rewards Features)

src/
 └── features/
      └── crowdfunding/
           ├── components/
           │     ├── CampaignList.tsx
           │     ├── CampaignCard.tsx
           │     ├── CampaignDetail.tsx
           │     ├── CreateCampaignForm.tsx
           │     └── FundCampaignModal.tsx
           │
           ├── services/
           │     └── crowdfundingContract.ts     # Interact with Clarity contracts
           │
           ├── types/
           │     └── crowdfunding.d.ts
           │
           ├── crowdfunding.module.css
           │
           └── crowdfundingRoutes.tsx

```
src/
├── components/
│   ├── Campaign/
│   │   ├── CampaignList.tsx
│   │   └── CreateCampaign.tsx
│   ├── Escrow/
│   │   ├── EscrowInitiate.tsx
│   │   └── EscrowRefund.tsx
│   └── Rewards/
│       └── ClaimReward.tsx
│
├── pages/
│   ├── CampaignPage.tsx
│   ├── EscrowPage.tsx
│   └── RewardsPage.tsx
│
├── styles/
│   ├── Campaign/
│   │   ├── CampaignList.module.css
│   │   └── CreateCampaign.module.css
│   ├── Escrow/
│   │   ├── EscrowInitiate.module.css
│   │   └── EscrowRefund.module.css
│   └── Rewards/
│       └── ClaimReward.module.css
│
├── hooks/
│   └── useWallet.ts
│
├── utils/
│   └── clarity.ts
```

✅ **Focus**: Implement campaign creation, escrow actions, and rewards claiming with contract calls.

---

## 🔴 Complex (NFTs, Verification, Advanced Logic, State Mgmt)

```
src/
├── components/
│   ├── NFT/
│   │   └── MintNFT.tsx
│   ├── Verification/
│   │   ├── SubmitVerification.tsx
│   │   └── VerificationStatus.tsx
│   └── Analytics/
│       └── PoolAnalytics.tsx
│
├── pages/
│   ├── NFTPage.tsx
│   └── VerificationPage.tsx
│
├── styles/
│   ├── NFT/
│   │   └── MintNFT.module.css
│   ├── Verification/
│   │   ├── SubmitVerification.module.css
│   │   └── VerificationStatus.module.css
│   └── Analytics/
│       └── PoolAnalytics.module.css
│
├── store/
│   └── globalState.ts (Zustand or Redux Toolkit)
│
├── constants/
│   └── network.ts (testnet, mainnet config)
│
├── services/
│   └── stacks.ts (Hiro API wrappers, contract callers)
```

✅ **Focus**: NFTs, advanced state, analytics, verification flows, and interacting with multiple smart contracts.

---

## ✅ Summary of Key Conventions

* **`styles/`** contains all `module.css` files, grouped by feature/component
* **`components/`** are organized by feature domain (Campaign, Wallet, Rewards, etc.)
* **`pages/`** are routed screens (React Router)
* **`services/`** contains contract interaction helpers using Stacks.js
* **No backend** needed — relies on Hiro API + Clarity + Stacks.js

---


