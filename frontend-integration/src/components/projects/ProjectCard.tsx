import React from 'react';
import { Link } from 'react-router-dom';
import styles from '../../styles/components/ProjectCard.module.css';

export interface Project {
  id: string;
  thumbnailUrl: string;
  title: string;
  filmmaker: string;
  fundingCurrent: number;
  fundingGoal: number;
  daysLeft: number;
}

interface ProjectCardProps {
  project: Project;
}

const ProjectCard: React.FC<ProjectCardProps> = ({ project }) => {
  const fundingPercentage = (project.fundingCurrent / project.fundingGoal) * 100;

  return (
    <Link to={`/projects/${project.id}`} className={styles.cardLink}>
      <div className={styles.card}>
        <div className={styles.thumbnail}>
          <img src={project.thumbnailUrl} alt={`${project.title} thumbnail`} />
        </div>
        <div className={styles.info}>
          <h3 className={styles.title}>{project.title}</h3>
          <p className={styles.filmmaker}>by {project.filmmaker}</p>
          <div className={styles.funding}>
            <div className={styles.progressBar}>
              <div
                className={styles.progress}
                style={{ width: `${fundingPercentage}%` }}
              ></div>
            </div>
            <div className={styles.fundingText}>
              <span>${project.fundingCurrent.toLocaleString()}</span>
              <span>{project.daysLeft} days left</span>
            </div>
          </div>
        </div>
      </div>
    </Link>
  );
};

export default ProjectCard;
