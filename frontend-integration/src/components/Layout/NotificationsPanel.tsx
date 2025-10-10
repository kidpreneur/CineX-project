import React from 'react';
import styles from '../../styles/Layout/NotificationsPanel.module.css';
import { FaBell } from 'react-icons/fa';

const mockNotifications = [
  { id: 1, message: 'Your campaign "Cosmic Wanderers" reached 50% funding!' },
  { id: 2, message: 'You received a new endorsement on your portfolio.' },
  { id: 3, message: 'Platform update: New features added to funding pools.' },
];

const NotificationsPanel: React.FC<{ open: boolean; onClose: () => void }> = ({ open, onClose }) => {
  if (!open) return null;
  return (
    <div className={styles.overlay} onClick={onClose}>
      <div className={styles.panel} onClick={e => e.stopPropagation()}>
        <div className={styles.header}>
          <FaBell className={styles.icon} />
          <span>Notifications</span>
          <button className={styles.closeBtn} onClick={onClose}>&times;</button>
        </div>
        <ul className={styles.list}>
          {mockNotifications.length === 0 ? (
            <li className={styles.empty}>No new notifications.</li>
          ) : (
            mockNotifications.map(n => <li key={n.id}>{n.message}</li>)
          )}
        </ul>
      </div>
    </div>
  );
};

export default NotificationsPanel;
