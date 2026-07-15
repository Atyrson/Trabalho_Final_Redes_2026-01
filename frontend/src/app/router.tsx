import { createBrowserRouter, Navigate } from "react-router-dom";
import { AdminRoute } from "../auth/AdminRoute";
import { ProtectedRoute } from "../auth/ProtectedRoute";
import { AppShell } from "../components/AppShell";
import { AdminPage } from "../pages/AdminPage";
import { AuthCallbackPage } from "../pages/AuthCallbackPage";
import { ChannelPage } from "../pages/ChannelPage";
import { ChannelsPage } from "../pages/ChannelsPage";
import { LoginPage } from "../pages/LoginPage";
import { NotFoundPage } from "../pages/NotFoundPage";

export const router = createBrowserRouter([
  { path: "/login", element: <LoginPage /> },
  { path: "/auth/callback", element: <AuthCallbackPage /> },
  {
    element: <ProtectedRoute />,
    children: [
      {
        element: <AppShell />,
        children: [
          { index: true, element: <Navigate to="/canais" replace /> },
          { path: "/canais", element: <ChannelsPage /> },
          { path: "/canais/:channelId", element: <ChannelPage /> },
          {
            element: <AdminRoute />,
            children: [{ path: "/admin", element: <AdminPage /> }],
          },
        ],
      },
    ],
  },
  { path: "*", element: <NotFoundPage /> },
]);
