import React, { useState, useEffect } from 'react';
import styles from '../../styles/components/ClaimRewardModal.module.css';
import { FaGift, FaCheckCircle } from 'react-icons/fa';

const rewardFields = [
  { label: 'Reward NFT', value: '🎬 CineX Contributor NFT' },
  { label: 'Campaign', value: 'Cosmic Wanderers' },
  { label: 'Tier', value: 'Gold' },
  { label: 'Claimable Amount', value: '1 NFT' },
  { label: 'Status', value: 'Unclaimed' },
];

const ClaimRewardModal: React.FC<{ open: boolean; onClose: () => void }> = ({ open, onClose }) => {
  const [visibleFields, setVisibleFields] = useState<number>(0);
  const [claimed, setClaimed] = useState(false);

  useEffect(() => {
    if (open) {
      setVisibleFields(0);
      setClaimed(false);
      const timer = setInterval(() => {
        setVisibleFields((prev) => {
          if (prev < rewardFields.length) return prev + 1;
          clearInterval(timer);
          return prev;
        });
      }, 2000);
      return () => clearInterval(timer);
    }
  }, [open]);

  const handleClaim = () => {
    setClaimed(true);
    setTimeout(onClose, 2000);
  };

  if (!open) return null;

  return (
    <div className={styles.overlay}>
      <div className={styles.modal}>
        <button className={styles.closeBtn} onClick={onClose}>&times;</button>
        <div className={styles.header}><FaGift className={styles.icon} /> Claim Your Reward</div>
        <div className={styles.fieldsGrid}>
          {rewardFields.slice(0, visibleFields).map((field, idx) => (
            <div
              key={field.label}
              className={styles.field + ' ' + styles.animated + ' ' + styles[`animate${idx%4}`]}
              style={{ animationDelay: `${idx * 0.2}s` }}
            >
              <span className={styles.label}>{field.label}:</span>
              <span className={styles.value}>{field.value}</span>
            </div>
          ))}
        </div>
        {visibleFields === rewardFields.length && !claimed && (
          <button className={styles.claimBtn} onClick={handleClaim}>Claim Reward</button>
        )}
        {claimed && (
          <div className={styles.successMsg}><FaCheckCircle className={styles.successIcon} /> Reward claimed!</div>
        )}
      </div>
    </div>
  );
};

export default ClaimRewardModal;
