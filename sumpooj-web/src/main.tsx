import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import { ThemeProvider } from "@mui/material/styles";
import CssBaseline from "@mui/material/CssBaseline";
import theme from "./theme";
import "./index.css";
import { syncOfflineSales } from "./utils/offlineSalesSync";
import { POSProvider } from "./pages/pos/POSContext";

import { BrowserRouter } from "react-router-dom";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <POSProvider>
      <BrowserRouter>
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <App />
        </ThemeProvider>
      </BrowserRouter>
    </POSProvider>
  </React.StrictMode>
);

window.addEventListener("online", () => {
  console.log("Internet restored — syncing offline sales");
  syncOfflineSales();
});
