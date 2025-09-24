// import React from 'react';
import { Routes, Route } from 'react-router-dom';
import Header from './components/Layout/Header';
import Footer from './components/Layout/Footer';
import Home from './pages/Home';
import Projects from './pages/Projects';
import Waitlist from './pages/Waitlist';
import Dashboard from './pages/Dashboard';
import PoolDashboard from './pages/PoolDashboard';
import PoolDetail from './pages/PoolDetail';
import PoolCreate from './pages/PoolCreate';
import './App.css';

function App() {
  return (
    <div className="app-container">
      <Header />
      <main className="main-content">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/projects" element={<Projects />} />
          <Route path="/waitlist" element={<Waitlist />} />
          <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/pool-dashboard" element={<PoolDashboard />} />
            <Route path="/pool-detail" element={<PoolDetail />} />
          <Route path="/pool-create" element={<PoolCreate />} />
        </Routes>
      </main>
      <Footer />
    </div>
  );
}

export default App;
