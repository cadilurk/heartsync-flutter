import { Heart, Smartphone, Sparkles } from "lucide-react";
import { useState } from "react";
import { motion } from "motion/react";

export function HeartAlarm() {
  const [isShaking, setIsShaking] = useState(false);
  const [lastSent, setLastSent] = useState<Date | null>(null);
  const [signalType, setSignalType] = useState<"miss" | "care" | "love">("love");

  const handleSendSignal = () => {
    setIsShaking(true);
    setLastSent(new Date());
    
    // Simulate vibration
    if (navigator.vibrate) {
      navigator.vibrate([200, 100, 200, 100, 400]);
    }
    
    setTimeout(() => setIsShaking(false), 1000);
  };

  const signals = [
    { type: "miss" as const, emoji: "🥺", label: "Miss You", color: "from-blue-400 to-indigo-400" },
    { type: "care" as const, emoji: "🤗", label: "Care", color: "from-amber-400 to-orange-400" },
    { type: "love" as const, emoji: "❤️", label: "Love You", color: "from-rose-400 to-pink-500" },
  ];

  return (
    <div className="min-h-full px-4 py-6 max-w-md mx-auto">
      {/* Header */}
      <div className="text-center mb-8">
        <h1 className="text-2xl font-bold bg-gradient-to-r from-rose-500 to-purple-500 bg-clip-text text-transparent mb-2">
          Heart Alarm
        </h1>
        <p className="text-gray-500 text-sm">Send love signals to your partner 💌</p>
      </div>

      {/* Main Alarm Button */}
      <div className="relative mb-8 flex justify-center">
        <motion.div
          animate={isShaking ? { rotate: [0, -10, 10, -10, 10, 0] } : {}}
          transition={{ duration: 0.5 }}
          className="relative"
        >
          <button
            onClick={handleSendSignal}
            className={`relative w-48 h-48 rounded-full bg-gradient-to-br ${
              signals.find(s => s.type === signalType)?.color
            } shadow-2xl flex items-center justify-center transition-transform hover:scale-105 active:scale-95`}
          >
            <Heart className="w-24 h-24 text-white fill-white" />
          </button>
          
          {/* Ripple effect */}
          {isShaking && (
            <motion.div
              initial={{ scale: 1, opacity: 0.8 }}
              animate={{ scale: 2, opacity: 0 }}
              transition={{ duration: 1 }}
              className={`absolute inset-0 rounded-full bg-gradient-to-br ${
                signals.find(s => s.type === signalType)?.color
              }`}
            />
          )}
        </motion.div>

        {/* Decorative sparkles */}
        <Sparkles className="absolute top-4 right-8 w-8 h-8 text-yellow-400 animate-pulse" />
        <Sparkles className="absolute bottom-8 left-4 w-6 h-6 text-pink-400 animate-pulse delay-300" />
      </div>

      <p className="text-center text-gray-600 mb-8">
        {isShaking ? "Sending..." : "Tap or shake your phone"}
      </p>

      {/* Signal Type Selection */}
      <div className="mb-8">
        <h3 className="text-sm font-medium text-gray-700 mb-3 text-center">
          Choose Signal Type
        </h3>
        <div className="grid grid-cols-3 gap-3">
          {signals.map((signal) => (
            <button
              key={signal.type}
              onClick={() => setSignalType(signal.type)}
              className={`p-4 rounded-2xl border-2 transition-all ${
                signalType === signal.type
                  ? "border-rose-400 bg-rose-50 shadow-md"
                  : "border-pink-100 bg-white/70 hover:border-rose-200"
              }`}
            >
              <div className="text-3xl mb-2">{signal.emoji}</div>
              <p className="text-xs font-medium text-gray-700">{signal.label}</p>
            </button>
          ))}
        </div>
      </div>

      {/* Status Card */}
      <div className="bg-white/70 backdrop-blur rounded-2xl p-6 border border-pink-100 mb-6">
        <div className="flex items-center gap-3 mb-4">
          <Smartphone className="w-5 h-5 text-rose-500" />
          <h3 className="font-semibold text-gray-800">Connection Status</h3>
        </div>
        
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-gray-600 text-sm">Your Partner</span>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
              <span className="text-sm font-medium text-green-600">Online</span>
            </div>
          </div>
          
          <div className="flex items-center justify-between">
            <span className="text-gray-600 text-sm">Distance</span>
            <span className="text-sm font-medium text-gray-800">Close by</span>
          </div>
          
          {lastSent && (
            <div className="flex items-center justify-between pt-3 border-t border-pink-100">
              <span className="text-gray-600 text-sm">Last Sent</span>
              <span className="text-sm font-medium text-gray-800">
                {lastSent.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
              </span>
            </div>
          )}
        </div>
      </div>

      {/* Recent Signals */}
      <div className="bg-white/70 backdrop-blur rounded-2xl p-6 border border-pink-100">
        <h3 className="font-semibold text-gray-800 mb-4">Recent Signals</h3>
        
        <div className="space-y-3">
          <div className="flex items-center gap-3 text-sm">
            <div className="w-10 h-10 rounded-full bg-rose-100 flex items-center justify-center">
              ❤️
            </div>
            <div className="flex-1">
              <p className="font-medium text-gray-800">You sent "Love You"</p>
              <p className="text-xs text-gray-500">5 minutes ago</p>
            </div>
          </div>
          
          <div className="flex items-center gap-3 text-sm">
            <div className="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center">
              🤗
            </div>
            <div className="flex-1">
              <p className="font-medium text-gray-800">Partner sent "Care"</p>
              <p className="text-xs text-gray-500">2 hours ago</p>
            </div>
          </div>
          
          <div className="flex items-center gap-3 text-sm">
            <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center">
              🥺
            </div>
            <div className="flex-1">
              <p className="font-medium text-gray-800">You sent "Miss You"</p>
              <p className="text-xs text-gray-500">Yesterday</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
