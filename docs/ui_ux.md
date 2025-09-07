# CineX Platform: UI/UX Design Document

This document outlines the user interface (UI) and user experience (UX) design for the CineX platform, a decentralized crowdfunding platform for indie filmmakers.

## 1. Overall Vision & Principles

The CineX platform should feel modern, trustworthy, and inspiring. The design will be guided by the following principles:

*   **Clarity and Simplicity:** The interface will be clean, intuitive, and easy to navigate for all user types, from crypto-savvy investors to filmmakers.
*   **Transparency and Trust:** As a decentralized platform, all interactions with the blockchain will be clearly communicated to the user. Transaction statuses, fees, and contract details will be readily accessible.
*   **Cinematic Feel:** The design will evoke a sense of professionalism and creativity, fitting for a platform dedicated to filmmaking.
*   **Responsive and Accessible:** The platform will be fully responsive and accessible to users on all devices (desktop, tablet, and mobile).

## 2. Branding & Style Guide

### Color Palette

The color palette is designed to be sophisticated, with a cinematic feel. A dark theme is proposed as the default to reduce eye strain and make visual content stand out.

*   **Primary Background:** Dark Charcoal (`#121212`) - Evokes a dark theater or editing room.
*   **Secondary Background:** Dark Slate (`#222222`) - For cards and elevated surfaces.
*   **Primary Text & Accents:** Warm Beige (`#F5F5DC`) - For body text and secondary UI elements.
*   **Primary Call-to-Action (CTA) & Highlights:** Vibrant Gold (`#FFBF00`) - To draw attention to key actions like "Fund Project" or "Connect Wallet".
*   **Success/Confirmation:** Green (`#28a745`) - For successful transactions, funded goals, etc.
*   **Error/Warning:** Red (`#dc3545`) - For failed transactions, error messages, and warnings.

### Typography

The typography will be modern, clean, and highly legible.

*   **Headings:** Poppins (SemiBold, Bold) - A stylish and modern sans-serif font for titles and headings.
*   **Body Text:** Inter (Regular) - A highly readable sans-serif font for paragraphs, labels, and other UI text.

### Iconography

A consistent icon set is crucial for a clean UI. We will use **Material Design Icons**.

*   **Navigation:** `home`, `dashboard`, `movie`, `account_balance_wallet`, `admin_panel_settings`
*   **Actions:** `add`, `thumb_up`, `thumb_down`, `check_circle`, `cancel`, `logout`
*   **Status:** `hourglass_empty` (pending), `check` (success), `error` (failed)

### Imagery & Visuals

*   **Film Stills:** High-quality, cinematic stills from the projects will be used as hero images and thumbnails. A subtle film-grain overlay will be applied to all images to maintain a consistent aesthetic.
*   **Thumbnails:** Project thumbnails will have a consistent 16:9 aspect ratio. On hover, they will display a play button to watch a trailer and a brief project summary.

### Micro-interactions & Animations

Subtle animations will be used to enhance the user experience and provide feedback.

*   **Hover Effects:** Buttons, links, and cards will have subtle hover effects (e.g., a slight lift or color change).
*   **Page Transitions:** Smooth fade-in/fade-out transitions between pages.
*   **Loading States:** Skeleton loaders will be used to show the structure of the content while it's loading. A small, elegant spinner will be used for button actions.
*   **Notifications:** Toast notifications will slide in from the top right of the screen to confirm actions or display errors.

## 3. User Roles & Personas

The platform will cater to three main user roles:

*   **Investor (General User):** Individuals who want to invest in film projects. They can browse projects, join funding pools, and track their investments.
*   **Filmmaker (Co-Filmmaker/Creator):** Individuals or teams who want to raise funds for their film projects. They can create campaigns, submit proposals for verification, and manage their projects.
*   **Admin:** Platform administrators who are responsible for managing users, verifying film proposals, and overseeing the platform's operations.

## 4. Key User Flows

The platform will support the following key user flows:

*   **User Registration & Wallet Connection:** Users will connect their Stacks wallet to register and log in to the platform.
*   **Project Discovery:** Investors can browse and filter film projects based on genre, funding goal, and other criteria.
*   **Project Funding:** Investors can fund projects directly or by joining a funding pool. The funding process will be a clear, multi-step process with transparent transaction details.
*   **Campaign Creation:** Filmmakers can create a new crowdfunding campaign by filling out a detailed form with project information, funding goals, and reward tiers.
*   **Film Verification:** Filmmakers can submit their projects for verification by the platform admins.
*   **Reward Claiming:** Investors can claim their NFT rewards for supporting a successful project.
*   **Co-EP Rotating Funding:** Filmmakers can create or join trust-based rotating funding pools ("adashe") to secure funding in cycles with other verified filmmakers.

=======

=======
=======



## 5. Wireframes & Mockups (Text-based)

This section describes the layout and components of each page.

### Global Elements

*   **Navbar (Desktop):** `[Logo]` `[Home]` `[Projects]` `[Dashboard]` `[Connect Wallet / My Profile]`
*   **Hamburger Menu (Mobile):** A slide-in menu with links to all major pages, user profile, settings, and logout.
*   **Footer:** Links to `About`, `Contact/Support`, `Terms of Service`, and social media.

### Pages

#### 1. Landing Page (Home)

*   **Hero Section:** A full-bleed background image (a film still) with the tagline: "CineX: Invest Together. Create Together." and a primary CTA button: "Explore Projects".
*   **Featured Projects:** A horizontally scrolling carousel of featured film projects, with thumbnails, titles, and funding progress bars.
*   **How It Works:** A section with three simple steps (Discover, Fund, Reward) with icons and brief descriptions.
*   **Testimonials:** A section with quotes from filmmakers and investors.

#### 2. Projects Page

*   **Search and Filter Bar:** A prominent bar at the top with a search input and dropdown filters for genre, funding status, etc.
*   **Project Grid:** A responsive grid of project cards. Each card displays:
    *   Project thumbnail (16:9)
    *   Project title
    *   Filmmaker name
    *   Funding progress bar
    *   Days left in the campaign
*   **Pagination:** For browsing through multiple pages of projects.

#### 3. Project Detail Page

*   **Two-column Layout:**
    *   **Left Column:** A large video player for the trailer, followed by a gallery of film stills.
    *   **Right Column:**
        *   Project title and filmmaker name.
        *   Funding status (amount raised, goal, number of backers, days left).
        *   A prominent "Fund Project" button.
        *   Detailed project description (synopsis, team, etc.).
        *   Reward tiers.
*   **Tabs:** A tabbed section for `Comments`, `Updates`, and `Backers`.

#### 4. Dashboard (Investor)

*   **Welcome Message:** "Welcome back, [User Name]!"
*   **Stats Overview:** A set of cards displaying: `Total Invested`, `Projects Backed`, `Rewards Earned`.
*   **My Investments:** A table listing all the projects the user has invested in, with columns for `Project`, `Amount`, `Status`, and `Link to Project`.
*   **Recent Activity:** A feed of recent activities (e.g., "You invested 50 STX in 'The Last Stand'").

#### 5. Dashboard (Filmmaker)

*   **Welcome Message:** "Welcome back, [Filmmaker Name]!"
*   **My Projects:** A grid of the filmmaker's projects, with options to `Edit Campaign` or `View Stats`.
*   **Create New Project:** A prominent CTA button to start a new campaign.
*   **Project Stats:** Detailed analytics for each project (views, backers, funding sources).

#### 6. Admin Dashboard

*   **Platform Overview:** Key platform metrics (total funds raised, number of active projects, new users).
*   **Verification Queue:** A table of film projects pending verification, with options to `View Proposal`, `Approve`, or `Reject`.
*   **User Management:** A table of all users with options to view their activity or take administrative actions.
*   **Project Management:** A table of all projects on the platform.


=======

=======



#### 8. Co-EP Rotating Funding Pools Page

This page is dedicated to the 'adashe' style rotating funding pools, a core feature for professional filmmakers.

*   **Page Layout:** A dashboard-style layout with tabs for `[My Pools]`, `[Browse Pools]`, and `[Create a Pool]`.

*   **My Pools Tab:**
    *   A list of all pools the user is a member of.
    *   Each pool is a card with the following information:
        *   Pool Name
        *   Total Pool Value (e.g., 100,000 STX)
        *   Your Contribution (e.g., 10,000 STX)
        *   Number of Members (e.g., 5/10)
        *   Pool Status (`Forming`, `Active`, `Completed`)
        *   Current Rotation (e.g., "Funding: [Filmmaker Name]")
        *   Your Turn (e.g., "You are next in line" or "Your turn is in 3 cycles")
    *   A "View Pool" button on each card to navigate to the Pool Detail Page.

*   **Browse Pools Tab:**
    *   A list of all "forming" pools that the user is eligible to join (based on verified connections).
    *   Each pool card shows similar information to the "My Pools" tab.
    *   A "Request to Join" button on each card.

*   **Create a Pool Tab:**
    *   A multi-step form to create a new rotating funding pool:
        1.  **Pool Details:** Pool Name, Contribution per Member, Max Members, Cycle Duration.
        2.  **Legal Agreement:** A section to upload or link to a legal agreement, which will be hashed and stored on-chain.
        3.  **Invite Members:** An interface to invite other verified filmmakers from your network of connections.
        4.  **Review and Create:** A summary of the pool details before submitting the transaction to create the pool.

#### 9. Pool Detail Page

This page provides a detailed view of a single rotating funding pool.

*   **Header:** Pool Name, Total Value, and Status.
*   **Rotation Schedule:** A visual timeline or a list showing the order of beneficiaries, the scheduled funding date for each, and their funding status (`Pending`, `Funded`).
*   **Member List:** A list of all pool members, their contribution status (`Contributed`, `Pending`), and a link to their profiles.
*   **Contribution Section:** If the user has not yet contributed for the current cycle, a prominent "Contribute Now" button will be displayed.
*   **Project Details:** A section to display the project details of the current beneficiary.
*   **Activity Feed:** A log of all significant events in the pool (e.g., "Member X joined", "Member Y contributed", "Rotation 2 funded to Member Z").

#### 10. Wallet Connection & Modals

=======

=======
=======
#### 7. Wallet Connection & Modals




*   **Connect Wallet Modal:** A simple modal prompting the user to connect their Hiro Wallet. It will show the connection status.
*   **Transaction Modal:** When a user initiates a transaction (e.g., funding a project), a modal will appear showing the transaction details, estimated fees, and status (pending, success, failed). This provides crucial feedback and transparency.
