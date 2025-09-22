

import React, { useState } from 'react';
import styles from '../styles/pages/Waitlist.module.css';

const questions = [
  {
    text: "What's your primary role in the creative industry?",
    name: 'role',
    type: 'radio',
    options: [
      'Independent Filmmaker/Director',
      'Producer/Executive Producer',
      'Screenwriter/Content Creator',
      'Investor/Film Financier',
      'Creative Services Provider (VFX, animation,Post-production, music scores etc.)',
      'Film Enthusiast/Potential Investor',
      'Other',
    ],
    otherName: 'roleOther',
  },
  {
    text: "What's your experience with blockchain/crypto?",
    name: 'experience',
    type: 'radio',
    options: [
      'Complete beginner - never used crypto',
      'Some knowledge - own crypto but never used DeFi (Decentralized Finance',
      'Moderate - used DeFi platforms before',
      'Advanced - actively developed or invested in blockchain projects',
    ],
  },
  {
    text: "What's your biggest challenge in film and video content financing today?",
    name: 'challenge',
    type: 'radio',
    options: [
      'Finding initial capital to start projects',
      'Maintaining creative control and digital rights management (DRM) while securing funding',
      'Connecting with the right investors who understand my vision',
      'Managing multiple funding sources and stakeholders',
      'Lack of transparency in traditional funding processes',
      'Other',
    ],
    otherName: 'challengeOther',
  },
  {
    text: 'Which CineX feature excites you most?',
    name: 'feature',
    type: 'radio',
    options: [
      'Co-EP (Collaborative Executive Producer) investment model',
      'NFT-based film asset ownership',
      'Transparent, blockchain-verified funding',
      'Community-driven project selection',
      'Revenue sharing through smart contracts',
    ],
  },
  {
    text: 'How much would you typically invest in independent film projects?',
    name: 'investment',
    type: 'radio',
    options: [
      '$100 - $1,000',
      '$1,000 - $5,000',
      '$5,000 - $25,000',
      '$25,000 - $100,000',
      '$100,000+',
      "I'm primarily seeking funding, not investing",
    ],
  },
  {
    text: 'If you had these two features or instances on CineX, what would make you most confident investing or raising funding for your film project through a platform like CineX?',
    name: 'confidence',
    type: 'checkbox',
    options: [
      'Previous successful projects on the platform',
      'Clear legal framework and compliance',
      'Strong community of verified creatives',
      'Detailed project analytics and transparency',
      'Integration with traditional film distribution',
    ],
  },
  {
    text: 'How did you hear about CineX?',
    name: 'heardFrom',
    type: 'radio',
    options: [
      'Telegram community',
      'Stacks ecosystem event/community',
      'Social media (specify platform)',
      'Word of mouth/referral',
      'Other blockchain/film community',
    ],
  },
  {
    text: "What's the best way to keep you updated on CineX progress?",
    name: 'updates',
    type: 'radio',
    options: [
      'Email newsletters',
      'Telegram community updates',
      'In-app notifications',
      'Monthly video updates',
      'Community calls/AMAs (Ask Me Anything)',
    ],
  },
];

const Waitlist: React.FC = () => {
  const [formData, setFormData] = useState({
    role: '',
    roleOther: '',
    experience: '',
    challenge: '',
    challengeOther: '',
    feature: '',
    investment: '',
    confidence: [],
    heardFrom: '',
    heardFromOther: '',
    updates: '',
  });

  const [message, setMessage] = useState('');

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value, type } = e.target;
    if (type === 'checkbox') {
      const { checked } = e.target as HTMLInputElement;
      setFormData((prev) => ({
        ...prev,
        confidence: checked
          ? [...prev.confidence, value]
          : prev.confidence.filter((item) => item !== value),
      }));
    } else {
      setFormData((prev) => ({ ...prev, [name]: value }));
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    console.log('Waitlist form data:', formData);
    setMessage('Thank you for your interest! We will keep you updated.');
  };

  return (
    <div className={styles.waitlist}>
      <div className={styles.container}>
        <h1>Join the CineX Waitlist</h1>
        <p>Help us shape the future of film financing. Answer a few questions to join our exclusive community.</p>
        
        {message ? (
          <p className={styles.successMessage}>{message}</p>
        ) : (
          <form onSubmit={handleSubmit} className={styles.form}>
            {questions.map((q, index) => (
              <div key={q.name} className={styles.question}>
                <label>{`${index + 1}. ${q.text}`}</label>
                {q.options.map((option) => (
                  <div key={option}>
                    <input
                      type={q.type}
                      id={option}
                      name={q.name}
                      value={option}
                      checked={
                        q.type === 'checkbox'
                          ? formData.confidence.includes(option)
                          : formData[q.name] === option
                      }
                      onChange={handleChange}
                    />
                    <label htmlFor={option}>{option}</label>
                  </div>
                ))}
                {q.otherName && formData[q.name] === 'Other' && (
                  <input
                    type="text"
                    name={q.otherName}
                    placeholder="Please specify"
                    onChange={handleChange}
                    className={styles.otherInput}
                  />
                )}
              </div>
            ))}
            <p className={styles.disclaimer}>
              Please note: This form is for demonstration purposes only. Your answers are not yet being stored.
            </p>
            <button type="submit" className={styles.submitButton}>Submit</button>
          </form>
        )}
      </div>
    </div>
  );
};

export default Waitlist;
