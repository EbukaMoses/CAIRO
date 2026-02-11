"use client";

import React from "react";
import { Button } from "./ui/button";
import { Plus } from "lucide-react";

interface IncreaseButtonProps {
  onClick: () => void;
}

export function IncreaseButton({ onClick }: IncreaseButtonProps) {
  return (
    <Button
      onClick={onClick}
      variant="outline"
      size="icon"
      className="h-16 w-16 rounded-2xl border-2 hover:border-primary hover:bg-primary/10 transition-all hover:-translate-y-1 active:translate-y-0"
    >
      <Plus className="h-8 w-8" />
    </Button>
  );
}
