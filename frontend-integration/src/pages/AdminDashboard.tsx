import React from 'react';
import styles from '../styles/pages/AdminDashboard.module.css';

const AdminDashboard: React.FC = () => {
  return (
    <div className={styles.adminDashboardContainer}>
      <h1>Admin Dashboard</h1>
      <section className={styles.statsSection}>
        <h2>Platform Stats</h2>
        <ul>
          <li>Total Users: 1,234</li>
          <li>Total Projects: 56</li>
          <li>Total Pools: 12</li>
          <li>Pending Verifications: 4</li>
        </ul>
      </section>
      <section className={styles.managementSection}>
        <h2>User / Project / Pool Management</h2>
        <p>Manage users, projects, and pools here. (Coming soon)</p>
      </section>
      <section className={styles.verificationSection}>
        <h2>Verification Queue</h2>
        <ul>
          <li>Project A - Awaiting Verification</li>
          <li>Pool B - Awaiting Verification</li>
        </ul>
      </section>
    </div>
  );
};

export default AdminDashboard;
