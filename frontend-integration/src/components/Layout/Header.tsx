import React, { useState } from 'react';
import Modal from '../Modal';
import WalletStatus from '../WalletStatus';
import TransactionStatusModal from '../TransactionStatusModal';
import { Link, useNavigate } from 'react-router-dom';
import styles from '../../styles/Layout/Header.module.css';

const Header: React.FC = () => {
  const [menuOpen, setMenuOpen] = useState(false);
  const [walletModalOpen, setWalletModalOpen] = useState(false);
  const [adminModalOpen, setAdminModalOpen] = useState(false); // will be removed
  const navigate = useNavigate();
  const [walletConnected, setWalletConnected] = useState(false);
  const [walletAddress, setWalletAddress] = useState<string | undefined>(undefined);
  const [walletStatus, setWalletStatus] = useState<string | undefined>(undefined);
  // Mock connect/disconnect logic for Hiro wallet
  const [txModalOpen, setTxModalOpen] = useState(false);
  const [txStatus, setTxStatus] = useState<'pending' | 'success' | 'error' | null>(null);
  const [txId, setTxId] = useState<string | undefined>(undefined);
  const [txFee, setTxFee] = useState<string | undefined>(undefined);
  const [txError, setTxError] = useState<string | undefined>(undefined);

  const handleConnect = () => {
    setWalletConnected(true);
    setWalletAddress('SP2C2...EXAMPLE');
    setWalletStatus('Connected');
    // Simulate a transaction after connecting
    setTxStatus('pending');
    setTxFee('0.0005 STX');
    setTxModalOpen(true);
    setTimeout(() => {
      setTxStatus('success');
      setTxId('0xABC123...');
    }, 2000);
  };
  const handleDisconnect = () => {
    setWalletConnected(false);
    setWalletAddress(undefined);
    setWalletStatus('Disconnected');
  };
  const closeTxModal = () => {
    setTxModalOpen(false);
    setTxStatus(null);
    setTxId(undefined);
    setTxFee(undefined);
    setTxError(undefined);
  };

  const toggleMenu = () => {
    setMenuOpen(!menuOpen);
  };

  const openWalletModal = () => {
    setWalletModalOpen(true);
    setMenuOpen(false);
  };
  const openAdminDashboard = () => {
    setMenuOpen(false);
    navigate('/admin-dashboard');
  };
  const closeWalletModal = () => setWalletModalOpen(false);
  const closeAdminModal = () => setAdminModalOpen(false);

  return (
    <header className={styles.header}>
      <div className={styles.logo}>
        <Link to="/">CineX</Link>
      </div>
      <button className={styles.hamburger} onClick={toggleMenu}>
        {/* A simple hamburger icon using spans */}
        <span className={styles.bar}></span>
        <span className={styles.bar}></span>
        <span className={styles.bar}></span>
      </button>
      <nav className={styles.nav}>
        <Link to="/">Home</Link>
        <Link to="/projects">Explore Projects</Link>
        <Link to="/waitlist">Waitlist</Link>
        <Link to="/register">Register</Link>
        <Link to="/login">Login</Link>
        <Link to="/pool-create">Create Pool</Link>
      </nav>
      {/* Hamburger menu for laptop/desktop only, shows extra links when open */}
      <div className={styles.hamburgerMenuWrapper}>
        <button className={styles.hamburger} onClick={toggleMenu}>
          <span className={styles.bar}></span>
          <span className={styles.bar}></span>
          <span className={styles.bar}></span>
        </button>
        {menuOpen && (
          <div className={styles.hamburgerMenu}>
            <Link to="/dashboard" onClick={toggleMenu}>User Dashboard</Link>
            <Link to="/pool-dashboard" onClick={toggleMenu}>Pools</Link>
            <Link to="/pool-detail" onClick={toggleMenu}>Pool Details</Link>
            <button className={styles.menuButton} onClick={() => { openWalletModal(); toggleMenu(); }}>Wallet Connection</button>
            <button className={styles.menuButton} onClick={() => { openAdminDashboard(); toggleMenu(); }}>Admin Dashboard</button>
          </div>
        )}
      </div>
      <Modal isOpen={walletModalOpen} onClose={closeWalletModal}>
        <h2>Wallet Connection</h2>
        <WalletStatus
          onConnect={handleConnect}
          onDisconnect={handleDisconnect}
          isConnected={walletConnected}
          address={walletAddress}
          status={walletStatus}
        />
      </Modal>
      {/* Admin dashboard modal removed; now navigates to page */}
      <TransactionStatusModal
        isOpen={txModalOpen}
        onClose={closeTxModal}
        status={txStatus}
        txId={txId}
        fee={txFee}
        error={txError}
      />
    </header>
  );
};

export default Header;
