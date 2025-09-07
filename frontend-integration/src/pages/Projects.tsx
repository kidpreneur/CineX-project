import React from 'react';
import styles from '../styles/pages/Projects.module.css';

const Projects: React.FC = () => {
  return (
    <div className={styles.projectsPage}>
      <header className={styles.header}>
        <h1>Explore Film Projects</h1>
        <div className={styles.searchAndFilter}>
          <input type="text" placeholder="Search projects..." className={styles.searchInput} />
          <select className={styles.filterSelect}>
            <option value="">All Genres</option>
            <option value="documentary">Documentary</option>
            <option value="feature-film">Feature Film</option>
            <option value="short-film">Short Film</option>
          </select>
        </div>
      </header>
      <div className={styles.projectGrid}>
        {/* Placeholder for project cards */}
        <div className={styles.projectCard}>Project A</div>
        <div className={styles.projectCard}>Project B</div>
        <div className={styles.projectCard}>Project C</div>
        <div className={styles.projectCard}>Project D</div>
        <div className={styles.projectCard}>Project E</div>
        <div className={styles.projectCard}>Project F</div>
      </div>
    </div>
  );
};

export default Projects;
