import { Trophy, Video, MapPin, Coffee, CheckCircle2, Clock, AlertCircle } from "lucide-react";
import { useState } from "react";

export function HeartChallenges() {
  const [petLevel] = useState(5);
  const [petHappiness] = useState(85);
  const [daysActive] = useState(3);

  const challenges = [
    {
      id: 1,
      title: "15-minute video call",
      description: "Chat via video call for at least 15 minutes",
      icon: Video,
      points: 10,
      status: "available" as const,
      color: "from-blue-400 to-cyan-400",
    },
    {
      id: 2,
      title: "Check-in together",
      description: "Check-in at the same location",
      icon: MapPin,
      points: 15,
      status: "completed" as const,
      color: "from-green-400 to-emerald-400",
    },
    {
      id: 3,
      title: "Order food for partner",
      description: "Send a surprise food order to your partner",
      icon: Coffee,
      points: 20,
      status: "available" as const,
      color: "from-orange-400 to-amber-400",
    },
    {
      id: 4,
      title: "Send 5 love messages",
      description: "Send at least 5 sweet messages today",
      icon: CheckCircle2,
      points: 5,
      status: "completed" as const,
      color: "from-pink-400 to-rose-400",
    },
  ];

  const completedToday = challenges.filter(c => c.status === "completed").length;

  return (
    <div className="min-h-full px-4 py-6 max-w-md mx-auto pb-24">
      {/* Header */}
      <div className="text-center mb-6">
        <h1 className="text-2xl font-bold bg-gradient-to-r from-rose-500 to-purple-500 bg-clip-text text-transparent mb-2">
          Heart Challenges
        </h1>
        <p className="text-gray-500 text-sm">Raise your love pet together 🐾</p>
      </div>

      {/* Pet Card */}
      <div className="bg-gradient-to-br from-purple-400 via-pink-400 to-rose-400 rounded-3xl p-6 mb-6 shadow-2xl">
        <div className="bg-white/20 backdrop-blur rounded-2xl p-4 mb-4">
          <div className="flex items-center justify-center mb-4">
            <div className="relative">
              <div className="w-32 h-32 rounded-full bg-white/30 backdrop-blur flex items-center justify-center">
                <img
                  src="https://images.unsplash.com/photo-1681062791533-81a44832eb72?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjdXRlJTIwY2F0JTIwa2F3YWlpfGVufDF8fHx8MTc3MjQ1Nzg1NXww&ixlib=rb-4.1.0&q=80&w=1080"
                  alt="Pet"
                  className="w-28 h-28 rounded-full object-cover"
                />
              </div>
              <div className="absolute -top-2 -right-2 bg-yellow-400 text-white px-3 py-1 rounded-full text-sm font-bold shadow-lg">
                Lv.{petLevel}
              </div>
            </div>
          </div>
          
          <h3 className="text-white text-xl font-bold text-center mb-2">
            Love Cat
          </h3>
          
          {/* Happiness Bar */}
          <div className="mb-3">
            <div className="flex justify-between text-white text-sm mb-1">
              <span>Happiness</span>
              <span>{petHappiness}%</span>
            </div>
            <div className="h-3 bg-white/30 rounded-full overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-yellow-300 to-yellow-400 transition-all"
                style={{ width: `${petHappiness}%` }}
              ></div>
            </div>
          </div>

          {/* Level Progress */}
          <div>
            <div className="flex justify-between text-white text-sm mb-1">
              <span>Experience</span>
              <span>320/500</span>
            </div>
            <div className="h-3 bg-white/30 rounded-full overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-purple-300 to-pink-300 transition-all"
                style={{ width: "64%" }}
              ></div>
            </div>
          </div>
        </div>

        {/* Warning */}
        {daysActive < 7 ? (
          <div className="bg-yellow-100 border border-yellow-300 rounded-xl p-3 flex items-start gap-2">
            <AlertCircle className="w-5 h-5 text-yellow-600 flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-sm font-medium text-yellow-800">
                {7 - daysActive} days left to complete challenges
              </p>
              <p className="text-xs text-yellow-700">
                If no challenges completed in 7 days, pet will be frozen
              </p>
            </div>
          </div>
        ) : null}
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        <div className="bg-white/70 backdrop-blur rounded-xl p-3 border border-pink-100 text-center">
          <Trophy className="w-5 h-5 text-yellow-500 mx-auto mb-1" />
          <p className="text-xl font-bold text-gray-800">{completedToday}</p>
          <p className="text-xs text-gray-500">Today</p>
        </div>
        <div className="bg-white/70 backdrop-blur rounded-xl p-3 border border-pink-100 text-center">
          <CheckCircle2 className="w-5 h-5 text-green-500 mx-auto mb-1" />
          <p className="text-xl font-bold text-gray-800">24</p>
          <p className="text-xs text-gray-500">This Week</p>
        </div>
        <div className="bg-white/70 backdrop-blur rounded-xl p-3 border border-pink-100 text-center">
          <Clock className="w-5 h-5 text-purple-500 mx-auto mb-1" />
          <p className="text-xl font-bold text-gray-800">{daysActive}</p>
          <p className="text-xs text-gray-500">Day Streak</p>
        </div>
      </div>

      {/* Daily Challenges */}
      <div className="mb-4">
        <h3 className="text-lg font-semibold text-gray-800 mb-3 flex items-center gap-2">
          <Trophy className="w-5 h-5 text-rose-500" />
          Today's Challenges
        </h3>
      </div>

      <div className="space-y-3">
        {challenges.map((challenge) => {
          const Icon = challenge.icon;
          return (
            <div
              key={challenge.id}
              className={`bg-white/70 backdrop-blur rounded-2xl p-4 border ${
                challenge.status === "completed"
                  ? "border-green-200 bg-green-50/50"
                  : "border-pink-100"
              } relative overflow-hidden`}
            >
              {/* Background gradient */}
              <div
                className={`absolute top-0 right-0 w-24 h-24 bg-gradient-to-br ${challenge.color} opacity-10 rounded-full blur-2xl`}
              ></div>

              <div className="relative flex items-start gap-4">
                <div
                  className={`w-12 h-12 rounded-xl bg-gradient-to-br ${challenge.color} flex items-center justify-center flex-shrink-0`}
                >
                  <Icon className="w-6 h-6 text-white" />
                </div>

                <div className="flex-1">
                  <div className="flex items-start justify-between mb-1">
                    <h4 className="font-semibold text-gray-800">
                      {challenge.title}
                    </h4>
                    {challenge.status === "completed" && (
                      <CheckCircle2 className="w-5 h-5 text-green-500" />
                    )}
                  </div>
                  <p className="text-sm text-gray-600 mb-2">
                    {challenge.description}
                  </p>
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-purple-600">
                      +{challenge.points} points
                    </span>
                    {challenge.status === "available" && (
                      <button className="px-4 py-1 bg-gradient-to-r from-rose-400 to-pink-400 text-white text-sm rounded-lg hover:shadow-md transition-shadow">
                        Start
                      </button>
                    )}
                    {challenge.status === "completed" && (
                      <span className="text-xs text-green-600 font-medium">
                        Completed
                      </span>
                    )}
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Rewards Preview */}
      <div className="mt-6 bg-gradient-to-r from-yellow-100 to-amber-100 rounded-2xl p-4 border border-yellow-200">
        <h4 className="font-semibold text-gray-800 mb-2 flex items-center gap-2">
          <Trophy className="w-5 h-5 text-yellow-600" />
          Upcoming Rewards
        </h4>
        <p className="text-sm text-gray-700">
          Complete 3 more challenges to unlock new pet features! 🎁
        </p>
      </div>
    </div>
  );
}
