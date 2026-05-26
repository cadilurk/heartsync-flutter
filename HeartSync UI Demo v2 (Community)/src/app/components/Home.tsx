import { Heart, Calendar, Sparkles } from "lucide-react";
import { useState, useEffect } from "react";

export function Home() {
  const [days, setDays] = useState(0);
  
  // Mock start date - in real app, this would come from database
  const startDate = new Date("2024-01-14");
  
  useEffect(() => {
    const calculateDays = () => {
      const today = new Date();
      const diffTime = Math.abs(today.getTime() - startDate.getTime());
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
      setDays(diffDays);
    };
    
    calculateDays();
    const interval = setInterval(calculateDays, 1000 * 60 * 60); // Update every hour
    
    return () => clearInterval(interval);
  }, []);

  const milestones = [
    { id: 1, title: "First Meeting", date: "Jan 14, 2024", emoji: "👋" },
    { id: 2, title: "100 Days Anniversary", date: "Apr 23, 2024", emoji: "💯" },
    { id: 3, title: "Valentine's Day 2025", date: "Feb 14, 2025", emoji: "💝" },
    { id: 4, title: "Your Birthday", date: "Jun 15, 2025", emoji: "🎂" },
  ];

  return (
    <div className="min-h-full px-4 py-6 max-w-md mx-auto">
      {/* Header */}
      <div className="text-center mb-8">
        <h1 className="text-2xl font-bold bg-gradient-to-r from-rose-500 to-purple-500 bg-clip-text text-transparent mb-2">
          Our Love Story
        </h1>
        <p className="text-gray-500 text-sm">Every day is worth cherishing 💕</p>
      </div>

      {/* Heart Counter - Main Feature */}
      <div className="relative mb-8">
        <div className="bg-gradient-to-br from-pink-400 via-rose-400 to-purple-500 rounded-3xl p-8 shadow-2xl">
          <div className="text-center">
            <div className="flex justify-center mb-4">
              <Heart className="w-16 h-16 text-white fill-white animate-pulse" />
            </div>
            <h2 className="text-white text-lg font-medium mb-2">
              We've been together for
            </h2>
            <div className="text-7xl font-bold text-white mb-2">{days}</div>
            <p className="text-white/90 text-xl">days</p>
          </div>
        </div>
        
        {/* Decorative elements */}
        <div className="absolute -top-2 -right-2 w-12 h-12 bg-yellow-300 rounded-full blur-xl opacity-50"></div>
        <div className="absolute -bottom-2 -left-2 w-16 h-16 bg-pink-300 rounded-full blur-xl opacity-50"></div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-2 gap-4 mb-8">
        <div className="bg-white/70 backdrop-blur rounded-2xl p-4 border border-pink-100">
          <div className="flex items-center gap-2 mb-2">
            <Sparkles className="w-5 h-5 text-yellow-500" />
            <span className="text-gray-600 text-sm">Challenges</span>
          </div>
          <p className="text-2xl font-bold text-gray-800">24</p>
          <p className="text-xs text-gray-500">Completed</p>
        </div>
        
        <div className="bg-white/70 backdrop-blur rounded-2xl p-4 border border-pink-100">
          <div className="flex items-center gap-2 mb-2">
            <Calendar className="w-5 h-5 text-rose-500" />
            <span className="text-gray-600 text-sm">Memories</span>
          </div>
          <p className="text-2xl font-bold text-gray-800">156</p>
          <p className="text-xs text-gray-500">Saved</p>
        </div>
      </div>

      {/* Milestones */}
      <div className="mb-6">
        <h3 className="text-lg font-semibold text-gray-800 mb-4 flex items-center gap-2">
          <Calendar className="w-5 h-5 text-rose-500" />
          Important Milestones
        </h3>
        
        <div className="space-y-3">
          {milestones.map((milestone) => (
            <div
              key={milestone.id}
              className="bg-white/70 backdrop-blur rounded-xl p-4 border border-pink-100 flex items-center gap-4"
            >
              <div className="text-3xl">{milestone.emoji}</div>
              <div className="flex-1">
                <h4 className="font-medium text-gray-800">{milestone.title}</h4>
                <p className="text-sm text-gray-500">{milestone.date}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Add Milestone Button */}
      <button className="w-full bg-gradient-to-r from-rose-400 to-pink-400 text-white py-3 rounded-xl font-medium shadow-lg hover:shadow-xl transition-shadow">
        + Add New Milestone
      </button>
    </div>
  );
}
