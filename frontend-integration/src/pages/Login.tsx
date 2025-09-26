import React, { useState } from 'react';
import styles from '../styles/pages/Login.module.css';

const Login: React.FC = () => {
  const [form, setForm] = useState({
    email: '',
    password: '',
  });
  const [error, setError] = useState('');

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Login logic here
    if (!form.email || !form.password) {
      setError('Please fill in all fields');
      return;
    }
    setError('');
    alert('Logged in successfully!');
  };

  return (
    <div className={styles.loginPage}>
      <form className={styles.form} onSubmit={handleSubmit}>
        <h2>Login</h2>
        <label htmlFor="email">Email</label>
        <input type="email" id="email" name="email" value={form.email} onChange={handleChange} required />
        <label htmlFor="password">Password</label>
        <input type="password" id="password" name="password" value={form.password} onChange={handleChange} required />
        {error && <div className={styles.error}>{error}</div>}
        <button type="submit" className={styles.submitBtn}>Login</button>
      </form>
    </div>
  );
};

export default Login;
