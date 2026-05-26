import { Outlet, NavLink } from "react-router";
import { Heart, Bell, Map, Image, Trophy, ShoppingBag, User } from "lucide-react";

export function Layout() {
  const navItems = [
    { to: "/", icon: Heart, label: "Home" },
    { to: "/alarm", icon: Bell, label: "Alarm" },
    { to: "/map", icon: Map, label: "Map" },
    { to: "/space", icon: Image, label: "Space" },
    { to: "/challenges", icon: Trophy, label: "Challenges" },
    { to: "/store", icon: ShoppingBag, label: "Store" },
    { to: "/account", icon: User, label: "Account" },
  ];

  return (
    <div className="flex flex-col h-screen bg-gradient-to-br from-pink-50 via-rose-50 to-purple-50">
      {/* Main Content */}
      <main className="flex-1 overflow-y-auto pb-20">
        <Outlet />
      </main>

      {/* Bottom Navigation */}
      <nav className="fixed bottom-0 left-0 right-0 bg-white/80 backdrop-blur-lg border-t border-pink-100 shadow-lg">
        <div className="max-w-md mx-auto px-2 py-2">
          <div className="flex justify-around items-center">
            {navItems.map(({ to, icon: Icon, label }) => (
              <NavLink
                key={to}
                to={to}
                end={to === "/"}
                className={({ isActive }) =>
                  `flex flex-col items-center gap-1 px-3 py-2 rounded-xl transition-all ${
                    isActive
                      ? "text-rose-500"
                      : "text-gray-400 hover:text-rose-300"
                  }`
                }
              >
                {({ isActive }) => (
                  <>
                    <Icon
                      className={`w-6 h-6 ${isActive ? "fill-rose-500" : ""}`}
                    />
                    <span className="text-xs font-medium">{label}</span>
                  </>
                )}
              </NavLink>
            ))}
          </div>
        </div>
      </nav>
    </div>
  );
}
