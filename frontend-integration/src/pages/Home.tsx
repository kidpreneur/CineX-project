import React from 'react';
import { Link } from 'react-router-dom';
import styles from '../styles/pages/Home.module.css';
import ProjectCard from '../components/projects/ProjectCard';
import { placeholderProjects } from '../data/projects';

const Home: React.FC = () => {
  return (
    <div className={styles.home}>
      <section className={styles.hero}>
        <h1>Invest Together. Create Together.</h1>
        <p className={styles.subtitle}>The decentralized platform for funding the next generation of films.</p>
        <div className={styles.ctaButtons}>
          <Link to="/projects" className={styles.ctaPrimary}>
            Get Started
          </Link>
          <Link to="/projects" className={styles.ctaSecondary}>
            Explore Projects
          </Link>
        </div>
      </section>

      <section className={styles.overview}>
        <div className={styles.overviewContent}>
          <h2>What is CineX?</h2>
          <p>
            CineX is a revolutionary platform that connects filmmakers with investors, leveraging the power of blockchain technology to create a transparent, efficient, and community-driven funding ecosystem. Whether you're a creator with a vision or an investor looking for the next big hit, CineX empowers you to be part of the filmmaking journey.
          </p>
        </div>
      </section>

      <section className={styles.featured}>
        <h2>Featured Projects</h2>
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
