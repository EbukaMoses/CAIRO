"use client";

import React from "react";
import { mainnet, sepolia } from "@starknet-react/chains";
import {
  StarknetConfig,
  publicProvider,
  ready,
  braavos,
  useInjectedConnectors,
  voyager,
} from "@starknet-react/core";

/** StarknetConfig with autoConnect enabled (per Starknet React docs) to restore session on revisit. */
function StarknetConnectors({ children }: { children: React.ReactNode }) {
  const { connectors } = useInjectedConnectors({
    recommended: [ready(), braavos()],
    includeRecommended: "onlyIfNoConnectors",
    order: "random",
  });

  return (
    <StarknetConfig
      chains={[mainnet, sepolia]}
      provider={publicProvider()}
      connectors={connectors}
      explorer={voyager}
      autoConnect={true}
    >
      {children}
    </StarknetConfig>
  );
}

export function StarknetProvider({ children }: { children: React.ReactNode }) {
  return <StarknetConnectors>{children}</StarknetConnectors>;
}
