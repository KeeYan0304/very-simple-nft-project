import Install from './components/Install'
import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import React, { lazy, Suspense } from 'react';
import ErrorBoundary from "./components/ErrorBoundary";

const Home = lazy(() => import('./components/Home'));
function loadComponent(name) {
  const Component = React.lazy(() =>
    import(`./components/Home.jsx`)
  );
  return Component;
}

function App() {
  const [errorMessage, setErrorMessage] = useState(null);
  const [account, setAccount] = useState(null);

  const componentNumber = 2;
  const Component = loadComponent(componentNumber);

  useEffect(() => {
    if (window.ethereum) {
      window.ethereum.on("accountsChanged", accountsChanged);
      window.ethereum.on("chainChanged", chainChanged);
    }
  }, []);

  const chainChanged = () => {
    setErrorMessage(null);
    setAccount(null);
    setBalance(null);
  };

  const accountsChanged = async (newAccount) => {
    setAccount(newAccount);
    try {
      <Home />
    } catch (err) {
      console.error(err);
      setErrorMessage("There was a problem connecting to MetaMask");
    }
  };

  const connectHandler = async () => {
    if (window.ethereum) {
      try {
        const res = await window.ethereum.request({
          method: "eth_requestAccounts",
        });
        await accountsChanged(res[0]);
      } catch (err) {
        console.error(err);
        setErrorMessage("There was a problem connecting to MetaMask");
      }
    } else {
      setErrorMessage("Install MetaMask");
    }
  };

  return (
    <div>
      <section>
      <button onClick={connectHandler}>Connect Account</button>
      {account != null &&
        <Suspense fallback={<div>Loading...</div>}>
        <ErrorBoundary>
          <Component />
        </ErrorBoundary>
      </Suspense>
      }
      </section>
    </div>
  )
}

export default App;