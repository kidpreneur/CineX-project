import React from 'react';
import { FaMoon, FaSun } from 'react-icons/fa';
import styles from '../../styles/Layout/DarkModeToggle.module.css';

const DarkModeToggle: React.FC<{ darkMode: boolean; toggleDarkMode: () => void }> = ({ darkMode, toggleDarkMode }) => (
  <button className={styles.toggleBtn} onClick={toggleDarkMode} title={darkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode'}>
    {darkMode ? <FaSun /> : <FaMoon />}
    <span className={styles.label}>{darkMode ? 'Light Mode' : 'Dark Mode'}</span>
  </button>
);

export default DarkModeToggle;
