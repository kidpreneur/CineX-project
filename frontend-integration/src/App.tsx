import React from 'react';
import Header from './components/Layout/Header';
import Footer from './components/Layout/Footer';
import './App.css';

function App() {
  return (
    <div className="app-container">
      <Header />
      <main className="main-content">
        {/* The router outlet will go here in the future */}
        <h1>Welcome to CineX</h1>
        <p>This is the main content area.</p>
      </main>
      <Footer />
    </div>
  );
}

export default App;
