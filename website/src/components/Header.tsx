import { WalletSelector } from "./WalletSelector";

export function Header() {
  return (
    <div className="flex items-center justify-between px-6 py-4 max-w-screen-xl mx-auto w-full flex-wrap bg-black/20 backdrop-blur-sm border-b border-black/30">
      <h1 className="matrix-title text-2xl md:text-3xl">APTOS ARENA - PIG</h1>

      <div className="flex gap-4 items-center flex-wrap">
        <WalletSelector />
      </div>
    </div>
  );
}
