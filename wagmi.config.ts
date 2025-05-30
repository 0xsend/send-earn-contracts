import { defineConfig } from "@wagmi/cli";
import { foundry } from "@wagmi/cli/plugins";

export default defineConfig({
  out: "generated.ts",
  contracts: [],
  plugins: [
    foundry({
      project: ".",
      include: ["SendEarn**.sol/**", "Platform.sol/**"],
    }),
  ],
});
