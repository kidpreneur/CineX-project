import React from 'react';
import styles from '../styles/pages/EscrowManagement.module.css';

// Placeholder data for demonstration
const campaigns = [
  { id: 1, name: 'Cosmic Wanderers', balance: 65000, authorized: true, feesCollected: 2500 },
  { id: 2, name: 'Documentary X', balance: 12000, authorized: false, feesCollected: 600 },
];

const EscrowManagement: React.FC = () => {
  return (
    <div className={styles.escrowPage}>
      <h1>Escrow Fund Management</h1>
      <p>View and manage campaign escrow balances, authorized withdrawals, and platform fee collections.</p>
      <table className={styles.escrowTable}>
        <thead>
          <tr>
            <th>Campaign</th>
            <th>Escrow Balance</th>
            <th>Authorized Withdrawal</th>
            <th>Fees Collected</th>
          </tr>
        </thead>
        <tbody>
          {campaigns.map((c) => (
            <tr key={c.id}>
              <td>{c.name}</td>
              <td>{c.balance} STX</td>
              <td>{c.authorized ? 'Yes' : 'No'}</td>
              <td>{c.feesCollected} STX</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default EscrowManagement;
