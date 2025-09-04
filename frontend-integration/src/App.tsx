

=======

=======

import React from 'react';
=======



=======


import { Routes, Route } from 'react-router-dom';
import Header from './components/Layout/Header';
import Footer from './components/Layout/Footer';
import Home from './pages/Home';
import './App.css';

function App() {
  return (
    <div className="app-container">
      <Header />
      <main className="main-content">
        <Routes>
          <Route path="/" element={<Home />} />
          {/* Other routes will be added here in the future */}
        </Routes>
      </main>
      <Footer />
    </div>
  );
}

export default App;
