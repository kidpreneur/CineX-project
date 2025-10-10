import React, { useState } from 'react';
import styles from '../../styles/components/FundCampaignModal.module.css';

const FundCampaignModal: React.FC<{ open: boolean; onClose: () => void; campaignTitle?: string }> = ({ open, onClose, campaignTitle }) => {
  const [amount, setAmount] = useState('');
  const [showSuccess, setShowSuccess] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setShowSuccess(true);
    setTimeout(() => {
      setShowSuccess(false);
      onClose();
    }, 2000);
  };

  if (!open) return null;

  return (
    <div className={styles.overlay}>
      <div className={styles.modal}>
        <button className={styles.closeBtn} onClick={onClose}>&times;</button>
        <h2 className={styles.heading}>Fund Campaign</h2>
        <p className={styles.campaignTitle}>{campaignTitle || 'Campaign'}</p>
        <form className={styles.form} onSubmit={handleSubmit}>
          <label className={styles.label}>
            Amount (STX)
            <input
              type="number"
              min="1"
              className={styles.input}
              value={amount}
              onChange={e => setAmount(e.target.value)}
              required
            />
          </label>
          <button className={styles.submitBtn} type="submit">Fund</button>
        </form>
        {showSuccess && <div className={styles.successMsg}>Thank you for supporting this campaign!</div>}
      </div>
    </div>
  );
};

export default FundCampaignModal;
