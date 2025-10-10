import React, { useState } from 'react';
import styles from '../../styles/Layout/HamburgerMenu.module.css';
import { Link } from 'react-router-dom';
import { FaHome, FaTachometerAlt, FaUsers, FaFilm, FaSignInAlt, FaUser, FaCog, FaMoon, FaBell, FaEnvelope } from 'react-icons/fa';

const HamburgerMenu: React.FC<{ open: boolean; onClose: () => void; darkMode: boolean; toggleDarkMode: () => void }> = ({ open, onClose, darkMode, toggleDarkMode }) => {
  const [showNotifications, setShowNotifications] = useState(false);

  if (!open) return null;

  return (
    <div className={styles.overlay} onClick={onClose}>
      <nav className={styles.menu} onClick={e => e.stopPropagation()}>
        <button className={styles.closeBtn} onClick={onClose}>&times;</button>
        <ul className={styles.menuList}>
          <li><Link to="/" onClick={onClose}><FaHome /> Home</Link></li>
          <li><Link to="/dashboard" onClick={onClose}><FaTachometerAlt /> Dashboard</Link></li>
          <li><Link to="/pool-dashboard" onClick={onClose}><FaUsers /> Funding Pool</Link></li>
          <li><Link to="/verify-films" onClick={onClose}><FaFilm /> Verify Films</Link></li>
          <li><Link to="/login" onClick={onClose}><FaSignInAlt /> Login / Logout</Link></li>
          <li><Link to="/profile" onClick={onClose}><FaUser /> My Profile</Link></li>
          <li><Link to="/settings" onClick={onClose}><FaCog /> Settings</Link></li>
          <li><button className={styles.menuBtn} onClick={toggleDarkMode}><FaMoon /> {darkMode ? 'Light Mode' : 'Dark Mode'}</button></li>
          <li>
            <button className={styles.menuBtn} onClick={() => setShowNotifications(!showNotifications)}><FaBell /> Notifications</button>
            {showNotifications && (
              <div className={styles.notificationsPanel}>
                <p>No new notifications.</p>
              </div>
            )}
          </li>
          <li><Link to="/contact" onClick={onClose}><FaEnvelope /> Contact / Support</Link></li>
        </ul>
      </nav>
    </div>
  );
};

export default HamburgerMenu;
