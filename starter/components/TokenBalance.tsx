"use client";

import React, { useEffect, useState } from "react";
import { Loader2 } from "lucide-react";
import { useAccount, useBalance, useProvider } from "@starknet-react/core";
import { Contract } from "starknet";
import { STRK_SEPOLIA, USDC_SEPOLIA } from "@/lib/coins";

const ERC20_ABI = [
  {
    type: "function",
    name: "balanceOf",
    state_mutability: "view",
    inputs: [{ name: "account", type: "core::starknet::contract_address::ContractAddress" }],
    outputs: [{ type: "core::integer::u256" }],
  },
  {
    type: "function",
    name: "decimals",
    state_mutability: "view",
    inputs: [],
    outputs: [{ type: "core::integer::u8" }],
  },
] as const;

interface TokenBalanceProps {
  /** "inline" for navbar (row), "stack" for sidebar (column) */
  variant?: "inline" | "stack";
}

export function TokenBalance({ variant = "inline" }: TokenBalanceProps) {
  const { address, isConnected } = useAccount();
  const { provider } = useProvider();

  const {
    data: strkBalance,
    isPending: strkLoading,
    isFetching: strkFetching,
  } = useBalance({
    address: address ?? undefined,
    token: STRK_SEPOLIA as `0x${string}`,
    enabled: !!address,
  });

  const [usdcBalance, setUsdcBalance] = useState<string | null>(null);
  const [usdcLoading, setUsdcLoading] = useState(false);

  useEffect(() => {
    if (!address || !provider) {
      setUsdcBalance(null);
      return;
    }
    let cancelled = false;
    setUsdcLoading(true);
    const contract = new Contract({
      abi: ERC20_ABI,
      address: USDC_SEPOLIA as `0x${string}`,
      providerOrAccount: provider,
    });
    contract
      .call("balanceOf", [address])
      .then((res) => {
        if (cancelled) return;
        const result = res as unknown as { balance?: { low: bigint; high: bigint } };
        let balance = BigInt(0);
        if (result && typeof result === "object") {
          const b = (result as { balance?: bigint }).balance ?? (result as { 0?: bigint })[0];
          if (typeof b === "bigint") balance = b;
          else if (b && typeof b === "object" && "low" in b) {
            const u = b as { low: bigint; high: bigint };
            balance = u.low + (u.high << BigInt(128));
          }
        }
        const formatted = (Number(balance) / 1e6).toLocaleString(undefined, { maximumFractionDigits: 2 });
        setUsdcBalance(formatted);
      })
      .catch(() => {
        if (!cancelled) setUsdcBalance("—");
      })
      .finally(() => {
        if (!cancelled) setUsdcLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [address, provider]);

  if (!isConnected || !address) return null;

  const loading = strkLoading || strkFetching || usdcLoading;

  if (loading && !strkBalance && usdcBalance === null) {
    return (
      <div className="flex items-center gap-2 px-3 py-2 bg-muted/50 rounded-lg border border-border/50">
        <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
        <span className="text-sm font-medium text-muted-foreground">Loading balances…</span>
      </div>
    );
  }

  const pillClass = "flex items-center gap-2 px-3 py-2 rounded-lg border border-border/50 bg-secondary/50 min-w-0";
  const wrapperClass = variant === "stack" ? "flex flex-col gap-3" : "flex flex-wrap items-center gap-3";

  return (
    <div className={wrapperClass}>
      <div className={pillClass}>
        {strkLoading || strkFetching ? (
          <Loader2 className="h-3 w-3 animate-spin text-muted-foreground" />
        ) : (
          <div className="w-4 h-4 rounded-full bg-blue-500/20 flex items-center justify-center">
            <img src="/starknetlogo.svg" alt="Starknet" width={20} height={20} />
          </div>
        )}
        <span className="text-sm font-medium font-mono truncate">
          {strkBalance?.formatted ?? "—"} STRK
        </span>
      </div>
      <div className={pillClass}>
        {usdcLoading ? (
          <Loader2 className="h-4 w-4 animate-spin text-muted-foreground shrink-0" />
        ) : (
          <span className="text-sm font-medium font-mono truncate">{usdcBalance ?? "—"} USDC</span>
        )}
      </div>
    </div>
  );
}
