import React from 'react';
import styles from '../styles/pages/AdminControls.module.css';

const AdminControls: React.FC = () => {
  // Placeholder state for demonstration
  const [paused, setPaused] = React.useState(false);
  const [recoveryLog] = React.useState([
    { id: 1, module: 'Crowdfunding', amount: 10000, recipient: 'SP3...45G', reason: 'Emergency recovery', block: 123456 },
  ]);
  const [stats] = React.useState({
    totalFilmmakers: 42,
    totalPortfolios: 18,
    totalEndorsements: 7,
    totalVerificationFees: 5000,
  });

  return (
    <div className={styles.adminControls}>
      <h1>Admin & Emergency Controls</h1>
      <div className={styles.section}>
        <h2>Platform State</h2>
        <p>Status: <strong>{paused ? 'Paused' : 'Active'}</strong></p>
        <button onClick={() => setPaused(!paused)} className={styles.pauseBtn}>
          {paused ? 'Unpause Platform' : 'Pause Platform'}
        </button>
      </div>
      <div className={styles.section}>
        <h2>Emergency Fund Recovery Log</h2>
        <table className={styles.logTable}>
          <thead>
            <tr>
              <th>ID</th>
              <th>Module</th>
              <th>Amount</th>
              <th>Recipient</th>
              <th>Reason</th>
              <th>Block</th>
            </tr>
          </thead>
          <tbody>
            {recoveryLog.map((log) => (
              <tr key={log.id}>
                <td>{log.id}</td>
                <td>{log.module}</td>
                <td>{log.amount}</td>
                <td>{log.recipient}</td>
                <td>{log.reason}</td>
                <td>{log.block}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className={styles.section}>
        <h2>Platform Analytics</h2>
        <ul>
          <li>Total Registered Filmmakers: {stats.totalFilmmakers}</li>
          <li>Total Portfolios: {stats.totalPortfolios}</li>
          <li>Total Endorsements: {stats.totalEndorsements}</li>
          <li>Total Verification Fees Collected: {stats.totalVerificationFees} STX</li>
        </ul>
      </div>
    </div>
  );
};

export default AdminControls;
