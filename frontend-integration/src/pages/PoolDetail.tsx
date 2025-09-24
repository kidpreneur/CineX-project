import React from 'react';
import styles from '../styles/pages/PoolDetail.module.css';

// Placeholder pool detail data
const pool = {
  name: 'Indie Filmmakers Pool',
  value: '100,000 STX',
  status: 'Forming',
  rotationSchedule: [
    { name: 'Jane Doe', date: '2025-10-01', status: 'Pending' },
    { name: 'John Smith', date: '2025-11-01', status: 'Funded' },
    { name: 'Alex Lee', date: '2025-12-01', status: 'Pending' },
  ],
  members: [
    { name: 'Jane Doe', contribution: 'Contributed' },
    { name: 'John Smith', contribution: 'Pending' },
    { name: 'Alex Lee', contribution: 'Contributed' },
  ],
  beneficiary: {
    name: 'Jane Doe',
    project: 'Cosmic Wanderers',
    details: 'Sci-fi adventure film seeking final round of funding.',
  },
  activity: [
    'Member Jane Doe joined',
    'Member John Smith contributed',
    'Rotation 1 funded to John Smith',
  ],
};

const PoolDetail: React.FC = () => {
  return (
    <div className={styles.poolDetail}>
      <header className={styles.header}>
        <h1>{pool.name}</h1>
        <p><strong>Total Value:</strong> {pool.value}</p>
        <p><strong>Status:</strong> {pool.status}</p>
      </header>
      <section className={styles.rotationSchedule}>
        <h2>Rotation Schedule</h2>
        <ul>
          {pool.rotationSchedule.map((item, idx) => (
            <li key={idx}>
              <strong>{item.name}</strong> - {item.date} - <span>{item.status}</span>
            </li>
          ))}
        </ul>
      </section>
      <section className={styles.members}>
        <h2>Members</h2>
        <ul>
          {pool.members.map((member, idx) => (
            <li key={idx}>
              {member.name} - <span>{member.contribution}</span>
            </li>
          ))}
        </ul>
      </section>
      <section className={styles.beneficiary}>
        <h2>Current Beneficiary</h2>
        <p><strong>Name:</strong> {pool.beneficiary.name}</p>
        <p><strong>Project:</strong> {pool.beneficiary.project}</p>
        <p>{pool.beneficiary.details}</p>
        <button className={styles.contributeBtn}>Contribute Now</button>
      </section>
      <section className={styles.activityFeed}>
        <h2>Activity Feed</h2>
        <ul>
          {pool.activity.map((event, idx) => (
            <li key={idx}>{event}</li>
          ))}
        </ul>
      </section>
    </div>
  );
};

export default PoolDetail;
