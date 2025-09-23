import React from 'react';
import { Link } from 'react-router-dom';
import styles from '../styles/pages/Home.module.css';

const Home: React.FC = () => {
  return (
    <div className={styles.home}>
      <section className={styles.hero}>
        <h1>CineX: The Future of Film Funding</h1>
        <Link to="/waitlist" className={styles.waitlistButton}>
          Join Waitlist
        </Link>
      </section>
      <section className={styles.featured}>
        <h2>Featured Projects</h2>
        <div className={styles.projectGrid}>
          {/* Placeholder for project cards */}
          <div className={styles.projectCard}>Project 1</div>
          <div className={styles.projectCard}>Project 2</div>
          <div className={styles.projectCard}>Project 3</div>
        </div>
      </section>
    </div>
  );
};

export default Home;
