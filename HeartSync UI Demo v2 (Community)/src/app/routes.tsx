import { createBrowserRouter } from "react-router";
import { Home } from "./components/Home";
import { HeartAlarm } from "./components/HeartAlarm";
import { HeartMap } from "./components/HeartMap";
import { HeartSpace } from "./components/HeartSpace";
import { HeartChallenges } from "./components/HeartChallenges";
import { HeartStore } from "./components/HeartStore";
import { Account } from "./components/Account";
import { Layout } from "./components/Layout";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: Layout,
    children: [
      { index: true, Component: Home },
      { path: "alarm", Component: HeartAlarm },
      { path: "map", Component: HeartMap },
      { path: "space", Component: HeartSpace },
      { path: "challenges", Component: HeartChallenges },
      { path: "store", Component: HeartStore },
      { path: "account", Component: Account },
    ],
  },
]);
