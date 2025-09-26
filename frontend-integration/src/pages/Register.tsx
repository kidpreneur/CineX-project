import React, { useState } from 'react';
import styles from '../styles/pages/Register.module.css';

const Register: React.FC = () => {
  const [role, setRole] = useState('investor');
  const [form, setForm] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
  });
  const [error, setError] = useState('');

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleRoleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setRole(e.target.value);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (form.password !== form.confirmPassword) {
      setError('Passwords do not match');
      return;
    }
    setError('');
    // Registration logic here
    alert('Registered successfully!');
  };

  return (
    <div className={styles.registerPage}>
      <form className={styles.form} onSubmit={handleSubmit}>
        <h2>Register</h2>
        <label htmlFor="name">Name</label>
        <input type="text" id="name" name="name" value={form.name} onChange={handleChange} required />
        <label htmlFor="email">Email</label>
        <input type="email" id="email" name="email" value={form.email} onChange={handleChange} required />
        <label htmlFor="password">Password</label>
        <input type="password" id="password" name="password" value={form.password} onChange={handleChange} required />
        <label htmlFor="confirmPassword">Confirm Password</label>
        <input type="password" id="confirmPassword" name="confirmPassword" value={form.confirmPassword} onChange={handleChange} required />
        <div className={styles.roleSection}>
          <span>Registering as:</span>
          <label>
            <input type="radio" name="role" value="investor" checked={role === 'investor'} onChange={handleRoleChange} /> Investor
          </label>
          <label>
            <input type="radio" name="role" value="co-partner" checked={role === 'co-partner'} onChange={handleRoleChange} /> Co-partner
          </label>
        </div>
        {error && <div className={styles.error}>{error}</div>}
        <button type="submit" className={styles.submitBtn}>Register</button>
      </form>
    </div>
  );
};

export default Register;
