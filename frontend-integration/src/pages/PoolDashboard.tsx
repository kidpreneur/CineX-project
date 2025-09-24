import React from 'react';
import styles from '../styles/pages/PoolDashboard.module.css';

// Placeholder pool data
const pools = [
  {
    id: 1,
    name: 'Indie Filmmakers Pool',
    value: '100,000 STX',
    contribution: '10,000 STX',
    members: '5/10',
    status: 'Forming',
    currentRotation: 'Funding: Jane Doe',
    yourTurn: 'Your turn is in 2 cycles',
  },
  {
    id: 2,
    name: 'Animation Collective',
    value: '50,000 STX',
    contribution: '5,000 STX',
    members: '8/10',
    status: 'Active',
    currentRotation: 'Funding: John Smith',
    yourTurn: 'You are next in line',
  },
];

const PoolDashboard: React.FC = () => {
  return (
    <div className={styles.poolDashboard}>
      <header className={styles.header}>
        <h1>Funding Pools</h1>
        <div className={styles.tabs}>
          <button className={styles.tabActive}>My Pools</button>
          <button className={styles.tab}>Browse Pools</button>
          <button className={styles.tab}>Create a Pool</button>
        </div>
      </header>
      <section className={styles.poolList}>
        {pools.map(pool => (
          <div key={pool.id} className={styles.poolCard}>
            <h2>{pool.name}</h2>
            <ul>
              <li><strong>Total Pool Value:</strong> {pool.value}</li>
              <li><strong>Your Contribution:</strong> {pool.contribution}</li>
              <li><strong>Members:</strong> {pool.members}</li>
              <li><strong>Status:</strong> {pool.status}</li>
              <li><strong>Current Rotation:</strong> {pool.currentRotation}</li>
              <li><strong>Your Turn:</strong> {pool.yourTurn}</li>
            </ul>
            <button className={styles.viewPoolBtn}>View Pool</button>
          </div>
        ))}
      </section>
    </div>
  );
};

export default PoolDashboard;
