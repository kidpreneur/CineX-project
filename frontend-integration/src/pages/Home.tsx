import React from 'react';
import handsLogo from '../assets/hands-together-logo.svg';
import { Link } from 'react-router-dom';
import styles from '../styles/pages/Home.module.css';
import ProjectCard from '../components/projects/ProjectCard';
import { placeholderProjects } from '../data/projects';

const Home: React.FC = () => {
  return (
    <div className={styles.home}>
      <section className={styles.hero}>
        <div className={styles.heroLogoWrapper}>
          <img src={handsLogo} alt="Hands coming together" className={styles.heroLogo} />
        </div>
  <h1>Welcome to Crowdfunding Platform for Creatives</h1>
  <p className={styles.subtitle}>A platform where people in the creative and entertainment industry raise funds for their projects.</p>
        <div className={styles.ctaButtons}>
          <Link to="/create-campaign" className={styles.ctaPrimary + ' ' + styles.ctaLarge}>
            Create a Campaign
          </Link>
        </div>
        <div className={styles.ctaButtons}>
          <Link to="/campaigns" className={styles.ctaSecondary}>
            Explore Campaigns
          </Link>
        </div>
      </section>

      <section className={styles.overview}>
        <div className={styles.overviewContent}>
          <h2>What is CineX?</h2>
          <p>
            CineX is a revolutionary platform that connects creatives and entertainment professionals with supporters, leveraging the power of blockchain technology to create a transparent, efficient, and community-driven crowdfunding ecosystem. Whether you're a creator with a vision or a supporter looking to back the next big idea, CineX empowers you to be part of the creative journey.
          </p>
        </div>
      </section>

      <section className={styles.featured}>
        <h2>Featured Campaigns</h2>
        <div className={styles.projectGrid}>
          {placeholderProjects.slice(0, 3).map(project => (
            <ProjectCard project={project} key={project.id} />
          ))}
        </div>
      </section>
    </div>
  );
};

export default Home;
