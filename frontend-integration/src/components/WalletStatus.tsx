import React, { useState } from 'react';

interface WalletStatusProps {
  onConnect: () => void;
  onDisconnect: () => void;
  isConnected: boolean;
  address?: string;
  status?: string;
}

const WalletStatus: React.FC<WalletStatusProps> = ({ onConnect, onDisconnect, isConnected, address, status }) => {
  return (
    <div>
      {isConnected ? (
        <>
          <p><strong>Connected:</strong> {address}</p>
          <button onClick={onDisconnect}>Disconnect</button>
          {status && <p>Status: {status}</p>}
        </>
      ) : (
        <button onClick={onConnect}>Connect Hiro Wallet</button>
      )}
    </div>
  );
};

export default WalletStatus;
