// Stacks wallet authentication context for React
import { createContext, useContext, useState, useEffect } from 'react';
import { UserSession, AppConfig, showConnect } from '@stacks/connect';

const appConfig = new AppConfig(['store_write', 'publish_data']);
const userSession = new UserSession({ appConfig });

interface AuthContextType {
  userSession: any;
  userData: any;
  signIn: () => void;
  signOut: () => void;
}

const AuthContext = createContext<AuthContextType>({
  userSession,
  userData: null,
  signIn: () => {},
  signOut: () => {},
});

import type { ReactNode } from 'react';

type AuthProviderProps = {
  children: ReactNode;
};

type UserData = any; // You can replace this with a more specific type if desired

export const AuthProvider = ({ children }: AuthProviderProps) => {
  const [userData, setUserData] = useState<UserData | null>(null);

  useEffect(() => {
    if (userSession.isUserSignedIn()) {
      setUserData(userSession.loadUserData());
    } else if (userSession.isSignInPending()) {
      userSession.handlePendingSignIn().then((userData: UserData) => {
        setUserData(userData);
      });
    }
  }, []);

  const signIn = () => {
    showConnect({
      appDetails: {
        name: 'CineX',
        icon: window.location.origin + '/vite.svg',
      },
      userSession,
      onFinish: () => {
        setUserData(userSession.loadUserData());
      },
    });
  };

  const signOut = () => {
    userSession.signUserOut(window.location.origin);
    setUserData(null);
  };

  return (
    <AuthContext.Provider value={{ userSession, userData, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => useContext(AuthContext);
