import React from 'react';
import styles from '../styles/pages/Dashboard.module.css';

const Dashboard: React.FC = () => {
  // Placeholder data for the dashboard
  const user = {
    name: 'Alex Doe',
    walletAddress: 'SP3...45G',
    balance: '2,500 STX',
  campaignsBacked: 8,
    fundsContributed: '12,500 STX',
  };

  const recentActivity = [
  'You successfully backed the campaign "Cosmic Wanderers".',
  'Your campaign proposal for "Ocean\'s Lullaby" has been approved.',
  'You joined the "Indie Animators" funding pool.',
  'A new campaign "City of Steam" has been listed.',
  ];

  return (
    <div className={styles.dashboard}>
      <header className={styles.header}>
  <h1>Welcome, {user.name}</h1>
  <p className={styles.helperText}>This is your personal space to manage creative campaigns and investments. Here you can launch, track, and support campaigns in the creative and entertainment industry.</p>
      </header>

      <div className={styles.mainGrid}>
        <section className={`${styles.card} ${styles.profileSummary}`}>
          <h2 className={styles.cardTitle}>Profile Summary</h2>
          <ul>
            <li><strong>Wallet Address:</strong> {user.walletAddress}</li>
            <li><strong>Balance:</strong> {user.balance}</li>
            <li><strong>Campaigns Backed:</strong> {user.campaignsBacked}</li>
            <li><strong>Total Funds Contributed:</strong> {user.fundsContributed}</li>
          </ul>
        </section>

        <section className={`${styles.card} ${styles.actions}`}>
          <h2 className={styles.cardTitle}>Quick Actions</h2>
          <div className={styles.actionButtons}>
            <button className={styles.button} title="Start a new campaign and raise funds for your creative project.">Create a Campaign</button>
            <button className={styles.button} title="Browse available funding pools to support or join.">Explore Funding Pools</button>
            <button className={styles.button} title="See all campaigns you have launched or backed.">View My Campaigns</button>
            <a href="/rewards" className={styles.button} title="View your NFT contributor rewards">My NFT Rewards</a>
            <a href="/coep-pools" className={styles.button} title="Collaborate in Co-EP rotating funding pools">Co-EP Funding Pools</a>
            <a href="/escrow-management" className={styles.button} title="View and manage campaign escrow balances and withdrawals">Escrow Fund Management</a>
          </div>
        </section>

        <section className={`${styles.card} ${styles.recentActivity}`}>
          <h2 className={styles.cardTitle}>Recent Activity</h2>
          <ul>
            {recentActivity.map((activity, index) => (
              <li key={index}>{activity}</li>
            ))}
          </ul>
        </section>
      </div>
    </div>
  );
};

export default Dashboard;
