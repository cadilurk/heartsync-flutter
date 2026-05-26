import { MapPin, Navigation, Heart } from "lucide-react";
import { useState } from "react";

export function HeartMap() {
  const [distance] = useState(2.5); // km - mock data
  
  // Distance status based on proximity
  const getDistanceStatus = (dist: number) => {
    if (dist < 1) return { color: "green", status: "Very Close", emoji: "💚", bgColor: "bg-green-100", textColor: "text-green-600" };
    if (dist < 5) return { color: "yellow", status: "Close by", emoji: "💛", bgColor: "bg-yellow-100", textColor: "text-yellow-600" };
    return { color: "red", status: "Far apart", emoji: "❤️", bgColor: "bg-red-100", textColor: "text-red-600" };
  };

  const status = getDistanceStatus(distance);

  return (
    <div className="min-h-full px-4 py-6 max-w-md mx-auto">
      {/* Header */}
      <div className="text-center mb-8">
        <h1 className="text-2xl font-bold bg-gradient-to-r from-rose-500 to-purple-500 bg-clip-text text-transparent mb-2">
          Heart Map
        </h1>
        <p className="text-gray-500 text-sm">Distance between two hearts 🗺️</p>
      </div>

      {/* Map Visualization */}
      <div className="relative mb-8 bg-gradient-to-br from-blue-100 via-purple-100 to-pink-100 rounded-3xl overflow-hidden h-96 shadow-xl">
        {/* Decorative grid */}
        <div className="absolute inset-0 opacity-20">
          <div className="grid grid-cols-8 grid-rows-8 h-full">
            {[...Array(64)].map((_, i) => (
              <div key={i} className="border border-gray-300"></div>
            ))}
          </div>
        </div>

        {/* User 1 - You */}
        <div className="absolute left-1/4 top-1/3 transform -translate-x-1/2 -translate-y-1/2">
          <div className="relative">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-rose-400 to-pink-500 flex items-center justify-center shadow-lg animate-pulse">
              <Heart className="w-8 h-8 text-white fill-white" />
            </div>
            <div className="absolute -top-8 left-1/2 transform -translate-x-1/2 bg-white px-3 py-1 rounded-full shadow-md whitespace-nowrap">
              <span className="text-sm font-medium text-gray-800">You</span>
            </div>
            {/* Ripple effect */}
            <div className="absolute inset-0 rounded-full bg-rose-300 animate-ping opacity-30"></div>
          </div>
        </div>

        {/* User 2 - Partner */}
        <div className="absolute right-1/4 bottom-1/3 transform translate-x-1/2 translate-y-1/2">
          <div className="relative">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-purple-400 to-indigo-500 flex items-center justify-center shadow-lg animate-pulse">
              <Heart className="w-8 h-8 text-white fill-white" />
            </div>
            <div className="absolute -top-8 left-1/2 transform -translate-x-1/2 bg-white px-3 py-1 rounded-full shadow-md whitespace-nowrap">
              <span className="text-sm font-medium text-gray-800">Partner</span>
            </div>
            {/* Ripple effect */}
            <div className="absolute inset-0 rounded-full bg-purple-300 animate-ping opacity-30"></div>
          </div>
        </div>

        {/* Connection Line */}
        <svg className="absolute inset-0 w-full h-full pointer-events-none">
          <line
            x1="25%"
            y1="33%"
            x2="75%"
            y2="67%"
            stroke={status.color === 'green' ? '#10b981' : status.color === 'yellow' ? '#fbbf24' : '#ef4444'}
            strokeWidth="3"
            strokeDasharray="10,5"
            className="opacity-50"
          />
        </svg>
      </div>

      {/* Distance Status Card */}
      <div className={`${status.bgColor} rounded-2xl p-6 mb-6 border-2 border-${status.color}-200`}>
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <span className="text-4xl">{status.emoji}</span>
            <div>
              <h3 className="font-semibold text-gray-800 text-lg">{status.status}</h3>
              <p className="text-sm text-gray-600">Current Status</p>
            </div>
          </div>
          <div className={`w-4 h-4 rounded-full bg-${status.color}-500 animate-pulse`}></div>
        </div>
        
        <div className="flex items-center justify-between pt-4 border-t border-gray-200">
          <span className="text-gray-600">Distance</span>
          <span className={`text-2xl font-bold ${status.textColor}`}>{distance} km</span>
        </div>
      </div>

      {/* Location Details */}
      <div className="space-y-4 mb-6">
        <div className="bg-white/70 backdrop-blur rounded-xl p-4 border border-pink-100 flex items-center gap-4">
          <div className="w-12 h-12 rounded-full bg-rose-100 flex items-center justify-center">
            <MapPin className="w-6 h-6 text-rose-500" />
          </div>
          <div className="flex-1">
            <h4 className="font-medium text-gray-800">Your Location</h4>
            <p className="text-sm text-gray-500">District 1, HCMC</p>
          </div>
          <Navigation className="w-5 h-5 text-gray-400" />
        </div>

        <div className="bg-white/70 backdrop-blur rounded-xl p-4 border border-pink-100 flex items-center gap-4">
          <div className="w-12 h-12 rounded-full bg-purple-100 flex items-center justify-center">
            <MapPin className="w-6 h-6 text-purple-500" />
          </div>
          <div className="flex-1">
            <h4 className="font-medium text-gray-800">Partner's Location</h4>
            <p className="text-sm text-gray-500">District 3, HCMC</p>
          </div>
          <Navigation className="w-5 h-5 text-gray-400" />
        </div>
      </div>

      {/* Distance History */}
      <div className="bg-white/70 backdrop-blur rounded-2xl p-6 border border-pink-100">
        <h3 className="font-semibold text-gray-800 mb-4 flex items-center gap-2">
          <Heart className="w-5 h-5 text-rose-500" />
          Distance History
        </h3>
        
        <div className="space-y-3">
          <div className="flex items-center justify-between text-sm">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-green-500"></div>
              <span className="text-gray-600">Today</span>
            </div>
            <span className="font-medium text-gray-800">2.5 km</span>
          </div>
          
          <div className="flex items-center justify-between text-sm">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-green-500"></div>
              <span className="text-gray-600">Yesterday</span>
            </div>
            <span className="font-medium text-gray-800">0.8 km</span>
          </div>
          
          <div className="flex items-center justify-between text-sm">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-yellow-500"></div>
              <span className="text-gray-600">2 days ago</span>
            </div>
            <span className="font-medium text-gray-800">12 km</span>
          </div>
          
          <div className="flex items-center justify-between text-sm">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-red-500"></div>
              <span className="text-gray-600">3 days ago</span>
            </div>
            <span className="font-medium text-gray-800">45 km</span>
          </div>
        </div>
      </div>
    </div>
  );
}
