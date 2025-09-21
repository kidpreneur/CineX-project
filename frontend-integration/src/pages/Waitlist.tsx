import React, { useState } from 'react';
import styles from '../styles/pages/Waitlist.module.css';

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
    setMessage('Thank you for joining our waitlist! We will keep you updated.');
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
            {/* Question 1 */}
            <div className={styles.question}>
              <label>"What's your primary role in the creative industry?"</label>
              {[
                'Independent Filmmaker/Director',
                'Producer/Executive Producer',
                'Screenwriter/Content Creator',
                'Investor/Film Financier',
                'Creative Services Provider (VFX, animation,Post-production, music scores etc.)',
                'Film Enthusiast/Potential Investor',
              ].map((role) => (
                <div key={role}>
                  <input type="radio" id={role} name="role" value={role} onChange={handleChange} />
                  <label htmlFor={role}>{role}</label>
                </div>
              ))}
              <div>
                <input type="radio" id="roleOther" name="role" value="Other" onChange={handleChange} />
                <label htmlFor="roleOther">Other</label>
                {formData.role === 'Other' && (
                  <input type="text" name="roleOther" placeholder="Please specify" onChange={handleChange} className={styles.otherInput} />
                )}
              </div>
            </div>

            {/* Question 2 */}
            <div className={styles.question}>
              <label>"What's your experience with blockchain/crypto?"</label>
              {[
                'Complete beginner - never used crypto',
                'Some knowledge - own crypto but never used DeFi (Decentralized Finance',
                'Moderate - used DeFi platforms before',
                'Advanced - actively developed or invested in blockchain projects',
              ].map((exp) => (
                <div key={exp}>
                  <input type="radio" id={exp} name="experience" value={exp} onChange={handleChange} />
                  <label htmlFor={exp}>{exp}</label>
                </div>
              ))}
            </div>

            {/* Question 3 */}
            <div className={styles.question}>
              <label>"What's your biggest challenge in film and video content financing today?"</label>
              {[
                'Finding initial capital to start projects',
                'Maintaining creative control and digital rights management (DRM) while securing funding',
                'Connecting with the right investors who understand my vision',
                'Managing multiple funding sources and stakeholders',
                'Lack of transparency in traditional funding processes',
              ].map((challenge) => (
                <div key={challenge}>
                  <input type="radio" id={challenge} name="challenge" value={challenge} onChange={handleChange} />
                  <label htmlFor={challenge}>{challenge}</label>
                </div>
              ))}
              <div>
                <input type="radio" id="challengeOther" name="challenge" value="Other" onChange={handleChange} />
                <label htmlFor="challengeOther">Other</label>
                {formData.challenge === 'Other' && (
                  <input type="text" name="challengeOther" placeholder="Please specify" onChange={handleChange} className={styles.otherInput} />
                )}
              </div>
            </div>

            {/* Question 4 */}
            <div className={styles.question}>
              <label>"Which CineX feature excites you most?"</label>
              {[
                'Co-EP (Collaborative Executive Producer) investment model',
                'NFT-based film asset ownership',
                'Transparent, blockchain-verified funding',
                'Community-driven project selection',
                'Revenue sharing through smart contracts',
              ].map((feature) => (
                <div key={feature}>
                  <input type="radio" id={feature} name="feature" value={feature} onChange={handleChange} />
                  <label htmlFor={feature}>{feature}</label>
                </div>
              ))}
            </div>

            {/* Question 5 */}
            <div className={styles.question}>
              <label>"How much would you typically invest in independent film projects?"</label>
              {[
                '$100 - $1,000',
                '$1,000 - $5,000',
                '$5,000 - $25,000',
                '$25,000 - $100,000',
                '$100,000+',
                "I'm primarily seeking funding, not investing",
              ].map((investment) => (
                <div key={investment}>
                  <input type="radio" id={investment} name="investment" value={investment} onChange={handleChange} />
                  <label htmlFor={investment}>{investment}</label>
                </div>
              ))}
            </div>

            {/* Question 6 */}
            <div className={styles.question}>
              <label>"If you had these two features or instances on CineX, what would make you most confident investing or raising funding for your film project through a platform like CineX?"</label>
              {[
                'Previous successful projects on the platform',
                'Clear legal framework and compliance',
                'Strong community of verified creatives',
                'Detailed project analytics and transparency',
                'Integration with traditional film distribution',
              ].map((confidence) => (
                <div key={confidence}>
                  <input type="checkbox" id={confidence} name="confidence" value={confidence} onChange={handleChange} />
                  <label htmlFor={confidence}>{confidence}</label>
                </div>
              ))}
            </div>

            {/* Question 7 */}
            <div className={styles.question}>
              <label>"How did you hear about CineX?"</label>
              {[
                'Telegram community',
                'Stacks ecosystem event/community',
                'Social media (specify platform)',
                'Word of mouth/referral',
              ].map((heardFrom) => (
                <div key={heardFrom}>
                  <input type="radio" id={heardFrom} name="heardFrom" value={heardFrom} onChange={handleChange} />
                  <label htmlFor={heardFrom}>{heardFrom}</label>
                </div>
              ))}
              <div>
                <input type="radio" id="heardFromOther" name="heardFrom" value="Other blockchain/film community" onChange={handleChange} />
                <label htmlFor="heardFromOther">Other blockchain/film community</label>
              </div>
            </div>

            {/* Question 8 */}
            <div className={styles.question}>
              <label>"What's the best way to keep you updated on CineX progress?"</label>
              {[
                'Email newsletters',
                'Telegram community updates',
                'In-app notifications',
                'Monthly video updates',
                'Community calls/AMAs (Ask Me Anything)',
              ].map((updates) => (
                <div key={updates}>
                  <input type="radio" id={updates} name="updates" value={updates} onChange={handleChange} />
                  <label htmlFor={updates}>{updates}</label>
                </div>
              ))}
            </div>

            <button type="submit" className={styles.submitButton}>Submit</button>
          </form>
        )}
      </div>
    </div>
  );
};

export default Waitlist;
