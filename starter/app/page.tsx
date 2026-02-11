"use client";

import React, { useState } from "react";
import Image from "next/image";
import { Navbar } from "@/components/Navbar";
import { TokenBalance } from "@/components/TokenBalance";
import { Button } from "@/components/ui/button";
import { Plus, Minus, Loader2 } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { useAccount, useContract, useReadContract, useSendTransaction } from "@starknet-react/core";
import { COUNTER_ABI } from "@/abi/counter_abi";
import { COUNTER_CONTRACT_ADDRESS } from "@/lib/utils";

export default function Home() {
  const [inputValue, setInputValue] = useState("1");
  const numericValue = Math.max(0, Math.floor(Number(inputValue) || 0));

  const { address, isConnected } = useAccount();
  const { contract } = useContract({
    abi: COUNTER_ABI,
    address: COUNTER_CONTRACT_ADDRESS as `0x${string}`,
  });

  const { data: count, isPending: countLoading, isFetching: countFetching } = useReadContract({
    abi: COUNTER_ABI,
    address: COUNTER_CONTRACT_ADDRESS as `0x${string}`,
    functionName: "get_count",
    args: [],
    watch: true,
    enabled: true,
  });

  const { send: sendTx, isPending: txPending } = useSendTransaction({});

  const handleIncreaseBy = () => {
    if (!contract || !address || numericValue <= 0) return;
    const call = contract.populate("increase_count_by", [BigInt(numericValue)]);
    sendTx([call]);
  };

  const handleDecreaseBy = () => {
    if (!contract || !address || numericValue <= 0) return;
    const call = contract.populate("decrease_count_by", [BigInt(numericValue)]);
    sendTx([call]);
  };

  const displayCount = count !== undefined && count !== null ? Number(count) : 0;
  const countLoadingState = countLoading || countFetching;
  const canTransact = isConnected && !!address && !txPending && numericValue > 0;

  return (
    <main className="min-h-screen flex flex-col bg-background selection:bg-primary/20">
      <Navbar />

      <div className="flex-1 relative overflow-hidden">
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-primary/10 rounded-full blur-[140px] pointer-events-none" aria-hidden />
        <div className="relative z-10 container mx-auto max-w-5xl px-4 pt-24 pb-16">
          {/* Hero image */}
          <header className="rounded-2xl overflow-hidden border border-border/60 shadow-xl mb-10 sm:mb-14 bg-primary/5">
            <div className="relative aspect-[21/9] sm:aspect-[3/1] min-h-[180px] w-full">
              <Image
                src="https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=1200&q=80"
                alt="Starknet Africa — build on Starknet"
                fill
                className="object-cover"
                sizes="(max-width: 768px) 100vw, 1024px"
                priority
              />
              <div className="absolute inset-0 bg-gradient-to-t from-primary/80 via-primary/20 to-transparent" />
              <div className="absolute inset-0 flex flex-col items-center justify-center text-center px-4">
                <h1 className="text-3xl sm:text-4xl md:text-5xl font-extrabold tracking-tight text-white drop-shadow-lg">
                  Counter
                </h1>
                <p className="mt-2 text-white/90 text-sm sm:text-base max-w-md drop-shadow">
                  Manage your count on Starknet.
                </p>
              </div>
            </div>
          </header>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 lg:gap-8 items-start">
            {/* Counter section */}
            <section className="lg:col-span-2 space-y-6">
              <div className="rounded-2xl border border-border/60 bg-card/80 backdrop-blur-xl shadow-xl overflow-hidden">
                <div className="p-6 sm:p-8 border-b border-border/50">
                  <div className="flex items-center justify-between gap-4 mb-2">
                    <span className="text-sm font-medium text-muted-foreground uppercase tracking-wider">
                      Current count
                    </span>
                    {countFetching && (
                      <Loader2 className="h-4 w-4 animate-spin text-muted-foreground shrink-0" aria-hidden />
                    )}
                  </div>
                  <div className="min-h-[120px] flex items-center justify-center">
                    {countLoadingState && displayCount === 0 ? (
                      <Loader2 className="h-14 w-14 animate-spin text-muted-foreground" aria-label="Loading count" />
                    ) : (
                      <AnimatePresence mode="popLayout">
                        <motion.span
                          key={displayCount}
                          initial={{ opacity: 0, y: 12, scale: 0.96 }}
                          animate={{ opacity: 1, y: 0, scale: 1 }}
                          exit={{ opacity: 0, y: -12, scale: 0.96 }}
                          transition={{ type: "spring", stiffness: 300, damping: 24 }}
                          className="text-6xl sm:text-7xl font-bold tabular-nums text-foreground"
                        >
                          {displayCount}
                        </motion.span>
                      </AnimatePresence>
                    )}
                  </div>
                </div>
                <div className="p-6 sm:p-8 bg-muted/30 space-y-4">
                  <label htmlFor="count-value" className="block text-sm font-medium text-foreground">
                    Change by
                  </label>
                  <div className="flex flex-col sm:flex-row gap-3">
                    <input
                      id="count-value"
                      type="number"
                      min={0}
                      value={inputValue}
                      onChange={(e) => setInputValue(e.target.value)}
                      className="flex h-11 w-full sm:w-24 px-4 rounded-lg border border-input bg-background text-foreground font-mono text-center text-lg focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
                    />
                    <div className="flex flex-wrap gap-3">
                      <Button
                        onClick={handleDecreaseBy}
                        disabled={!canTransact}
                        variant="outline"
                        size="lg"
                        className="flex-1 sm:flex-initial gap-2 min-w-0"
                      >
                        {txPending ? <Loader2 className="h-4 w-4 animate-spin shrink-0" /> : <Minus className="h-4 w-4 shrink-0" />}
                        <span className="truncate">Decrease by {numericValue}</span>
                      </Button>
                      <Button
                        onClick={handleIncreaseBy}
                        disabled={!canTransact}
                        variant="default"
                        size="lg"
                        className="flex-1 sm:flex-initial gap-2 min-w-0"
                      >
                        {txPending ? <Loader2 className="h-4 w-4 animate-spin shrink-0" /> : <Plus className="h-4 w-4 shrink-0" />}
                        <span className="truncate">Increase by {numericValue}</span>
                      </Button>
                    </div>
                  </div>
                  {!isConnected && (
                    <p className="text-sm text-muted-foreground">
                      Connect your wallet to change the counter.
                    </p>
                  )}
                </div>
              </div>
            </section>

            {/* Balances sidebar (when connected) */}
            {isConnected && (
              <aside className="lg:col-span-1">
                <div className="rounded-2xl border border-border/60 bg-card/80 backdrop-blur-xl shadow-xl p-6 sticky top-24">
                  <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-4">
                    Your balances
                  </h2>
                  <div className="flex flex-col gap-3">
                    <TokenBalance variant="stack" />
                  </div>
                </div>
              </aside>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}
