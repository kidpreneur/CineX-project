import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import styles from '../../styles/Layout/Header.module.css';

const Header: React.FC = () => {
  const [menuOpen, setMenuOpen] = useState(false);

  const toggleMenu = () => {
    setMenuOpen(!menuOpen);
  };

  return (
    <header className={styles.header}>
      <div className={styles.logo}>
        <Link to="/">CineX</Link>
      </div>
      <button className={styles.hamburger} onClick={toggleMenu}>
        {/* A simple hamburger icon using spans */}
        <span className={styles.bar}></span>
        <span className={styles.bar}></span>
        <span className={styles.bar}></span>
      </button>
      <nav className={`${styles.nav} ${menuOpen ? styles.navOpen : ''}`}>
          <Link to="/">Home</Link>
          <Link to="/projects">Projects</Link>
          <Link to="/waitlist">Waitlist</Link>
          <Link to="/dashboard">Dashboard</Link>
          <button className={styles.connectButton}>Connect Wallet</button>
      </nav>
    </header>
  );
};

export default Header;
