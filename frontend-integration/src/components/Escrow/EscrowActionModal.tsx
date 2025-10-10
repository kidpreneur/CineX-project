import React, { useState, useEffect } from 'react';
import styles from '../../styles/components/EscrowActionModal.module.css';
import { FaLock, FaUnlock, FaUndo, FaCheckCircle } from 'react-icons/fa';

const escrowFields = [
  { label: 'Campaign', value: 'Cosmic Wanderers' },
  { label: 'Escrow Balance', value: '6,500 STX' },
  { label: 'Authorized Withdrawal', value: 'Yes' },
  { label: 'Refundable Amount', value: '1,200 STX' },
  { label: 'Status', value: 'Funds in Escrow' },
];

const EscrowActionModal: React.FC<{ open: boolean; onClose: () => void }> = ({ open, onClose }) => {
  const [visibleFields, setVisibleFields] = useState<number>(0);
  const [action, setAction] = useState<'none' | 'withdraw' | 'refund' | 'done'>('none');

  useEffect(() => {
    if (open) {
      setVisibleFields(0);
      setAction('none');
      const timer = setInterval(() => {
        setVisibleFields((prev) => {
          if (prev < escrowFields.length) return prev + 1;
          clearInterval(timer);
          return prev;
        });
      }, 2000);
      return () => clearInterval(timer);
    }
  }, [open]);

  const handleWithdraw = () => {
    setAction('withdraw');
    setTimeout(() => setAction('done'), 1500);
    setTimeout(onClose, 3000);
  };
  const handleRefund = () => {
    setAction('refund');
    setTimeout(() => setAction('done'), 1500);
    setTimeout(onClose, 3000);
  };

  if (!open) return null;

  return (
    <div className={styles.overlay}>
      <div className={styles.modal}>
        <button className={styles.closeBtn} onClick={onClose}>&times;</button>
        <div className={styles.header}><FaLock className={styles.icon} /> Escrow Actions</div>
        <div className={styles.fieldsGrid}>
          {escrowFields.slice(0, visibleFields).map((field, idx) => (
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
        {visibleFields === escrowFields.length && action === 'none' && (
          <div className={styles.actionBtns}>
            <button className={styles.withdrawBtn} onClick={handleWithdraw}><FaUnlock /> Withdraw</button>
            <button className={styles.refundBtn} onClick={handleRefund}><FaUndo /> Refund</button>
          </div>
        )}
        {action === 'withdraw' && (
          <div className={styles.successMsg}><FaCheckCircle className={styles.successIcon} /> Withdrawal successful!</div>
        )}
        {action === 'refund' && (
          <div className={styles.successMsg}><FaCheckCircle className={styles.successIcon} /> Refund successful!</div>
        )}
      </div>
    </div>
  );
};

export default EscrowActionModal;
