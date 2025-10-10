import React from 'react';
import styles from '../../styles/components/Testimonials.module.css';

const testimonials = [
  {
    name: 'Jane Filmmaker',
    quote: 'CineX helped me bring my dream documentary to life. The support from the community was incredible!',
    project: 'Voices of the Ocean',
    avatar: 'https://randomuser.me/api/portraits/women/44.jpg',
  },
  {
    name: 'Alex Producer',
    quote: 'The crowdfunding process was smooth and transparent. I loved the platform’s creative energy!',
    project: 'City Lights',
    avatar: 'https://randomuser.me/api/portraits/men/32.jpg',
  },
  {
    name: 'Sam Supporter',
    quote: 'Supporting indie films on CineX is fun and rewarding. I even got a special NFT for my contribution!',
    project: 'Indie Animators',
    avatar: 'https://randomuser.me/api/portraits/men/65.jpg',
  },
];

const Testimonials: React.FC = () => (
  <section className={styles.testimonialsSection}>
    <h2 className={styles.heading}>Success Stories</h2>
    <div className={styles.testimonialsGrid}>
      {testimonials.map((t, idx) => (
        <div className={styles.testimonialCard} key={idx}>
          <img src={t.avatar} alt={t.name} className={styles.avatar} />
          <blockquote className={styles.quote}>{t.quote}</blockquote>
          <div className={styles.meta}>
            <span className={styles.name}>{t.name}</span>
            <span className={styles.project}>on <strong>{t.project}</strong></span>
          </div>
        </div>
      ))}
    </div>
  </section>
);

export default Testimonials;
