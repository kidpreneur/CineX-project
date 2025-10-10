import CoEPPools from './pages/CoEPPools';
import AdminControls from './pages/AdminControls';
import ContributorRewards from './pages/ContributorRewards';
import EscrowManagement from './pages/EscrowManagement';
// import React from 'react';
import { Routes, Route } from 'react-router-dom';
import Header from './components/Layout/Header';
import Footer from './components/Layout/Footer';
import Home from './pages/Home';
import Campaigns from './pages/Projects';
import CampaignDetail from './pages/CampaignDetail';
import Waitlist from './pages/Waitlist';
import Dashboard from './pages/Dashboard';
import PoolDashboard from './pages/PoolDashboard';
import PoolDetail from './pages/PoolDetail';
import PoolCreate from './pages/PoolCreate';
import AdminDashboard from './pages/AdminDashboard';
import Register from './pages/Register';
import Login from './pages/Login';
import './App.css';

function App() {
  return (
    <div className="app-container">
      <Header />
      <main className="main-content">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/projects" element={<Campaigns />} />
          <Route path="/campaigns" element={<Campaigns />} />
          <Route path="/waitlist" element={<Waitlist />} />
          <Route path="/campaigns/:id" element={<CampaignDetail />} />
          <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/pool-dashboard" element={<PoolDashboard />} />
            <Route path="/pool-detail" element={<PoolDetail />} />
          <Route path="/pool-create" element={<PoolCreate />} />
          <Route path="/admin-dashboard" element={<AdminDashboard />} />
          <Route path="/admin-controls" element={<AdminControls />} />
          <Route path="/rewards" element={<ContributorRewards />} />
          <Route path="/coep-pools" element={<CoEPPools />} />
          <Route path="/escrow-management" element={<EscrowManagement />} />
          <Route path="/register" element={<Register />} />
          <Route path="/login" element={<Login />} />
        </Routes>
      </main>
      <Footer />
    </div>
  );
}

export default App;
