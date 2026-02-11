"use client";

import React, { createContext, useContext, useState, ReactNode } from "react";

interface WalletContextType {
  isConnected: boolean;
  address: string | null;
  walletName: "Braavos" | "Ready" | null;
  connect: (wallet: "Braavos" | "Ready") => Promise<void>;
  disconnect: () => void;
}

const WalletContext = createContext<WalletContextType | undefined>(undefined);

export function WalletProvider({ children }: { children: ReactNode }) {
  const [isConnected, setIsConnected] = useState(false);
  const [address, setAddress] = useState<string | null>(null);
  const [walletName, setWalletName] = useState<"Braavos" | "Ready" | null>(null);

  const connect = async (wallet: "Braavos" | "Ready") => {
    // Simulate connection delay
    await new Promise((resolve) => setTimeout(resolve, 1000));
    
    // Mock address
    const mockAddress = "0x0123...abc" + Math.floor(Math.random() * 1000).toString();
    
    setIsConnected(true);
    setAddress(mockAddress);
    setWalletName(wallet);
  };

  const disconnect = () => {
    setIsConnected(false);
    setAddress(null);
    setWalletName(null);
  };

  return (
    <WalletContext.Provider value={{ isConnected, address, walletName, connect, disconnect }}>
      {children}
    </WalletContext.Provider>
  );
}

export function useWallet() {
  const context = useContext(WalletContext);
  if (context === undefined) {
    throw new Error("useWallet must be used within a WalletProvider");
  }
  return context;
}
