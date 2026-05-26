import { Camera, Heart, Lock, MessageCircle, Plus, Image as ImageIcon } from "lucide-react";
import { useState } from "react";

export function HeartSpace() {
  const [activeTab, setActiveTab] = useState<"photos" | "notes">("photos");

  const memories = [
    {
      id: 1,
      type: "photo",
      url: "https://images.unsplash.com/photo-1658851866325-49fb8b7fbcb2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb3VwbGUlMjByb21hbnRpYyUyMHN1bnNldHxlbnwxfHx8fDE3NzIzODI1MTl8MA&ixlib=rb-4.1.0&q=80&w=1080",
      caption: "First sunset together",
      date: "Feb 14, 2024",
    },
    {
      id: 2,
      type: "photo",
      url: "https://images.unsplash.com/photo-1688421937759-7c2b066d8371?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb3VwbGUlMjBob2xkaW5nJTIwaGFuZHMlMjBiZWFjaHxlbnwxfHx8fDE3NzI0NTc4MTN8MA&ixlib=rb-4.1.0&q=80&w=1080",
      caption: "Beach memories",
      date: "Mar 20, 2024",
    },
    {
      id: 3,
      type: "photo",
      url: "https://images.unsplash.com/photo-1693462467631-e013fa26062d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb3VwbGUlMjBjYWZlJTIwZGF0ZXxlbnwxfHx8fDE3NzI0NTA5NzR8MA&ixlib=rb-4.1.0&q=80&w=1080",
      caption: "Our first date",
      date: "Apr 05, 2024",
    },
    {
      id: 4,
      type: "photo",
      url: "https://images.unsplash.com/photo-1614680889829-9b2d25a71be0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxyb21hbnRpYyUyMGRpbm5lciUyMGNhbmRsZXN8ZW58MXx8fHwxNzcyNDU3ODE0fDA&ixlib=rb-4.1.0&q=80&w=1080",
      caption: "Romantic dinner",
      date: "May 10, 2024",
    },
  ];

  const notes = [
    {
      id: 1,
      title: "First Meeting",
      content: "You wore a white shirt that day, with the brightest smile. I knew right then you were the one...",
      date: "Jan 14, 2024",
      emoji: "💕",
    },
    {
      id: 2,
      title: "Da Lat Trip",
      content: "Those days in Da Lat were unforgettable. We watched sunsets together, walked in the morning mist...",
      date: "Feb 28, 2024",
      emoji: "🌄",
    },
    {
      id: 3,
      title: "First Home-cooked Meal",
      content: "The food wasn't perfect but it was made with love. I'll never forget that moment...",
      date: "Mar 15, 2024",
      emoji: "🍳",
    },
  ];

  return (
    <div className="min-h-full px-4 py-6 max-w-md mx-auto pb-24">
      {/* Header */}
      <div className="text-center mb-6">
        <h1 className="text-2xl font-bold bg-gradient-to-r from-rose-500 to-purple-500 bg-clip-text text-transparent mb-2">
          Heart Space
        </h1>
        <p className="text-gray-500 text-sm flex items-center justify-center gap-2">
          <Lock className="w-4 h-4" />
          Your private space together
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        <div className="bg-white/70 backdrop-blur rounded-xl p-3 border border-pink-100 text-center">
          <ImageIcon className="w-5 h-5 text-rose-500 mx-auto mb-1" />
          <p className="text-xl font-bold text-gray-800">156</p>
          <p className="text-xs text-gray-500">Photos</p>
        </div>
        <div className="bg-white/70 backdrop-blur rounded-xl p-3 border border-pink-100 text-center">
          <MessageCircle className="w-5 h-5 text-purple-500 mx-auto mb-1" />
          <p className="text-xl font-bold text-gray-800">42</p>
          <p className="text-xs text-gray-500">Notes</p>
        </div>
        <div className="bg-white/70 backdrop-blur rounded-xl p-3 border border-pink-100 text-center">
          <Heart className="w-5 h-5 text-pink-500 mx-auto mb-1" />
          <p className="text-xl font-bold text-gray-800">24</p>
          <p className="text-xs text-gray-500">Moments</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 mb-6 bg-white/70 backdrop-blur rounded-xl p-1 border border-pink-100">
        <button
          onClick={() => setActiveTab("photos")}
          className={`flex-1 py-2 px-4 rounded-lg font-medium transition-all ${
            activeTab === "photos"
              ? "bg-gradient-to-r from-rose-400 to-pink-400 text-white shadow-md"
              : "text-gray-600 hover:text-gray-800"
          }`}
        >
          <Camera className="w-4 h-4 inline mr-2" />
          Photos
        </button>
        <button
          onClick={() => setActiveTab("notes")}
          className={`flex-1 py-2 px-4 rounded-lg font-medium transition-all ${
            activeTab === "notes"
              ? "bg-gradient-to-r from-rose-400 to-pink-400 text-white shadow-md"
              : "text-gray-600 hover:text-gray-800"
          }`}
        >
          <MessageCircle className="w-4 h-4 inline mr-2" />
          Notes
        </button>
      </div>

      {/* Content */}
      {activeTab === "photos" ? (
        <div className="grid grid-cols-2 gap-3 mb-6">
          {memories.map((memory) => (
            <div
              key={memory.id}
              className="relative aspect-square rounded-2xl overflow-hidden shadow-lg group"
            >
              <img
                src={memory.url}
                alt={memory.caption}
                className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity">
                <div className="absolute bottom-0 left-0 right-0 p-3">
                  <p className="text-white text-sm font-medium mb-1">
                    {memory.caption}
                  </p>
                  <p className="text-white/80 text-xs">{memory.date}</p>
                </div>
              </div>
            </div>
          ))}

          {/* Add Photo Button */}
          <button className="aspect-square rounded-2xl border-2 border-dashed border-pink-300 bg-pink-50/50 flex flex-col items-center justify-center gap-2 hover:bg-pink-100/50 transition-colors">
            <Plus className="w-8 h-8 text-pink-400" />
            <span className="text-sm text-pink-600 font-medium">Add Photo</span>
          </button>
        </div>
      ) : (
        <div className="space-y-4 mb-6">
          {notes.map((note) => (
            <div
              key={note.id}
              className="bg-white/70 backdrop-blur rounded-2xl p-4 border border-pink-100 hover:shadow-md transition-shadow"
            >
              <div className="flex items-start gap-3">
                <div className="text-3xl">{note.emoji}</div>
                <div className="flex-1">
                  <h3 className="font-semibold text-gray-800 mb-1">
                    {note.title}
                  </h3>
                  <p className="text-sm text-gray-600 mb-2 line-clamp-2">
                    {note.content}
                  </p>
                  <p className="text-xs text-gray-400">{note.date}</p>
                </div>
              </div>
            </div>
          ))}

          {/* Add Note Button */}
          <button className="w-full py-4 rounded-2xl border-2 border-dashed border-pink-300 bg-pink-50/50 flex items-center justify-center gap-2 hover:bg-pink-100/50 transition-colors">
            <Plus className="w-5 h-5 text-pink-400" />
            <span className="text-sm text-pink-600 font-medium">
              Add New Note
            </span>
          </button>
        </div>
      )}

      {/* Upload Button */}
      <div className="fixed bottom-24 right-4 z-10">
        <button className="w-14 h-14 rounded-full bg-gradient-to-r from-rose-400 to-pink-500 shadow-xl flex items-center justify-center hover:shadow-2xl transition-shadow">
          <Plus className="w-6 h-6 text-white" />
        </button>
      </div>
    </div>
  );
}
