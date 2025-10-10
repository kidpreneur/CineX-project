import React from 'react';
import styles from '../styles/pages/CoEPPools.module.css';

// Placeholder data for demonstration
const pools = [
  {
    id: 1,
    name: 'Indie Filmmakers Pool',
    members: 5,
    value: 100000,
    status: 'Forming',
    reputation: 87,
    nextBeneficiary: 'Jane Doe',
    mutualProjects: 2,
  },
  {
    id: 2,
    name: 'Documentary Creators',
    members: 4,
    value: 80000,
    status: 'Active',
    reputation: 92,
    nextBeneficiary: 'John Smith',
    mutualProjects: 1,
  },
];

const CoEPPools: React.FC = () => {
  return (
    <div className={styles.poolsPage}>
      <h1>Co-EP Rotating Funding Pools</h1>
      <p>Collaborate with other filmmakers, build trust, and fund each other's projects through rotating savings pools.</p>
      <table className={styles.poolsTable}>
        <thead>
          <tr>
            <th>Name</th>
            <th>Members</th>
            <th>Pool Value</th>
            <th>Status</th>
            <th>Reputation</th>
            <th>Next Beneficiary</th>
            <th>Mutual Projects</th>
          </tr>
        </thead>
        <tbody>
          {pools.map((pool) => (
            <tr key={pool.id}>
              <td>{pool.name}</td>
              <td>{pool.members}</td>
              <td>{pool.value} STX</td>
              <td>{pool.status}</td>
              <td>{pool.reputation}</td>
              <td>{pool.nextBeneficiary}</td>
              <td>{pool.mutualProjects}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <div className={styles.socialTrust}>
        <h2>Social Trust & Endorsements</h2>
        <p>Build your reputation by collaborating on projects and receiving endorsements from other filmmakers.</p>
        <ul>
          <li>Endorsements and mutual projects increase your pool reputation.</li>
          <li>Verified members are prioritized for funding rounds.</li>
        </ul>
      </div>
    </div>
  );
};

export default CoEPPools;
