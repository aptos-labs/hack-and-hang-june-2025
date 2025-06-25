"use client";

import { Header } from "@/components/Header";
import { PigGame } from "@/components/PigGame";
import { MatrixRain } from "@/components/MatrixRain";
// Internal Components
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { WalletSelector } from "@/components/WalletSelector.tsx";

function App() {
  const { connected } = useWallet();

  return (
    <>
      <MatrixRain />
      <div className="matrix-rain"></div>
      <Header />
      <div className="flex items-center justify-center flex-col min-h-screen p-4">
        {connected ? (
          <Card className="matrix-card w-full max-w-2xl">
            <CardContent className="flex flex-col gap-8 pt-8">
              <div className="text-center mb-4">
                <h2 className="matrix-title text-3xl mb-2">APTOS ARENA - PIG</h2>
              </div>
              <PigGame />
            </CardContent>
          </Card>
        ) : (
          <Card className="matrix-card w-full max-w-md">
            <CardHeader className="text-center">
              <CardTitle className="matrix-title text-2xl mb-4">APTOS ARENA - PIG</CardTitle>
              <WalletSelector />
            </CardHeader>
          </Card>
        )}
      </div>
    </>
  );
}

export default App;
