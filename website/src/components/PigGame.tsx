"use client";

import { useEffect, useState, useRef } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useWalletClient } from "@thalalabs/surf/hooks";
// Internal components
import { toast } from "@/components/ui/use-toast";
import { aptosClient } from "@/utils/aptosClient";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { AccountAddress, Aptos, TypeTag, TypeTagAddress } from "@aptos-labs/ts-sdk";

// Utility to shorten addresses
function shortenAddress(addr?: string) {
  if (!addr) return "";
  if (addr.length <= 10) return addr;
  return `${addr.slice(0, 5)}..${addr.slice(-3)}`;
}

// Address with tooltip and copy
function AddressWithTooltip({ address }: { address?: string }) {
  const [show, setShow] = useState(false);
  const [copied, setCopied] = useState(false);
  if (!address) return null;
  return (
    <span
      className="relative cursor-pointer underline decoration-dotted"
      onMouseEnter={() => setShow(true)}
      onMouseLeave={() => {
        setShow(false);
        setCopied(false);
      }}
      tabIndex={0}
      onFocus={() => setShow(true)}
      onBlur={() => {
        setShow(false);
        setCopied(false);
      }}
      onClick={() => {
        navigator.clipboard.writeText(address);
        setCopied(true);
      }}
    >
      {shortenAddress(address)}
      {show && (
        <span className="absolute left-1/2 top-full z-10 mt-2 -translate-x-1/2 whitespace-nowrap rounded bg-[#F5E2C4] text-black px-3 py-2 text-xs shadow-lg border border-black flex items-center gap-2">
          <span>{copied ? "Copied!" : address}</span>
        </span>
      )}
    </span>
  );
}

export function PigGame() {
  const { account } = useWallet();
  const { client, connected } = useWalletClient();

  const queryClient = useQueryClient();

  const PIG_MASTER_ADDRESS =
    process.env.NEXT_PIG_MASTER_ADDRESS ?? "0xda81e838661e2e314b08c09efd26db04c529e02e26359bdafd3ad6fff81489d7";

  const [moduleAddress, setModuleAddress] = useState<string | undefined>(
    process.env.NEXT_DEFAULT_CONTRACT_ADDRESS ?? "0xea1355afdf213b84cd4266b5c2c530ebda7d9dd0b2edd9170185b9a6cfd174a2",
  );
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [gameTotalScore, setGameTotalScore] = useState<number>(0);
  const [gameTurnScore, setGameTurnScore] = useState<number>(0);
  const [rolling, setRolling] = useState(false);
  const [displayRoll, setDisplayRoll] = useState<number>(1);
  const [topUserScore, setTopUserScore] = useState<{
    rounds: string;
    score: string;
    turns: string;
  }>();
  const [topGlobalScore, setTopGlobalScore] = useState<{
    result: {
      rounds: string;
      score: string;
      turns: string;
    };
    user: string;
  }>();
  const [contractUserGamesPlayed, setContractUserGamesPlayed] = useState<number>(0);
  const [contractGamesPlayed, setContractGamesPlayed] = useState<number>(0);
  const [globalUserGamesPlayed, setGlobalUserGamesPlayed] = useState<number>(0);
  const [globalGamesPlayed, setGlobalGamesPlayed] = useState<number>(0);
  const [globalPlayers, setGlobalPlayers] = useState<number>(0);
  const [round, setRound] = useState<number>(0);
  const [turn, setTurn] = useState<number>(0);
  const [gameOver, setGameOver] = useState<boolean>(false);
  const [lastRoll, setLastRoll] = useState<number>(1);

  const rollIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  async function rollDice() {
    if (!connected || !client) {
      return;
    }
    setRolling(true);
    // Play dice sound
    if (audioRef.current) {
      audioRef.current.currentTime = 0;
      audioRef.current.loop = true;
      audioRef.current.play();
    }
    // Start rolling animation
    if (rollIntervalRef.current) clearInterval(rollIntervalRef.current);
    rollIntervalRef.current = setInterval(() => {
      setDisplayRoll(Math.floor(Math.random() * 6) + 1);
    }, 100);
    try {
      // Call contract
      const committedTransaction = await client.submitTransaction({
        function: `${moduleAddress}::pig_game::roll_dice`,
        typeArguments: [],
        functionArguments: [],
      });
      const executedTransaction = await aptosClient().waitForTransaction({
        transactionHash: committedTransaction.hash,
      });
      queryClient.invalidateQueries({
        queryKey: ["pig-game-state", account?.address],
      });
      toast({
        title: "Success",
        description: `Transaction succeeded, hash: ${executedTransaction.hash}`,
      });
    } catch (error) {
      toast({
        variant: "destructive",
        title: "Error",
        description: error instanceof Error ? error.message : String(error),
      });
    } finally {
      setRolling(false);
    }
  }

  async function holdDice() {
    if (!connected || !client) {
      return;
    }
    const committedTransaction = await client.submitTransaction({
      function: `${moduleAddress}::pig_game::hold`,
      typeArguments: [],
      functionArguments: [],
    });
    const executedTransaction = await aptosClient().waitForTransaction({
      transactionHash: committedTransaction.hash,
    });
    queryClient.invalidateQueries({
      queryKey: ["pig-game-state", account?.address],
    });

    toast({
      title: "Success",
      description: `Transaction succeeded, hash: ${executedTransaction.hash}`,
    });
  }

  async function completeGame() {
    if (!connected || !client) {
      return;
    }
    const committedTransaction = await client.submitTransaction({
      function: `${moduleAddress}::pig_game::complete_game`,
      typeArguments: [],
      functionArguments: [],
    });
    const executedTransaction = await aptosClient().waitForTransaction({
      transactionHash: committedTransaction.hash,
    });
    queryClient.invalidateQueries({
      queryKey: ["pig-game-state", account?.address],
    });

    toast({
      title: "Success",
      description: `Transaction succeeded, hash: ${executedTransaction.hash}`,
    });
  }

  async function resetGame() {
    if (!connected || !client) {
      return;
    }
    const committedTransaction = await client.submitTransaction({
      function: `${moduleAddress}::pig_game::reset_game`,
      typeArguments: [],
      functionArguments: [],
    });
    const executedTransaction = await aptosClient().waitForTransaction({
      transactionHash: committedTransaction.hash,
    });
    queryClient.invalidateQueries({
      queryKey: ["pig-game-state", account?.address],
    });

    toast({
      title: "Success",
      description: `Transaction succeeded, hash: ${executedTransaction.hash}`,
    });
  }

  const { data } = useQuery({
    queryKey: ["pig-game-state", account?.address],
    refetchInterval: 10_000,
    queryFn: async () => {
      try {
        const client = aptosClient();
        view<string>(
          client,
          `${moduleAddress}::pig_game::turn`,
          [account?.address ?? "0x0"],
          [new TypeTagAddress()],
          (val) => {
            setTurn(parseInt(val));
          },
        );
        view<string>(
          client,
          `${moduleAddress}::pig_game::round`,
          [account?.address ?? "0x0"],
          [new TypeTagAddress()],
          (val) => {
            setRound(parseInt(val));
          },
        );
        view<string>(
          client,
          `${moduleAddress}::pig_game::turn_score`,
          [account?.address ?? "0x0"],
          [new TypeTagAddress()],
          (val) => {
            setGameTurnScore(parseInt(val));
          },
        );
        view<string>(
          client,
          `${moduleAddress}::pig_game::total_score`,
          [account?.address ?? "0x0"],
          [new TypeTagAddress()],
          (val) => {
            setGameTotalScore(parseInt(val));
          },
        );
        view<string>(
          client,
          `${moduleAddress}::pig_game::last_roll`,
          [account?.address ?? "0x0"],
          [new TypeTagAddress()],
          (val) => {
            setLastRoll(parseInt(val));
          },
        );
        view<boolean>(
          client,
          `${moduleAddress}::pig_game::game_over`,
          [account?.address ?? "0x0"],
          [new TypeTagAddress()],
          (val) => {
            setGameOver(val);
          },
        );
        view<string>(
          client,
          `${moduleAddress}::pig_game::user_games_played`,
          [account?.address ?? "0x0"],
          [new TypeTagAddress()],
          (val) => {
            setContractUserGamesPlayed(parseInt(val));
          },
        );
        view<string>(client, `${moduleAddress}::pig_game::games_played`, [], [], (val) => {
          setContractGamesPlayed(parseInt(val));
        });
        view<{ vec: string[] }>(
          client,
          `${PIG_MASTER_ADDRESS}::pig_master::user_games_played`,
          [account?.address ?? "0x0"],
          [new TypeTagAddress()],
          ({ vec: val }) => {
            if (val.length === 0) {
              setGlobalUserGamesPlayed(0);
            } else {
              setGlobalUserGamesPlayed(parseInt(val[0]));
            }
          },
        );
        view<string>(client, `${PIG_MASTER_ADDRESS}::pig_master::total_games_played`, [], [], (val) => {
          setGlobalGamesPlayed(parseInt(val));
        });
        view<string>(client, `${PIG_MASTER_ADDRESS}::pig_master::total_players`, [], [], (val) => {
          setGlobalPlayers(parseInt(val));
        });
        view<{
          vec: {
            rounds: string;
            score: string;
            turns: string;
          }[];
        }>(
          client,
          `${PIG_MASTER_ADDRESS}::pig_master::user_top_score`,
          [account?.address ?? "0x0"],
          [new TypeTagAddress()],
          ({ vec: val }) => {
            if (val.length === 0) {
              setTopUserScore({ rounds: "N/A", turns: "N/A", score: "N/A" });
            } else {
              setTopUserScore(val[0]);
            }
          },
        );
        view<{
          vec: {
            result: {
              rounds: string;
              score: string;
              turns: string;
            };
            user: string;
          }[];
        }>(client, `${PIG_MASTER_ADDRESS}::pig_master::global_top_score`, [], [], ({ vec: val }) => {
          if (val.length === 0) {
            setTopGlobalScore({ result: { rounds: "N/A", turns: "N/A", score: "N/A" }, user: "N/A" });
          } else {
            setTopGlobalScore(val[0]);
          }
        });

        return {};
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
      } catch (error: any) {
        toast({
          variant: "destructive",
          title: "Error",
          description: error,
        });
        return {};
      }
    },
  });

  // When lastRoll changes, update displayRoll and stop rolling
  useEffect(() => {
    if (rolling) return;
    setDisplayRoll(gameOver ? 1 : lastRoll);
    if (rollIntervalRef.current) {
      clearInterval(rollIntervalRef.current);
      rollIntervalRef.current = null;
    }
  }, [data, gameOver, lastRoll, rolling]);

  // When rolling becomes false, ensure interval is cleared
  useEffect(() => {
    if (!rolling && rollIntervalRef.current) {
      clearInterval(rollIntervalRef.current);
      rollIntervalRef.current = null;
    }
  }, [rolling]);

  // Dice SVG component
  function Dice({ value, size = 48 }: { value: number; size?: number }) {
    // Dots positions for 1-6
    const dots = [
      [],
      [[0.5, 0.5]], // 1
      [
        [0.25, 0.25],
        [0.75, 0.75],
      ], // 2
      [
        [0.25, 0.25],
        [0.5, 0.5],
        [0.75, 0.75],
      ], // 3
      [
        [0.25, 0.25],
        [0.25, 0.75],
        [0.75, 0.25],
        [0.75, 0.75],
      ], // 4
      [
        [0.25, 0.25],
        [0.25, 0.75],
        [0.5, 0.5],
        [0.75, 0.25],
        [0.75, 0.75],
      ], // 5
      [
        [0.25, 0.25],
        [0.25, 0.5],
        [0.25, 0.75],
        [0.75, 0.25],
        [0.75, 0.5],
        [0.75, 0.75],
      ], // 6
    ];
    return (
      <svg width={size} height={size} viewBox="0 0 48 48" className="mx-auto" style={{ display: "block" }}>
        <rect x="4" y="4" width="40" height="40" rx="10" fill="#F5E2C4" stroke="#000" strokeWidth="3" />
        {dots[value]?.map(([x, y], i) => <circle key={i} cx={4 + x * 40} cy={4 + y * 40} r="4" fill="#000" />)}
      </svg>
    );
  }

  return (
    <div className="flex flex-col gap-8">
      {/* Game Over Banner */}
      {gameOver && (
        <div className="w-full text-center py-4 bg-black text-[#F5E2C4] text-2xl font-bold tracking-widest rounded shadow matrix-flicker mb-2">
          GAME OVER
        </div>
      )}
      {/* Game Address Input */}
      <div className="space-y-2">
        <label className="matrix-subtitle text-sm">CONTRACT ADDRESS:</label>
        <Input
          disabled={!client}
          placeholder="Enter contract address..."
          value={moduleAddress}
          onChange={(e) => setModuleAddress(e.target.value)}
          className="matrix-input"
        />
      </div>

      {/* Game State Display */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="matrix-card p-6 space-y-4">
          <h4 className="matrix-subtitle text-lg text-center">CURRENT GAME</h4>
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="matrix-text">ROLL:</span>
              <Dice value={rolling ? displayRoll : lastRoll} />
            </div>
            <div className="flex justify-between items-center">
              <span className="matrix-text">ROUND:</span>
              <span className="matrix-glow text-xl font-bold">{round}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="matrix-text">TURN:</span>
              <span className="matrix-glow text-xl font-bold">{turn}</span>
            </div>
          </div>
        </div>

        <div className="matrix-card p-6 space-y-4">
          <h4 className="matrix-subtitle text-lg text-center">GAME SCORES</h4>
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="matrix-text">TURN SCORE:</span>
              <span className="matrix-glow text-xl font-bold">{gameTurnScore.toString()}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="matrix-text">TOTAL SCORE:</span>
              <span className="matrix-glow text-xl font-bold">{gameTotalScore.toString()}</span>
            </div>
          </div>
        </div>
        <div className="matrix-card p-6 space-y-4">
          <h4 className="matrix-subtitle text-lg text-center">CONTRACT STATS</h4>
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="matrix-text">USER GAMES PLAYED:</span>
              <span className="matrix-glow text-xl font-bold">{contractUserGamesPlayed.toString()}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="matrix-text">TOTAL GAMES PLAYED:</span>
              <span className="matrix-glow text-xl font-bold">{contractGamesPlayed.toString()}</span>
            </div>
          </div>
        </div>
        <div className="matrix-card p-6 space-y-4">
          <h4 className="matrix-subtitle text-lg text-center">GLOBAL STATS</h4>
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="matrix-text">USER GAMES PLAYED:</span>
              <span className="matrix-glow text-xl font-bold">{globalUserGamesPlayed.toString()}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="matrix-text">TOP GLOBAL USER SCORE:</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="matrix-text">Rounds:</span>
              <span className="matrix-glow text-xl font-bold">{topUserScore?.rounds}</span>
              <span className="matrix-text">Turns:</span>
              <span className="matrix-glow text-xl font-bold">{topUserScore?.turns}</span>
            </div>
            <div className="flex justify-between items-center"></div>
            <div className="flex justify-between items-center">
              <span className="matrix-text">TOTAL GLOBAL PLAYERS:</span>
              <span className="matrix-glow text-xl font-bold">{globalPlayers.toString()}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="matrix-text">GLOBAL GAMES PLAYED:</span>
              <span className="matrix-glow text-xl font-bold">{globalGamesPlayed.toString()}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="matrix-text">TOP GLOBAL SCORE:</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="matrix-text">User:</span>
              <AddressWithTooltip address={topGlobalScore?.user} />
            </div>
            <div className="flex justify-between items-center">
              <span className="matrix-text">Rounds:</span>
              <span className="matrix-glow text-xl font-bold">{topGlobalScore?.result?.rounds}</span>
              <span className="matrix-text">Turns:</span>
              <span className="matrix-glow text-xl font-bold">{topGlobalScore?.result?.turns}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Game Controls */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Button disabled={!client} onClick={rollDice} variant="matrix" className="h-12 text-sm">
          ROLL DICE
        </Button>
        <Button disabled={!client} onClick={holdDice} variant="matrix" className="h-12 text-sm">
          HOLD
        </Button>
        <Button disabled={!client} onClick={completeGame} variant="matrix" className="h-12 text-sm">
          COMPLETE
        </Button>
        <Button disabled={!client} onClick={resetGame} variant="matrix" className="h-12 text-sm">
          RESET
        </Button>
      </div>
    </div>
  );
}

function view<T>(
  client: Aptos,
  fn: `${string}::${string}::${string}`,
  args: (string | AccountAddress)[],
  params: TypeTag[],
  setValue: (val: T) => void,
) {
  client
    .view<[T]>({
      payload: {
        function: fn,
        typeArguments: [],
        functionArguments: args,
        abi: {
          parameters: params,
          typeParameters: [],
          returnTypes: [],
        },
      },
    })
    .then((result) => {
      setValue(result[0]);
    })
    .catch((err) => {
      console.error(`Error fetching view function ${fn}:`, err);
      toast({
        variant: "destructive",
        title: "Error",
        description: `Failed to fetch view function: see console for details.`,
      });
    });
}
