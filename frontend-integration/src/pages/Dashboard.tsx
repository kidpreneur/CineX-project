import React from 'react';
import styles from '../styles/pages/Dashboard.module.css';

const Dashboard: React.FC = () => {
  // Placeholder data for the dashboard
  const user = {
    name: 'Alex Doe',
    walletAddress: 'SP3...45G',
    balance: '2,500 STX',
    projectsBacked: 8,
    fundsContributed: '12,500 STX',
  };

  const recentActivity = [
    'You successfully backed the project "Cosmic Wanderers".',
    'Your proposal for "Ocean\'s Lullaby" has been approved.',
    'You joined the "Indie Animators" funding pool.',
    'A new project "City of Steam" has been listed.',
  ];

  return (
    <div className={styles.dashboard}>
      <header className={styles.header}>
        <h1>Welcome, {user.name}</h1>
        <p>This is your personal space to manage film projects and investments.</p>
      </header>

      <div className={styles.mainGrid}>
        <section className={`${styles.card} ${styles.profileSummary}`}>
          <h2 className={styles.cardTitle}>Profile Summary</h2>
          <ul>
            <li><strong>Wallet Address:</strong> {user.walletAddress}</li>
            <li><strong>Balance:</strong> {user.balance}</li>
            <li><strong>Projects Backed:</strong> {user.projectsBacked}</li>
            <li><strong>Total Funds Contributed:</strong> {user.fundsContributed}</li>
          </ul>
        </section>

        <section className={`${styles.card} ${styles.actions}`}>
          <h2 className={styles.cardTitle}>Quick Actions</h2>
          <div className={styles.actionButtons}>
            <button className={styles.button}>Submit a Proposal</button>
            <button className={styles.button}>Explore Funding Pools</button>
            <button className={styles.button}>View My Projects</button>
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
