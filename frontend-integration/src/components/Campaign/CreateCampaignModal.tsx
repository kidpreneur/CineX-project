import React, { useState, useEffect } from 'react';
import styles from '../../styles/components/CreateCampaignModal.module.css';

const formFields = [
  { label: 'Campaign Title', name: 'title', type: 'text', placeholder: 'e.g. The Next Big Film' },
  { label: 'Description', name: 'description', type: 'textarea', placeholder: 'Describe your project (max 500 chars)' },
  { label: 'Funding Goal (STX)', name: 'fundingGoal', type: 'number', placeholder: 'e.g. 10000' },
  { label: 'Duration (days)', name: 'duration', type: 'number', placeholder: 'e.g. 30' },
  { label: 'Number of Reward Tiers', name: 'rewardTiers', type: 'number', placeholder: 'e.g. 3' },
  { label: 'Reward Descriptions', name: 'rewardDescriptions', type: 'textarea', placeholder: 'Describe each reward tier, separated by line' },
  { label: 'Creator Name', name: 'creatorName', type: 'text', placeholder: 'Your name' },
  { label: 'Portfolio Links', name: 'portfolio', type: 'text', placeholder: 'Links to previous works (comma separated)' },
  { label: 'Category/Genre', name: 'category', type: 'text', placeholder: 'e.g. Film, Music, Art' },
  { label: 'Thumbnail Image', name: 'thumbnail', type: 'file', placeholder: '' },
  { label: 'Supporting Document', name: 'supportDoc', type: 'file', placeholder: '' },
  { label: 'Agree to Terms', name: 'terms', type: 'checkbox', placeholder: '' },
];

const CreateCampaignModal: React.FC<{ open: boolean; onClose: () => void }> = ({ open, onClose }) => {
  const [visibleFields, setVisibleFields] = useState<number>(0);
  const [form, setForm] = useState<any>({});

  useEffect(() => {
    if (open) {
      setVisibleFields(0);
      const timer = setInterval(() => {
        setVisibleFields((prev) => {
          if (prev < formFields.length) return prev + 1;
          clearInterval(timer);
          return prev;
        });
      }, 2000);
      return () => clearInterval(timer);
    }
  }, [open]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value, type, checked, files } = e.target as any;
    if (type === 'checkbox') {
      setForm({ ...form, [name]: checked });
    } else if (type === 'file') {
      setForm({ ...form, [name]: files[0] });
    } else {
      setForm({ ...form, [name]: value });
    }
  };

  if (!open) return null;

  return (
    <div className={styles.modalOverlay}>
      <div className={styles.modal}>
        <button className={styles.closeBtn} onClick={onClose}>&times;</button>
        <h2 className={styles.heading}>Create a Campaign</h2>
        <div className={styles.scrollIndicator}>
          <span className={styles.arrow} />
        </div>
        <form className={styles.form}>
          <div className={styles.formScrollable}>
            {formFields.slice(0, visibleFields).map((field, idx) => (
              <div
                key={field.name}
                className={styles.formGroup + ' ' + styles.animated + ' ' + styles[`animate${idx%4}`]}
                style={{ animationDelay: `${idx * 0.2}s` }}
              >
                <label className={styles.label}>{field.label}</label>
                {field.type === 'textarea' ? (
                  <textarea
                    name={field.name}
                    placeholder={field.placeholder}
                    className={styles.input}
                    value={form[field.name] || ''}
                    onChange={handleChange}
                    disabled={visibleFields <= idx}
                  />
                ) : field.type === 'checkbox' ? (
                  <input
                    type="checkbox"
                    name={field.name}
                    checked={!!form[field.name]}
                    onChange={handleChange}
                    disabled={visibleFields <= idx}
                  />
                ) : (
                  <input
                    type={field.type}
                    name={field.name}
                    placeholder={field.placeholder}
                    className={styles.input}
                    value={field.type === 'file' ? undefined : form[field.name] || ''}
                    onChange={handleChange}
                    disabled={visibleFields <= idx}
                  />
                )}
              </div>
            ))}
          </div>
          {visibleFields === formFields.length && (
            <button className={styles.submitBtn} type="submit">Submit Campaign</button>
          )}
        </form>
      </div>
    </div>
  );
};

export default CreateCampaignModal;
