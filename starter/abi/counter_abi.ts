import type { Abi } from "starknet";

export const COUNTER_ABI = [
  {
    type: "function",
    name: "get_count",
    state_mutability: "view",
    inputs: [],
    outputs: [{ type: "core::integer::u64" }],
  },
  {
    type: "function",
    name: "increase_count_by",
    state_mutability: "external",
    inputs: [{ name: "value", type: "core::integer::u64" }],
    outputs: [],
  },
  {
    type: "function",
    name: "decrease_count_by",
    state_mutability: "external",
    inputs: [{ name: "value", type: "core::integer::u64" }],
    outputs: [],
  },
] as const satisfies Abi;
