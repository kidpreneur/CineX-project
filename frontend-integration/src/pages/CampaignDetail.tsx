import React from 'react';
import styles from '../styles/pages/CampaignDetail.module.css';

// Placeholder props for demonstration
const campaign = {
  id: 1,
  title: 'Cosmic Wanderers',
  description: 'A sci-fi adventure film seeking final round of funding.',
  fundingGoal: 100000,
  totalRaised: 65000,
  duration: 90,
  owner: 'SP3...45G',
  rewardTiers: [
    { tier: 1, description: 'Digital thank you + early access' },
    { tier: 2, description: 'Special credits + exclusive content' },
    { tier: 3, description: 'VIP event invite + signed poster' },
  ],
  isActive: true,
  fundsClaimed: false,
  isVerified: true,
  verificationLevel: 2,
  expiresAt: '2025-12-31',
  lastActivityAt: '2025-10-01',
  filmmaker: {
    name: 'Jane Doe',
    verified: true,
    verificationLevel: 2,
    portfolio: [
      { name: 'Short Film 1', year: 2022, url: '#' },
      { name: 'Documentary X', year: 2023, url: '#' },
    ],
    endorsements: [
      { endorser: 'Film Guild', letter: 'Outstanding work!', url: '#' },
    ],
  },
};

const CampaignDetail: React.FC = () => {
  return (
    <div className={styles.campaignDetail}>
      <h1>{campaign.title}</h1>
      <p>{campaign.description}</p>
      <div className={styles.stateInfo}>
        <span>Status: {campaign.isActive ? 'Active' : 'Inactive'}</span>
        <span>Verified: {campaign.isVerified ? `Level ${campaign.verificationLevel}` : 'No'}</span>
        <span>Expires: {campaign.expiresAt}</span>
        <span>Funds Claimed: {campaign.fundsClaimed ? 'Yes' : 'No'}</span>
      </div>
      <div className={styles.fundingInfo}>
        <span>Funding Goal: {campaign.fundingGoal} STX</span>
        <span>Total Raised: {campaign.totalRaised} STX</span>
        <span>Duration: {campaign.duration} days</span>
      </div>
      <div className={styles.rewardTiers}>
        <h2>Reward Tiers</h2>
        <ul>
          {campaign.rewardTiers.map((tier) => (
            <li key={tier.tier}><strong>Tier {tier.tier}:</strong> {tier.description}</li>
          ))}
        </ul>
      </div>
      <div className={styles.filmmakerInfo}>
        <h2>Filmmaker</h2>
        <span>Name: {campaign.filmmaker.name}</span>
        <span>Verified: {campaign.filmmaker.verified ? `Level ${campaign.filmmaker.verificationLevel}` : 'No'}</span>
        <h3>Portfolio</h3>
        <ul>
          {campaign.filmmaker.portfolio.map((item, idx) => (
            <li key={idx}><a href={item.url}>{item.name} ({item.year})</a></li>
          ))}
        </ul>
        <h3>Endorsements</h3>
        <ul>
          {campaign.filmmaker.endorsements.map((e, idx) => (
            <li key={idx}><a href={e.url}>{e.endorser}</a>: {e.letter}</li>
          ))}
        </ul>
      </div>
    </div>
  );
};

export default CampaignDetail;
