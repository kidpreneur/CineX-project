import React from 'react';

interface TransactionStatusModalProps {
  isOpen: boolean;
  onClose: () => void;
  status: 'pending' | 'success' | 'error' | null;
  txId?: string;
  fee?: string;
  error?: string;
}

const TransactionStatusModal: React.FC<TransactionStatusModalProps> = ({ isOpen, onClose, status, txId, fee, error }) => {
  if (!isOpen) return null;
  return (
    <div style={{ position: 'fixed', top:0, left:0, width:'100vw', height:'100vh', background:'rgba(0,0,0,0.4)', display:'flex', alignItems:'center', justifyContent:'center', zIndex: 2000 }} onClick={onClose}>
      <div style={{ background:'#fff', borderRadius:10, padding:'2rem 1.5rem', minWidth:320, maxWidth:'95vw', boxShadow:'0 4px 24px rgba(0,0,0,0.15)', position:'relative' }} onClick={e => e.stopPropagation()}>
        <button style={{ position:'absolute', top:10, right:20, background:'none', border:'none', fontSize:'2rem', color:'#888', cursor:'pointer' }} onClick={onClose}>&times;</button>
        <h2>Transaction Status</h2>
        {status === 'pending' && <p>Transaction is pending...</p>}
        {status === 'success' && <>
          <p>Transaction successful!</p>
          {txId && <p><strong>Tx ID:</strong> {txId}</p>}
        </>}
        {status === 'error' && <>
          <p style={{color:'red'}}>Transaction failed.</p>
          {error && <p>{error}</p>}
        </>}
        {fee && <p><strong>Fee:</strong> {fee}</p>}
      </div>
    </div>
  );
};

export default TransactionStatusModal;
