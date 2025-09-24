import React, { useState } from 'react';
import styles from '../styles/pages/PoolCreate.module.css';

interface Member {
  id: number;
  name: string;
}

const steps = [
  'Pool Details',
  'Legal Agreement',
  'Invite Members',
  'Review & Create',
];

const PoolCreate: React.FC = () => {
  const [step, setStep] = useState(0);
  const [form, setForm] = useState({
    name: '',
    contribution: '',
    maxMembers: '',
    cycleDuration: '',
    legalAgreement: null as File | null,
    agreementText: '',
    invited: '',
    members: [] as Member[],
  });
  const [errors, setErrors] = useState<string[]>([]);
  const [showToast, setShowToast] = useState(false);

  // Simulated user list for member invite autocomplete
  const userList = [
    { id: 1, name: 'Jane Doe' },
    { id: 2, name: 'John Smith' },
    { id: 3, name: 'Alex Lee' },
    { id: 4, name: 'Sam Green' },
  ];

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm({ ...form, legalAgreement: e.target.files ? e.target.files[0] : null });
  };

  const handleInvite = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm({ ...form, invited: e.target.value });
  };

  const addMember = (name: string) => {
    if (!form.members.some(m => m.name === name)) {
      setForm({ ...form, members: [...form.members, { id: Date.now(), name }] });
    }
    setForm({ ...form, invited: '' });
  };

  const removeMember = (id: number) => {
    setForm({ ...form, members: form.members.filter(m => m.id !== id) });
  };

  // Validation for each step
  const validateStep = () => {
    const errs: string[] = [];
    if (step === 0) {
      if (!form.name.trim()) errs.push('Pool name is required.');
      if (!form.contribution.trim()) errs.push('Contribution per member is required.');
      if (!form.maxMembers.trim() || isNaN(Number(form.maxMembers))) errs.push('Max members must be a number.');
      if (!form.cycleDuration.trim()) errs.push('Cycle duration is required.');
    }
    if (step === 1) {
      if (!form.legalAgreement && !form.agreementText.trim()) errs.push('Legal agreement (file or text) is required.');
    }
    if (step === 2) {
      if (form.members.length === 0) errs.push('Invite at least one member.');
    }
    setErrors(errs);
    return errs.length === 0;
  };

  const nextStep = () => {
    if (validateStep()) setStep(s => Math.min(s + 1, steps.length - 1));
  };
  const prevStep = () => setStep(s => Math.max(s - 1, 0));

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setShowToast(true);
    setTimeout(() => setShowToast(false), 3000);
    // Here you would send the form data to backend/blockchain
  };

  return (
    <div className={styles.poolCreate}>
      <header className={styles.header}>
        <h1>Create a Funding Pool</h1>
        <div className={styles.progressBar}>
          <div className={styles.progress} style={{ width: `${((step + 1) / steps.length) * 100}%` }} />
        </div>
        <div className={styles.steps}>
          {steps.map((label, idx) => (
            <span key={label} className={step === idx ? styles.active : ''}>{label}</span>
          ))}
        </div>
      </header>
      <form className={styles.form} onSubmit={handleSubmit}>
        {errors.length > 0 && (
          <div className={styles.errorBox}>
            {errors.map((err, i) => <div key={i}>{err}</div>)}
          </div>
        )}
        {step === 0 && (
          <section className={styles.section}>
            <label>Pool Name
              <input name="name" value={form.name} onChange={handleChange} placeholder="e.g. Indie Filmmakers Pool" />
            </label>
            <label>Contribution per Member
              <input name="contribution" value={form.contribution} onChange={handleChange} placeholder="e.g. 10,000 STX" />
            </label>
            <label>Max Members
              <input name="maxMembers" value={form.maxMembers} onChange={handleChange} placeholder="e.g. 10" type="number" min="2" />
            </label>
            <label>Cycle Duration
              <input name="cycleDuration" value={form.cycleDuration} onChange={handleChange} placeholder="e.g. 30 days" />
            </label>
          </section>
        )}
        {step === 1 && (
          <section className={styles.section}>
            <label>Legal Agreement (PDF)
              <input type="file" accept=".pdf" onChange={handleFile} />
              {form.legalAgreement && (
                <div className={styles.filePreview}>
                  <span>{form.legalAgreement.name}</span>
                </div>
              )}
            </label>
            <textarea name="agreementText" value={form.agreementText} onChange={handleChange} placeholder="Or paste agreement text here" rows={5} />
            {form.agreementText && (
              <div className={styles.agreementPreview}>
                <strong>Preview:</strong>
                <div>{form.agreementText.slice(0, 120)}{form.agreementText.length > 120 ? '...' : ''}</div>
              </div>
            )}
          </section>
        )}
        {step === 2 && (
          <section className={styles.section}>
            <label>Invite Members</label>
            <input
              name="invited"
              value={form.invited}
              onChange={handleInvite}
              placeholder="Type name and press Enter"
              list="user-list"
              autoComplete="off"
              onKeyDown={e => {
                if (e.key === 'Enter' && form.invited.trim()) {
                  addMember(form.invited.trim());
                  e.preventDefault();
                }
              }}
            />
            <datalist id="user-list">
              {userList.map(u => <option key={u.id} value={u.name} />)}
            </datalist>
            <div className={styles.memberChips}>
              {form.members.map(m => (
                <span key={m.id} className={styles.chip}>
                  {m.name}
                  <button type="button" className={styles.chipRemove} onClick={() => removeMember(m.id)}>&times;</button>
                </span>
              ))}
            </div>
          </section>
        )}
        {step === 3 && (
          <section className={styles.section}>
            <h2>Review Details</h2>
            <ul className={styles.reviewList}>
              <li><strong>Pool Name:</strong> {form.name}</li>
              <li><strong>Contribution per Member:</strong> {form.contribution}</li>
              <li><strong>Max Members:</strong> {form.maxMembers}</li>
              <li><strong>Cycle Duration:</strong> {form.cycleDuration}</li>
              <li><strong>Legal Agreement:</strong> {form.legalAgreement ? form.legalAgreement.name : (form.agreementText ? 'Text provided' : 'None uploaded')}</li>
              <li><strong>Invited Members:</strong> {form.members.map(m => m.name).join(', ')}</li>
            </ul>
            <button type="submit" className={styles.createBtn}>Create Pool</button>
          </section>
        )}
        <div className={styles.navBtns}>
          {step > 0 && <button type="button" onClick={prevStep} className={styles.navBtn}>Back</button>}
          {step < steps.length - 1 && <button type="button" onClick={nextStep} className={styles.navBtn}>Next</button>}
        </div>
      </form>
      {showToast && (
        <div className={styles.toast}>
          Pool created successfully!
        </div>
      )}
    </div>
  );
};

export default PoolCreate;
