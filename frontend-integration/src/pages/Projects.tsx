import React from 'react';
import styles from '../styles/pages/Projects.module.css';

// Define a type for the category structure for better type safety
interface GenreCategory {
  name: string;
  genres: string[];
}

const genreCategories: GenreCategory[] = [
  {
    name: "Film & Video",
    genres: [
      "Animation", "Documentary", "Feature Film", "Short Film", "Music Video",
      "Web Series", "TV Series", "Experimental Film", "Nollywood", "Bollywood",
      "Hollywood", "Silent Film", "Foreign Language Film"
    ]
  },
  {
    name: "Audio & Music",
    genres: [
      "Album/LP", "EP (Extended Play)", "Single", "Music Production",
      "Soundtrack / Film Score", "Podcast", "Audiobook", "Radio Show / Audio Drama",
      "Live Concert Recording"
    ]
  },
  {
    name: "Performing Arts",
    genres: [
      "Theatre / Play", "Musical", "Dance Performance", "Stand-up Comedy Special",
      "Immersive Experience", "Circus Arts", "Opera"
    ]
  },
  {
    name: "Publishing & Written Word",
    genres: [
      "Fiction Novel", "Non-Fiction Book", "Comic Book / Graphic Novel", "Art Book",
      "Poetry Collection", "Magazine / Zine", "Children's Book", "Screenplay / Script"
    ]
  },
  {
    name: "Games",
    genres: [
      "Video Game (Indie)", "Mobile Game", "Tabletop Game / Board Game",
      "Card Game", "Role-Playing Game (RPG)"
    ]
  },
  {
    name: "Digital & New Media",
    genres: [
      "Storytelling (Interactive/Digital)", "Vlogging / YouTube Content",
      "VR / AR Experience", "Interactive Narrative", "Educational Content Series"
    ]
  },
  {
    name: "Art & Design",
    genres: [
      "Photography Exhibition/Book", "Illustration Series", "Fashion Collection/Show",
      "Public Art Installation"
    ]
  }
];


const Projects: React.FC = () => {
  // Helper to convert genre names to kebab-case values
  const toKebabCase = (str: string) => str.toLowerCase().replace(/\s+/g, '-').replace(/[/()]/g, '');

  return (
    <div className={styles.projectsPage}>
      <header className={styles.header}>
        <h1>Explore Film Projects</h1>
        <div className={styles.searchAndFilter}>
          <input type="text" placeholder="Search projects..." className={styles.searchInput} />
          <select className={styles.filterSelect}>
            <option value="">All Genres</option>
            {genreCategories.map((category, index) => (
              <optgroup key={index} label={`${index + 1}. ${category.name}`} className={styles.categoryLabel}>
                {category.genres.map((genre, genreIndex) => (
                  <option key={genreIndex} value={toKebabCase(genre)}>
                    {genre}
                  </option>
                ))}
              </optgroup>
            ))}
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
