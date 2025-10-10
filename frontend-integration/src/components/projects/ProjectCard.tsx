import React from 'react';
import { FaInfoCircle } from 'react-icons/fa';
import { Link } from 'react-router-dom';
import styles from '../../styles/components/ProjectCard.module.css';

export interface Project {
  id: string;
  thumbnailUrl: string;
  title: string;
  creator: string;
  type: string; // e.g. Film, Music, Art, Podcast, Animation, Comedy, etc.
  description: string;
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
    <Link to={`/campaigns/${project.id}`} className={styles.cardLink}>
      <div className={styles.card}>
        <div className={styles.thumbnail}>
          <img src={project.thumbnailUrl} alt={`${project.title} thumbnail`} />
        </div>
        <div className={styles.info}>
          <div className={styles.campaignHeader}>
            <h3 className={styles.title}>{project.title}</h3>
            <span className={styles.campaignInfo} title="A campaign is a fundraising effort by a creative or entertainment professional to bring their project to life.">
              <FaInfoCircle />
            </span>
          </div>
          <p className={styles.filmmaker}>by {project.creator} &middot; <span className={styles.type}>{project.type}</span></p>
          <p className={styles.description}>{project.description}</p>
          <div className={styles.funding}>
            <div className={styles.progressBar}>
              <div
                className={styles.progress}
                style={{ width: `${fundingPercentage}%` }}
              ></div>
            </div>
            <div className={styles.fundingText}>
              <span>Raised: ${project.fundingCurrent.toLocaleString()} / ${project.fundingGoal.toLocaleString()}</span>
              <span>{project.daysLeft} days left</span>
            </div>
          </div>
        </div>
      </div>
    </Link>
  );
};

export default ProjectCard;
