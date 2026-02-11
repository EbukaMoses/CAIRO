"use client";

import React, { useState } from "react";
import { Button } from "./ui/button";
import { useAccount } from "@starknet-react/core";
import { ConnectModal } from "./ConnectModal";
import { DisconnectModal } from "./DisconnectModal";
import { Wallet } from "lucide-react";

export function Navbar() {
  const { address, isConnected } = useAccount();
  const [isConnectOpen, setIsConnectOpen] = useState(false);
  const [isDisconnectOpen, setIsDisconnectOpen] = useState(false);

  const handleWalletClick = () => {
    if (isConnected) {
      setIsDisconnectOpen(true);
    } else {
      setIsConnectOpen(true);
    }
  };

  return (
    <>
      <nav className="fixed top-0 left-0 right-0 z-40 border-b border-border/50 bg-background/90 backdrop-blur-md">
        <div className="container mx-auto flex h-14 sm:h-16 items-center justify-between gap-4 px-4 sm:px-6 max-w-5xl">
          <a href="/" className="flex items-center gap-2 min-w-0">
            <div className="h-8 w-8 shrink-0 rounded-lg bg-primary flex items-center justify-center">
              <span className="font-bold text-primary-foreground text-sm">S</span>
            </div>
            <span className="text-base sm:text-lg font-bold tracking-tight truncate hidden sm:block">
              Starknet Africa
            </span>
          </a>

          <Button
            onClick={handleWalletClick}
            variant={isConnected ? "outline" : "default"}
            size="default"
            className="rounded-full font-medium gap-2 transition-all duration-200 shrink-0"
          >
            <Wallet className="h-4 w-4 shrink-0" />
            {isConnected && address ? (
              <span className="font-mono text-xs truncate max-w-[140px] sm:max-w-[180px]">
                {address.slice(0, 6)}…{address.slice(-4)}
              </span>
            ) : (
              "Connect Wallet"
            )}
          </Button>
        </div>
      </nav>

      <ConnectModal
        isOpen={isConnectOpen}
        onClose={() => setIsConnectOpen(false)}
      />
      <DisconnectModal
        isOpen={isDisconnectOpen}
        onClose={() => setIsDisconnectOpen(false)}
      />
    </>
  );
}
