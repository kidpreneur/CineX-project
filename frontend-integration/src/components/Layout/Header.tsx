import React, { useState } from 'react';
import styles from '../../styles/Layout/Header.module.css';

const Header: React.FC = () => {
  const [menuOpen, setMenuOpen] = useState(false);

  const toggleMenu = () => {
    setMenuOpen(!menuOpen);
  };

  return (
    <header className={styles.header}>
      <div className={styles.logo}>
        <a href="/">CineX</a>
      </div>
      <button className={styles.hamburger} onClick={toggleMenu}>
        {/* A simple hamburger icon using spans */}
        <span className={styles.bar}></span>
        <span className={styles.bar}></span>
        <span className={styles.bar}></span>
      </button>
      <nav className={`${styles.nav} ${menuOpen ? styles.navOpen : ''}`}>
        <a href="/">Home</a>
        <a href="/projects">Projects</a>
        <a href="/dashboard">Dashboard</a>
        <button className={styles.connectButton}>Connect Wallet</button>
      </nav>
    </header>
  );
};

export default Header;
