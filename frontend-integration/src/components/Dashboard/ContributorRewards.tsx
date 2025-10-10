import React, { useState, useEffect } from 'react';
import styles from '../../styles/components/ContributorRewards.module.css';
import { FaGift, FaMedal } from 'react-icons/fa';

const mockRewards = [
  { id: 1, campaign: 'Cosmic Wanderers', type: 'NFT', tier: 'Gold', date: '2025-09-12', status: 'Claimed' },
  { id: 2, campaign: 'Indie Animators', type: 'NFT', tier: 'Silver', date: '2025-08-22', status: 'Unclaimed' },
  { id: 3, campaign: 'City of Steam', type: 'NFT', tier: 'Bronze', date: '2025-07-10', status: 'Claimed' },
];

const ContributorRewards: React.FC = () => {
  const [visibleRows, setVisibleRows] = useState(0);

  useEffect(() => {
    setVisibleRows(0);
    const timer = setInterval(() => {
      setVisibleRows((prev) => {
        if (prev < mockRewards.length) return prev + 1;
        clearInterval(timer);
        return prev;
      });
    }, 1200);
    return () => clearInterval(timer);
  }, []);

  return (
    <section className={styles.rewardsSection}>
      <h2 className={styles.heading}><FaGift /> Contributor Rewards & NFT History</h2>
      <table className={styles.rewardsTable}>
        <thead>
          <tr>
            <th>Campaign</th>
            <th>Type</th>
            <th>Tier</th>
            <th>Date</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {mockRewards.slice(0, visibleRows).map((reward, idx) => (
            <tr key={reward.id} className={styles.animated + ' ' + styles[`animate${idx%4}`]} style={{ animationDelay: `${idx * 0.2}s` }}>
              <td>{reward.campaign}</td>
              <td><FaMedal className={styles.icon} /> {reward.type}</td>
              <td>{reward.tier}</td>
              <td>{reward.date}</td>
              <td>{reward.status}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
};

export default ContributorRewards;
