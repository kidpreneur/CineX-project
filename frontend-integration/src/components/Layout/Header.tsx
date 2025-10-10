import React, { useState } from 'react';
import Modal from '../Modal';
import WalletStatus from '../WalletStatus';
import TransactionStatusModal from '../TransactionStatusModal';
import { Link, useNavigate } from 'react-router-dom';
import styles from '../../styles/Layout/Header.module.css';
import handsLogo from '../../assets/hands-together-logo.svg';

const Header: React.FC = () => {
  const [menuOpen, setMenuOpen] = useState(false);
  const [walletModalOpen, setWalletModalOpen] = useState(false);
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

  return (
    <header className={styles.header}>
      <div className={styles.logo}>
        <img src={handsLogo} alt="Hands together logo" className={styles.logoIcon} />
        <Link to="/" className={styles.logoTitle}>CineX</Link>
        <span className={styles.tagline}>Crowdfunding for Creatives</span>
      </div>
      <nav className={styles.nav}>
        <Link to="/" className={styles.navLink}>Home</Link>
  <Link to="/campaigns" className={styles.navLink}>Campaigns</Link>
        <Link to="/waitlist" className={styles.navLink}>Waitlist</Link>
        <Link to="/register" className={styles.navLink}>Register</Link>
        <Link to="/login" className={styles.navLink}>Login</Link>
      </nav>
      <div className={styles.hamburgerMenuWrapper}>
        <button className={styles.hamburger} onClick={toggleMenu} aria-label="Open menu">
          <span className={styles.bar}></span>
          <span className={styles.bar}></span>
          <span className={styles.bar}></span>
        </button>
        {menuOpen && (
          <div className={styles.hamburgerMenu}>
            <button className={styles.closeMenu} onClick={toggleMenu} aria-label="Close menu">&times;</button>
            <nav className={styles.menuLinks}>
              <div className={styles.menuPanel}>
                <button className={styles.closeLink} onClick={toggleMenu} aria-label="Close">&times;</button>
                <Link to="/dashboard" onClick={toggleMenu} className={styles.menuLink}>User Dashboard</Link>
              </div>
              <div className={styles.menuPanel}>
                <button className={styles.closeLink} onClick={toggleMenu} aria-label="Close">&times;</button>
                <Link to="/pool-dashboard" onClick={toggleMenu} className={styles.menuLink}>Pools</Link>
              </div>
              <div className={styles.menuPanel}>
                <button className={styles.closeLink} onClick={toggleMenu} aria-label="Close">&times;</button>
                <Link to="/pool-detail" onClick={toggleMenu} className={styles.menuLink}>Pool Details</Link>
              </div>
              <div className={styles.menuPanel}>
                <button className={styles.closeLink} onClick={toggleMenu} aria-label="Close">&times;</button>
                <button className={styles.menuButton} onClick={() => { openWalletModal(); toggleMenu(); }}>Wallet Connection</button>
              </div>
              <div className={styles.menuPanel}>
                <button className={styles.closeLink} onClick={toggleMenu} aria-label="Close">&times;</button>
                <button className={styles.menuButton} onClick={() => { openAdminDashboard(); toggleMenu(); }}>Admin Dashboard</button>
              </div>
            </nav>
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
