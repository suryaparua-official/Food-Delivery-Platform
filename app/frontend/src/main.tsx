import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./App.tsx";
import { GoogleOAuthProvider } from "@react-oauth/google";
import { AppProvider } from "./context/AppContext.tsx";
import "leaflet/dist/leaflet.css";
import { SocketProvider } from "./context/SocketContext.tsx";

// export const authService = "https://food-auth-1.onrender.com";
// export const restaurantService = "https://food-restaurant-m6cq.onrender.com";
// export const utilsService = "https://food-utils.onrender.com";
// export const realtimeService = "https://food-realtime.onrender.com";
// export const riderService = "https://food-rider.onrender.com";
// export const adminService = "https://food-admin-ojdy.onrender.com";

export const BASE_URL = "http://localhost:8081";
export const authService = BASE_URL;
export const restaurantService = BASE_URL;
export const utilsService = BASE_URL;
export const realtimeService = BASE_URL;
export const riderService = BASE_URL;
export const adminService = BASE_URL;

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <GoogleOAuthProvider clientId="338720985371-hklqld665timg58ftqk1ke6j0fchudf5.apps.googleusercontent.com">
      <AppProvider>
        <SocketProvider>
          <App />
        </SocketProvider>
      </AppProvider>
    </GoogleOAuthProvider>
  </StrictMode>,
);
