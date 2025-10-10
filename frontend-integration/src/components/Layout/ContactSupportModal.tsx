import React, { useState } from 'react';
import styles from '../../styles/Layout/ContactSupportModal.module.css';
import { FaEnvelope, FaCheckCircle } from 'react-icons/fa';

const ContactSupportModal: React.FC<{ open: boolean; onClose: () => void }> = ({ open, onClose }) => {
  const [form, setForm] = useState({ name: '', email: '', message: '' });
  const [submitted, setSubmitted] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitted(true);
    setTimeout(() => {
      setSubmitted(false);
      onClose();
    }, 2000);
  };

  if (!open) return null;

  return (
    <div className={styles.overlay}>
      <div className={styles.modal}>
        <button className={styles.closeBtn} onClick={onClose}>&times;</button>
        <div className={styles.header}>
          <FaEnvelope className={styles.icon} />
          <span>Contact / Support</span>
        </div>
        {submitted ? (
          <div className={styles.successMsg}>
            <FaCheckCircle className={styles.successIcon} />
            Thank you! Your message has been sent.
          </div>
        ) : (
          <form className={styles.form} onSubmit={handleSubmit}>
            <label className={styles.label}>
              Name
              <input
                type="text"
                name="name"
                className={styles.input}
                value={form.name}
                onChange={handleChange}
                required
              />
            </label>
            <label className={styles.label}>
              Email
              <input
                type="email"
                name="email"
                className={styles.input}
                value={form.email}
                onChange={handleChange}
                required
              />
            </label>
            <label className={styles.label}>
              Message
              <textarea
                name="message"
                className={styles.input}
                value={form.message}
                onChange={handleChange}
                required
              />
            </label>
            <button className={styles.submitBtn} type="submit">Send</button>
          </form>
        )}
      </div>
    </div>
  );
};

export default ContactSupportModal;
