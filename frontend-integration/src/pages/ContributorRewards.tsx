import React from 'react';
import styles from '../styles/pages/ContributorRewards.module.css';

// Placeholder data for demonstration
const rewards = [
  { tokenId: 1, campaign: 'Cosmic Wanderers', tier: 2, description: 'Special credits + exclusive content', date: '2025-09-01' },
  { tokenId: 2, campaign: 'Documentary X', tier: 1, description: 'Digital thank you + early access', date: '2025-08-15' },
];

const ContributorRewards: React.FC = () => {
  return (
    <div className={styles.rewardsPage}>
      <h1>My NFT Rewards</h1>
      <p>These are your contributor rewards for supporting campaigns on CineX.</p>
      <table className={styles.rewardsTable}>
        <thead>
          <tr>
            <th>Token ID</th>
            <th>Campaign</th>
            <th>Tier</th>
            <th>Description</th>
            <th>Date Received</th>
          </tr>
        </thead>
        <tbody>
          {rewards.map((reward) => (
            <tr key={reward.tokenId}>
              <td>{reward.tokenId}</td>
              <td>{reward.campaign}</td>
              <td>{reward.tier}</td>
              <td>{reward.description}</td>
              <td>{reward.date}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default ContributorRewards;
