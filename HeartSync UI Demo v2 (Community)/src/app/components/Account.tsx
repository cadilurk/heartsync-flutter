import { User, Heart, Link2, Settings, LogOut, Camera, Copy, Check } from "lucide-react";
import { useState } from "react";

export function Account() {
  const [copied, setCopied] = useState(false);

  // Mock user data
  const user = {
    name: "Emma Wilson",
    email: "emma.wilson@email.com",
    avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop",
    anniversaryDate: "Jan 14, 2024",
    pairingCode: "LOVE2024",
    partnerName: "Alex Johnson",
    partnerConnected: true,
  };

  const handleCopyCode = () => {
    navigator.clipboard.writeText(user.pairingCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="min-h-full px-4 py-6 max-w-md mx-auto pb-8">
      {/* Header */}
      <div className="text-center mb-8">
        <h1 className="text-2xl font-bold bg-gradient-to-r from-rose-500 to-purple-500 bg-clip-text text-transparent mb-2">
          My Account
        </h1>
        <p className="text-gray-500 text-sm">Manage your love journey 💖</p>
      </div>

      {/* Profile Card */}
      <div className="relative mb-6">
        <div className="bg-gradient-to-br from-pink-400 via-rose-400 to-purple-500 rounded-3xl p-6 shadow-2xl">
          <div className="flex flex-col items-center">
            {/* Avatar */}
            <div className="relative mb-4">
              <div className="w-24 h-24 rounded-full overflow-hidden border-4 border-white shadow-lg">
                <img
                  src={user.avatar}
                  alt={user.name}
                  className="w-full h-full object-cover"
                />
              </div>
              <button className="absolute bottom-0 right-0 w-8 h-8 bg-white rounded-full flex items-center justify-center shadow-lg hover:scale-110 transition-transform">
                <Camera className="w-4 h-4 text-rose-500" />
              </button>
            </div>

            {/* User Info */}
            <h2 className="text-white text-xl font-bold mb-1">{user.name}</h2>
            <p className="text-white/90 text-sm mb-3">{user.email}</p>

            {/* Anniversary Badge */}
            <div className="bg-white/20 backdrop-blur-sm rounded-full px-4 py-2 flex items-center gap-2">
              <Heart className="w-4 h-4 text-white fill-white" />
              <span className="text-white text-sm font-medium">
                Together since {user.anniversaryDate}
              </span>
            </div>
          </div>
        </div>

        {/* Decorative elements */}
        <div className="absolute -top-2 -right-2 w-12 h-12 bg-yellow-300 rounded-full blur-xl opacity-50"></div>
        <div className="absolute -bottom-2 -left-2 w-16 h-16 bg-pink-300 rounded-full blur-xl opacity-50"></div>
      </div>

      {/* Partner Connection */}
      <div className="mb-6">
        <h3 className="text-lg font-semibold text-gray-800 mb-4 flex items-center gap-2">
          <Link2 className="w-5 h-5 text-rose-500" />
          Partner Connection
        </h3>

        {user.partnerConnected ? (
          <div className="bg-white/70 backdrop-blur rounded-2xl p-5 border border-pink-100">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 bg-gradient-to-br from-purple-400 to-pink-400 rounded-full flex items-center justify-center">
                  <Heart className="w-6 h-6 text-white fill-white" />
                </div>
                <div>
                  <p className="font-medium text-gray-800">{user.partnerName}</p>
                  <p className="text-sm text-green-500 flex items-center gap-1">
                    <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
                    Connected
                  </p>
                </div>
              </div>
              <button className="text-rose-500 text-sm font-medium hover:text-rose-600">
                Disconnect
              </button>
            </div>

            <div className="pt-3 border-t border-pink-100">
              <p className="text-xs text-gray-500 mb-2">Your Pairing Code</p>
              <div className="flex items-center justify-between bg-gradient-to-r from-rose-50 to-pink-50 rounded-lg p-3">
                <span className="font-mono text-lg font-bold text-rose-500">{user.pairingCode}</span>
                <button
                  onClick={handleCopyCode}
                  className="flex items-center gap-1 text-sm text-rose-500 hover:text-rose-600 transition-colors"
                >
                  {copied ? (
                    <>
                      <Check className="w-4 h-4" />
                      <span>Copied!</span>
                    </>
                  ) : (
                    <>
                      <Copy className="w-4 h-4" />
                      <span>Copy</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        ) : (
          <div className="bg-white/70 backdrop-blur rounded-2xl p-5 border border-pink-100">
            <div className="text-center mb-4">
              <div className="w-16 h-16 bg-gradient-to-br from-gray-100 to-gray-200 rounded-full flex items-center justify-center mx-auto mb-3">
                <Link2 className="w-8 h-8 text-gray-400" />
              </div>
              <p className="text-gray-600 font-medium mb-1">No Partner Connected</p>
              <p className="text-sm text-gray-500">Share your code or enter your partner's code</p>
            </div>

            <div className="space-y-3">
              <div>
                <p className="text-xs text-gray-500 mb-2">Your Pairing Code</p>
                <div className="flex items-center justify-between bg-gradient-to-r from-rose-50 to-pink-50 rounded-lg p-3">
                  <span className="font-mono text-lg font-bold text-rose-500">{user.pairingCode}</span>
                  <button
                    onClick={handleCopyCode}
                    className="flex items-center gap-1 text-sm text-rose-500 hover:text-rose-600 transition-colors"
                  >
                    {copied ? (
                      <>
                        <Check className="w-4 h-4" />
                        <span>Copied!</span>
                      </>
                    ) : (
                      <>
                        <Copy className="w-4 h-4" />
                        <span>Copy</span>
                      </>
                    )}
                  </button>
                </div>
              </div>

              <div>
                <p className="text-xs text-gray-500 mb-2">Enter Partner's Code</p>
                <div className="flex gap-2">
                  <input
                    type="text"
                    placeholder="XXXXXXXX"
                    className="flex-1 px-4 py-2 rounded-lg border border-pink-200 focus:outline-none focus:ring-2 focus:ring-rose-400 bg-white/50"
                  />
                  <button className="px-6 py-2 bg-gradient-to-r from-rose-400 to-pink-400 text-white rounded-lg font-medium shadow hover:shadow-lg transition-shadow">
                    Connect
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Account Settings */}
      <div className="mb-6">
        <h3 className="text-lg font-semibold text-gray-800 mb-4 flex items-center gap-2">
          <Settings className="w-5 h-5 text-rose-500" />
          Settings
        </h3>

        <div className="space-y-3">
          <button className="w-full bg-white/70 backdrop-blur rounded-xl p-4 border border-pink-100 flex items-center justify-between hover:bg-white/90 transition-colors">
            <div className="flex items-center gap-3">
              <User className="w-5 h-5 text-gray-600" />
              <span className="text-gray-800 font-medium">Edit Profile</span>
            </div>
            <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>

          <button className="w-full bg-white/70 backdrop-blur rounded-xl p-4 border border-pink-100 flex items-center justify-between hover:bg-white/90 transition-colors">
            <div className="flex items-center gap-3">
              <Heart className="w-5 h-5 text-gray-600" />
              <span className="text-gray-800 font-medium">Anniversary Date</span>
            </div>
            <span className="text-sm text-gray-500">{user.anniversaryDate}</span>
          </button>

          <button className="w-full bg-white/70 backdrop-blur rounded-xl p-4 border border-pink-100 flex items-center justify-between hover:bg-white/90 transition-colors">
            <div className="flex items-center gap-3">
              <Settings className="w-5 h-5 text-gray-600" />
              <span className="text-gray-800 font-medium">Notifications</span>
            </div>
            <div className="w-12 h-6 bg-rose-400 rounded-full relative">
              <div className="absolute right-1 top-1 w-4 h-4 bg-white rounded-full"></div>
            </div>
          </button>
        </div>
      </div>

      {/* Logout Button */}
      <button className="w-full bg-gradient-to-r from-gray-100 to-gray-200 text-gray-700 py-3 rounded-xl font-medium shadow hover:shadow-lg transition-shadow flex items-center justify-center gap-2">
        <LogOut className="w-5 h-5" />
        Log Out
      </button>
    </div>
  );
}
