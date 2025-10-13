import { useState } from 'react';
import { openContractCall } from '@stacks/connect';
import { STACKS_TESTNET } from '@stacks/network';
import { stringUtf8CV, uintCV } from '@stacks/transactions';
import { useAuth } from '../auth/StacksAuthContext';

/**
 * General contract call template for Stacks dApps using stack.js
 *
 * Usage: Place <ContractCallExample /> in any component/page.
 * Adapt contractAddress, contractName, functionName, and functionArgs as needed.
 */
export default function ContractCallExample() {
  const { userData } = useAuth();
  const [txId, setTxId] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Example contract call details (replace with your own)
  const contractAddress = 'ST123...'; // TODO: Replace with your contract address
  const contractName = 'your-contract'; // TODO: Replace with your contract name
  const functionName = 'your-function'; // TODO: Replace with your function name
  const functionArgs = [
    stringUtf8CV('example'), // Example string argument
    uintCV(123),            // Example uint argument
  ];

  const handleContractCall = async () => {
    setLoading(true);
    setError(null);
    setTxId(null);
    try {
      await openContractCall({
  network: STACKS_TESTNET, // Use the testnet network constant
        contractAddress,
        contractName,
        functionName,
        functionArgs,
        appDetails: {
          name: 'CineX',
          icon: window.location.origin + '/vite.svg',
        },
        onFinish: (data: { txId: string }) => {
          setTxId(data.txId);
          setLoading(false);
        },
        onCancel: () => {
          setLoading(false);
        },
      });
    } catch (e: any) {
      setError(e.message || 'Contract call failed');
      setLoading(false);
    }
  };

  if (!userData) {
    return <div>Please connect your wallet to interact with contracts.</div>;
  }

  return (
    <div style={{ margin: '2rem 0' }}>
      <button onClick={handleContractCall} disabled={loading}>
        {loading ? 'Sending...' : 'Call Example Contract'}
      </button>
      {txId && (
        <div style={{ marginTop: 8 }}>
          Transaction submitted! TxID: <a href={`https://explorer.stacks.co/txid/${txId}?chain=testnet`} target="_blank" rel="noopener noreferrer">{txId}</a>
        </div>
      )}
      {error && <div style={{ color: 'red', marginTop: 8 }}>{error}</div>}
    </div>
  );
}
