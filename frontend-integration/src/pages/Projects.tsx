import React from 'react';
import { Link } from 'react-router-dom';
import styles from '../styles/pages/Projects.module.css';


// --- Start of in-lined ProjectCard component ---

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
  );
};

// --- End of in-lined ProjectCard component ---


// Define a type for the category structure for better type safety
interface GenreCategory {
  name: string;
  genres: string[];
}

const genreCategories: GenreCategory[] = [
    { name: "Film & Video", genres: ["Animation", "Documentary", "Feature Film", "Short Film", "Music Video", "Web Series", "TV Series", "Experimental Film", "Nollywood", "Bollywood", "Hollywood", "Silent Film", "Foreign Language Film"] },
    { name: "Audio & Music", genres: ["Album/LP", "EP (Extended Play)", "Single", "Music Production", "Soundtrack / Film Score", "Podcast", "Audiobook", "Radio Show / Audio Drama", "Live Concert Recording"] },
    { name: "Performing Arts", genres: ["Theatre / Play", "Musical", "Dance Performance", "Stand-up Comedy Special", "Immersive Experience", "Circus Arts", "Opera"] },
    { name: "Publishing & Written Word", genres: ["Fiction Novel", "Non-Fiction Book", "Comic Book / Graphic Novel", "Art Book", "Poetry Collection", "Magazine / Zine", "Children's Book", "Screenplay / Script"] },
    { name: "Games", genres: ["Video Game (Indie)", "Mobile Game", "Tabletop Game / Board Game", "Card Game", "Role-Playing Game (RPG)"] },
    { name: "Digital & New Media", genres: ["Storytelling (Interactive/Digital)", "Vlogging / YouTube Content", "VR / AR Experience", "Interactive Narrative", "Educational Content Series"] },
    { name: "Art & Design", genres: ["Photography Exhibition/Book", "Illustration Series", "Fashion Collection/Show", "Public Art Installation"] }
];

// Placeholder data for projects
const placeholderProjects: Project[] = [
  { id: '1', thumbnailUrl: 'https://via.placeholder.com/400x225.png/222/FFBF00?text=Project+A', title: 'Echoes of the Void', filmmaker: 'Jane Doe', fundingCurrent: 75000, fundingGoal: 100000, daysLeft: 15 },
  { id: '2', thumbnailUrl: 'https://via.placeholder.com/400x225.png/222/FFBF00?text=Project+B', title: 'Cyber Sunset', filmmaker: 'John Smith', fundingCurrent: 45000, fundingGoal: 50000, daysLeft: 30 },
  { id: '3', thumbnailUrl: 'https://via.placeholder.com/400x225.png/222/FFBF00?text=Project+C', title: 'The Last Artisan', filmmaker: 'Emily White', fundingCurrent: 120000, fundingGoal: 200000, daysLeft: 45 },
  { id: '4', thumbnailUrl: 'https://via.placeholder.com/400x225.png/222/FFBF00?text=Project+D', title: 'Forgotten Melodies', filmmaker: 'Michael Brown', fundingCurrent: 25000, fundingGoal: 60000, daysLeft: 20 },
  { id: '5', thumbnailUrl: 'https://via.placeholder.com/400x225.png/222/FFBF00?text=Project+E', title: 'Beneath the Surface', filmmaker: 'Sarah Green', fundingCurrent: 95000, fundingGoal: 100000, daysLeft: 5 },
  { id: '6', thumbnailUrl: 'https://via.placeholder.com/400x225.png/222/FFBF00?text=Project+F', title: 'City of Glass', filmmaker: 'David Black', fundingCurrent: 30000, fundingGoal: 150000, daysLeft: 60 },
];



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
        {placeholderProjects.map(project => (
          <Link to={`/projects/${project.id}`} key={project.id} className={styles.projectLink}>
            <ProjectCard project={project} />
          </Link>
        ))}
      </div>
      <div className={styles.pagination}>
        <button>Previous</button>
        <button>Next</button>
      </div>
    </div>
  );
};

export default Projects;
