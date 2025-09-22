import React from 'react';
import { Link } from 'react-router-dom';
import styles from '../styles/pages/Home.module.css';
import { MdSearch, MdAttachMoney, MdCardGiftcard } from 'react-icons/md';

const Home: React.FC = () => {
  return (
    <div className={styles.home}>
      <section className={styles.hero}>
        <h1>CineX: Invest Together. Create Together.</h1>
        <Link to="/projects" className={styles.ctaButton}>
          Explore Projects
        </Link>
      </section>
      <section className={styles.howItWorks}>
        <h2>How It Works</h2>
        <div className={styles.stepsGrid}>
          <div className={styles.step}>
            <div className={styles.stepIcon}><MdSearch /></div>
            <h3>1. Discover</h3>
            <p>Explore a curated selection of unique film projects from talented creators around the world.</p>
          </div>
          <div className={styles.step}>
            <div className={styles.stepIcon}><MdAttachMoney /></div>
            <h3>2. Fund</h3>
            <p>Invest in the projects you believe in. Your contribution directly supports the filmmakers and their vision.</p>
          </div>
          <div className={styles.step}>
            <div className={styles.stepIcon}><MdCardGiftcard /></div>
            <h3>3. Reward</h3>
            <p>Receive exclusive rewards, including NFTs, merchandise, and behind-the-scenes access.</p>
          </div>
        </div>
      </section>
      <section className={styles.testimonials}>
        <h2>What Our Community is Saying</h2>
        <div className={styles.testimonialGrid}>
          <div className={styles.testimonialCard}>
            <p className={styles.quote}>"CineX helped me bring my dream project to life. The community is incredibly supportive!"</p>
            <span className={styles.author}>- Alex, Filmmaker</span>
          </div>
          <div className={styles.testimonialCard}>
            <p className={styles.quote}>"As an investor, I love being able to support independent cinema and get unique NFT rewards."</p>
            <span className={styles.author}>- Sarah, Investor</span>
          </div>
          <div className={styles.testimonialCard}>
            <p className={styles.quote}>"A revolutionary platform for the film industry. Highly recommended!"</p>
            <span className={styles.author}>- David, Producer</span>
          </div>
        </div>
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
