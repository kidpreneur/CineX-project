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
              <Link to="/dashboard" onClick={toggleMenu} className={styles.menuLink}>
                User Dashboard
                <span className={styles.closeLink} onClick={toggleMenu}>&times;</span>
              </Link>
              <Link to="/pool-dashboard" onClick={toggleMenu} className={styles.menuLink}>
                Pools
                <span className={styles.closeLink} onClick={toggleMenu}>&times;</span>
              </Link>
              <Link to="/pool-detail" onClick={toggleMenu} className={styles.menuLink}>
                Pool Details
                <span className={styles.closeLink} onClick={toggleMenu}>&times;</span>
              </Link>
              <button className={styles.menuButton} onClick={() => { openWalletModal(); toggleMenu(); }}>
                Wallet Connection <span className={styles.closeLink}>&times;</span>
              </button>
              <button className={styles.menuButton} onClick={() => { openAdminDashboard(); toggleMenu(); }}>
                Admin Dashboard <span className={styles.closeLink}>&times;</span>
              </button>
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
