"use client";

import { useState } from "react";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const handleLogin = async (e?: any) => {
    if (e) e.preventDefault(); // ✅ STOP reload

    console.log("CLICKED LOGIN"); // 🔍 DEBUG

    const res = await fetch("/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });

    console.log("STATUS:", res.status);

    const data = await res.json();
    console.log("RESPONSE:", data);

    if (!res.ok) {
      alert("Login failed");
      return;
    }

    // ✅ DELAY (IMPORTANT for cookie)
    setTimeout(() => {
      window.location.href = "/admin/dashboard";
    }, 500);
  };

  return (
    <div className="min-h-screen flex items-center justify-center">
      <form
        onSubmit={handleLogin}
        className="p-6 border rounded w-80"
      >
        <h1 className="text-xl font-bold mb-4">Admin Login</h1>

        <input
          className="border p-2 w-full mb-3"
          placeholder="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />

        <input
          type="password"
          className="border p-2 w-full mb-3"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />

        <button
          type="submit"
          className="bg-black text-white w-full p-2"
        >
          Login
        </button>
      </form>
    </div>
  );
}