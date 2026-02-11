"use client";

import React from "react";
import { Modal } from "./ui/modal";
import { useConnect } from "@starknet-react/core";
import { Loader2, Shield, Zap } from "lucide-react";

interface ConnectModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function ConnectModal({ isOpen, onClose }: ConnectModalProps) {
  const { connectors, connect, isPending, variables } = useConnect();

  const handleConnect = (connectorId: string) => {
    const connector = connectors.find((c) => c.id === connectorId);
    if (connector) {
      connect({ connector });
      onClose();
    }
  };

  const displayName = (id: string) => {
    const lower = id.toLowerCase();
    if (lower.includes("braavos")) return "Braavos";
    if (lower.includes("argent") || lower.includes("ready")) return "Ready";
    return id;
  };

  const iconFor = (id: string) => {
    const lower = id.toLowerCase();
    if (lower.includes("braavos")) return <Shield className="h-5 w-5 text-blue-500" />;
    if (lower.includes("argent") || lower.includes("ready")) return <Zap className="h-5 w-5 text-yellow-500" />;
    return <Shield className="h-5 w-5 text-muted-foreground" />;
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Connect Wallet">
      <div className="grid gap-4">
        {connectors.map((connector) => {
          const connecting = isPending && variables?.connector?.id === connector.id;
          return (
            <button
              key={connector.id}
              onClick={() => handleConnect(connector.id)}
              disabled={isPending}
              className="flex items-center justify-between p-4 rounded-xl border bg-card hover:bg-accent hover:border-primary/50 transition-all group disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <div className="flex items-center gap-3">
                <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center group-hover:bg-primary/20 transition-colors">
                  {iconFor(connector.id)}
                </div>
                <span className="font-medium">{displayName(connector.id)}</span>
              </div>
              {connecting && <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />}
            </button>
          );
        })}
        {connectors.length === 0 && (
          <p className="text-sm text-muted-foreground text-center py-4">
            No wallet detected. Install Braavos or Ready to continue.
          </p>
        )}
      </div>
    </Modal>
  );
}
