"use client";

import React from "react";
import { Button } from "./ui/button";
import { Minus } from "lucide-react";

interface DecreaseButtonProps {
  onClick: () => void;
}

export function DecreaseButton({ onClick }: DecreaseButtonProps) {
  return (
    <Button
      onClick={onClick}
      variant="outline"
      size="icon"
      className="h-16 w-16 rounded-2xl border-2 hover:border-primary hover:bg-primary/10 transition-all hover:-translate-y-1 active:translate-y-0"
    >
      <Minus className="h-8 w-8" />
    </Button>
  );
}
