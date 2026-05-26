import { Gift, Heart, Search, Star, TrendingUp, Calendar } from "lucide-react";
import { useState } from "react";

export function HeartStore() {
  const [activeCategory, setActiveCategory] = useState<"all" | "valentine" | "anniversary" | "birthday">("all");

  const categories = [
    { id: "all" as const, label: "All", icon: Gift },
    { id: "valentine" as const, label: "Valentine", icon: Heart },
    { id: "anniversary" as const, label: "Anniversary", icon: Calendar },
    { id: "birthday" as const, label: "Birthday", icon: Star },
  ];

  const products = [
    {
      id: 1,
      name: "Rose Gift Box",
      price: "$35",
      image: "https://images.unsplash.com/photo-1723274154450-654d2250ccbb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxnaWZ0JTIwYm94JTIwcm9zZXN8ZW58MXx8fHwxNzcyNDU3ODk4fDA&ixlib=rb-4.1.0&q=80&w=1080",
      category: "valentine",
      rating: 4.8,
      sold: 234,
    },
    {
      id: 2,
      name: "Premium Silver Necklace",
      price: "$52",
      image: "https://images.unsplash.com/photo-1643300866907-032b3baeeb1f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxqZXdlbHJ5JTIwbmVja2xhY2V8ZW58MXx8fHwxNzcyNDU3ODk4fDA&ixlib=rb-4.1.0&q=80&w=1080",
      category: "anniversary",
      rating: 4.9,
      sold: 156,
    },
    {
      id: 3,
      name: "Luxury Perfume",
      price: "$88",
      image: "https://images.unsplash.com/photo-1747052881000-a640a4981dd0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwZXJmdW1lJTIwYm90dGxlJTIwZWxlZ2FudHxlbnwxfHx8fDE3NzI0MTg1MTh8MA&ixlib=rb-4.1.0&q=80&w=1080",
      category: "birthday",
      rating: 4.7,
      sold: 98,
    },
    {
      id: 4,
      name: "Valentine Chocolate Box",
      price: "$19",
      image: "https://images.unsplash.com/photo-1620527792840-30bee250b846?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjaG9jb2xhdGUlMjBib3glMjB2YWxlbnRpbmV8ZW58MXx8fHwxNzcyNDU3ODk5fDA&ixlib=rb-4.1.0&q=80&w=1080",
      category: "valentine",
      rating: 4.6,
      sold: 412,
    },
  ];

  const filteredProducts = activeCategory === "all" 
    ? products 
    : products.filter(p => p.category === activeCategory);

  return (
    <div className="min-h-full px-4 py-6 max-w-md mx-auto pb-24">
      {/* Header */}
      <div className="text-center mb-6">
        <h1 className="text-2xl font-bold bg-gradient-to-r from-rose-500 to-purple-500 bg-clip-text text-transparent mb-2">
          Heart Store
        </h1>
        <p className="text-gray-500 text-sm">Gift suggestions for your love 🎁</p>
      </div>

      {/* Search Bar */}
      <div className="mb-6">
        <div className="relative">
          <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="Search for gifts..."
            className="w-full pl-12 pr-4 py-3 bg-white/70 backdrop-blur border border-pink-100 rounded-xl focus:outline-none focus:ring-2 focus:ring-rose-300"
          />
        </div>
      </div>

      {/* Occasion Banner */}
      <div className="bg-gradient-to-r from-rose-400 via-pink-400 to-purple-400 rounded-2xl p-4 mb-6 shadow-lg">
        <div className="flex items-center gap-3 text-white">
          <TrendingUp className="w-6 h-6" />
          <div>
            <h3 className="font-semibold">Valentine's Day is coming!</h3>
            <p className="text-sm text-white/90">Prepare gifts for your loved one 💝</p>
          </div>
        </div>
      </div>

      {/* Categories */}
      <div className="mb-6">
        <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
          {categories.map((category) => {
            const Icon = category.icon;
            return (
              <button
                key={category.id}
                onClick={() => setActiveCategory(category.id)}
                className={`flex items-center gap-2 px-4 py-2 rounded-xl whitespace-nowrap transition-all ${
                  activeCategory === category.id
                    ? "bg-gradient-to-r from-rose-400 to-pink-400 text-white shadow-md"
                    : "bg-white/70 text-gray-600 border border-pink-100 hover:border-rose-200"
                }`}
              >
                <Icon className="w-4 h-4" />
                <span className="text-sm font-medium">{category.label}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Products Grid */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        {filteredProducts.map((product) => (
          <div
            key={product.id}
            className="bg-white/70 backdrop-blur rounded-2xl overflow-hidden border border-pink-100 hover:shadow-lg transition-shadow"
          >
            {/* Product Image */}
            <div className="relative aspect-square overflow-hidden">
              <img
                src={product.image}
                alt={product.name}
                className="w-full h-full object-cover hover:scale-110 transition-transform duration-300"
              />
              <div className="absolute top-2 right-2 bg-white/90 backdrop-blur px-2 py-1 rounded-lg flex items-center gap-1">
                <Star className="w-3 h-3 text-yellow-500 fill-yellow-500" />
                <span className="text-xs font-medium text-gray-800">
                  {product.rating}
                </span>
              </div>
            </div>

            {/* Product Info */}
            <div className="p-3">
              <h3 className="font-semibold text-gray-800 text-sm mb-1 line-clamp-2">
                {product.name}
              </h3>
              <p className="text-rose-600 font-bold mb-2">{product.price}</p>
              <div className="flex items-center justify-between">
                <span className="text-xs text-gray-500">
                  {product.sold} sold
                </span>
                <button className="p-1.5 bg-rose-100 rounded-lg hover:bg-rose-200 transition-colors">
                  <Heart className="w-4 h-4 text-rose-500" />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Suggestion Box */}
      <div className="bg-gradient-to-br from-purple-100 to-pink-100 rounded-2xl p-5 border border-pink-200">
        <h3 className="font-semibold text-gray-800 mb-3 flex items-center gap-2">
          <Gift className="w-5 h-5 text-purple-500" />
          Suggestions for You
        </h3>
        <p className="text-sm text-gray-700 mb-3">
          Based on your relationship, we suggest:
        </p>
        <div className="space-y-2">
          <div className="bg-white/70 rounded-xl p-3 flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-rose-100 flex items-center justify-center">
              🌹
            </div>
            <div className="flex-1">
              <p className="font-medium text-gray-800 text-sm">Red Roses</p>
              <p className="text-xs text-gray-500">Perfect for Valentine's</p>
            </div>
          </div>
          <div className="bg-white/70 rounded-xl p-3 flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-purple-100 flex items-center justify-center">
              💍
            </div>
            <div className="flex-1">
              <p className="font-medium text-gray-800 text-sm">Couple Rings</p>
              <p className="text-xs text-gray-500">For long-term couples</p>
            </div>
          </div>
        </div>
      </div>

      {/* Info Note */}
      <div className="mt-6 bg-blue-50 border border-blue-200 rounded-xl p-4">
        <p className="text-sm text-blue-800">
          <span className="font-medium">📦 Note:</span> We connect you with trusted shops. 
          Shipping and product quality are guaranteed by the shops.
        </p>
      </div>
    </div>
  );
}
