import React from 'react';
import styles from '../../styles/Layout/Footer.module.css';

const Footer: React.FC = () => {
  return (
    <footer className={styles.footer}>
      <div className={styles.links}>
        <a href="/about">About</a>
        <a href="/contact">Contact / Support</a>
        <a href="/terms">Terms of Service</a>
      </div>
      <div className={styles.social}>
        {/* Placeholder for social media icons */}
        <a href="https://twitter.com" target="_blank" rel="noopener noreferrer">Twitter</a>
        <a href="https://facebook.com" target="_blank" rel="noopener noreferrer">Facebook</a>
        <a href="https://instagram.com" target="_blank" rel="noopener noreferrer">Instagram</a>
      </div>
      <div className={styles.copy}>
        &copy; {new Date().getFullYear()} CineX. All Rights Reserved.
      </div>
    </footer>
  );
};

export default Footer;
