"use client";

import React, { useState } from "react";
import { Modal } from "./ui/modal";
import { useAccount, useDisconnect } from "@starknet-react/core";
import { Copy, Check, LogOut, Wallet } from "lucide-react";
import { Button } from "./ui/button";

interface DisconnectModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function DisconnectModal({ isOpen, onClose }: DisconnectModalProps) {
  const { address, connector } = useAccount();
  const { disconnect } = useDisconnect();
  const [copied, setCopied] = useState(false);

  const walletName = connector?.id ? (connector.id.toLowerCase().includes("braavos") ? "Braavos" : connector.id.toLowerCase().includes("argent") || connector.id.toLowerCase().includes("ready") ? "Ready" : connector.id) : "Wallet";

  const handleCopy = () => {
    if (address) {
      navigator.clipboard.writeText(address);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const handleDisconnect = () => {
    disconnect();
    onClose();
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Account Details">
      <div className="space-y-6">
        <div className="flex flex-col items-center justify-center p-6 bg-accent/30 rounded-xl border border-dashed">
          <div className="h-16 w-16 rounded-full bg-primary/10 flex items-center justify-center mb-4">
            <Wallet className="h-8 w-8 text-primary" />
          </div>
          <p className="text-sm text-muted-foreground mb-1">Connected with {walletName}</p>
          <div className="flex items-center gap-2 bg-background px-3 py-1.5 rounded-full border">
            <span className="font-mono text-sm">
              {address ? `${address.slice(0, 6)}...${address.slice(-4)}` : ""}
            </span>
            <button
              onClick={handleCopy}
              className="ml-1 p-1 hover:bg-muted rounded-full transition-colors"
            >
              {copied ? <Check className="h-3.5 w-3.5 text-green-500" /> : <Copy className="h-3.5 w-3.5 text-muted-foreground" />}
            </button>
          </div>
        </div>

        <Button
          onClick={handleDisconnect}
          variant="destructive"
          className="w-full gap-2"
        >
          <LogOut className="h-4 w-4" />
          Disconnect Wallet
        </Button>
      </div>
    </Modal>
  );
}
