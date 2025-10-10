import React, { useState } from 'react';
import { CreateCampaignModal } from '../components/Campaign';
import ContributorRewards from '../components/Dashboard/ContributorRewards';
import styles from '../styles/pages/Dashboard.module.css';

const Dashboard: React.FC = () => {
  // Simulate user roles: 'admin', 'filmmaker', 'investor'
  const [role, setRole] = useState<'admin' | 'filmmaker' | 'investor'>('filmmaker');
  const [showCreateModal, setShowCreateModal] = useState(false);

  // Mock user data for each role
  const user = role === 'admin'
    ? { name: 'Admin User', walletAddress: 'SP-ADMIN', balance: '100,000 STX', campaignsBacked: 0, fundsContributed: '0 STX' }
    : role === 'filmmaker'
    ? { name: 'Jane Filmmaker', walletAddress: 'SP-FILM', balance: '3,200 STX', campaignsBacked: 2, fundsContributed: '2,000 STX' }
    : { name: 'Investor Joe', walletAddress: 'SP-INVEST', balance: '8,500 STX', campaignsBacked: 12, fundsContributed: '25,000 STX' };

  const recentActivity = role === 'admin'
    ? [
        'Platform paused for maintenance.',
        'Emergency fund recovery executed.',
        'Analytics: 3 new campaigns today.',
      ]
    : role === 'filmmaker'
    ? [
        'Your campaign "Cosmic Wanderers" reached 50% funding.',
        'You received a new endorsement.',
        'You applied for funding: "Ocean’s Lullaby".',
      ]
    : [
        'You backed "City of Steam".',
        'Received NFT reward for "Indie Animators".',
        'Joined "Animation Pool".',
      ];

  return (
    <div className={styles.dashboard}>
      <header className={styles.header}>
        <h1>Welcome, {user.name}</h1>
        <p className={styles.helperText}>This is your personal space to manage creative campaigns and investments. Here you can launch, track, and support campaigns in the creative and entertainment industry.</p>
        <div style={{ marginTop: '0.5rem' }}>
          <span style={{ fontWeight: 600 }}>Switch Role: </span>
          <button onClick={() => setRole('admin')} style={{ marginRight: 8, fontWeight: role==='admin'?700:400 }}>Admin</button>
          <button onClick={() => setRole('filmmaker')} style={{ marginRight: 8, fontWeight: role==='filmmaker'?700:400 }}>Filmmaker</button>
          <button onClick={() => setRole('investor')} style={{ fontWeight: role==='investor'?700:400 }}>Investor</button>
        </div>
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

        {/* Quick Actions by Role */}
        <section className={`${styles.card} ${styles.actions}`}>
          <h2 className={styles.cardTitle}>Quick Actions</h2>
          <div className={styles.actionButtons}>
            {role === 'admin' && (
              <>
                <button className={styles.button} title="Pause or unpause the platform.">Pause/Unpause Platform</button>
                <button className={styles.button} title="View analytics and logs.">View Analytics</button>
                <button className={styles.button} title="Emergency fund recovery.">Emergency Recovery</button>
              </>
            )}
            {role === 'filmmaker' && (
              <>
                <button className={styles.button} title="Start a new campaign and raise funds for your creative project." onClick={() => setShowCreateModal(true)}>Create a Campaign</button>
                <button className={styles.button} title="Apply for funding as a creative.">Apply for Funding</button>
                <button className={styles.button} title="View and manage your pools.">My Pools</button>
                <a href="/rewards" className={styles.button} title="View your NFT contributor rewards">My NFT Rewards</a>
              </>
            )}
            {role === 'investor' && (
              <>
                <button className={styles.button} title="Browse available funding pools to support or join.">Explore Funding Pools</button>
                <button className={styles.button} title="See all campaigns you have launched or backed.">View My Campaigns</button>
                <a href="/coep-pools" className={styles.button} title="Collaborate in Co-EP rotating funding pools">Co-EP Funding Pools</a>
                <a href="/escrow-management" className={styles.button} title="View and manage campaign escrow balances and withdrawals">Escrow Fund Management</a>
              </>
            )}
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
      {role === 'filmmaker' && <CreateCampaignModal open={showCreateModal} onClose={() => setShowCreateModal(false)} />}
      <ContributorRewards />
    </div>
  );
};

export default Dashboard;
