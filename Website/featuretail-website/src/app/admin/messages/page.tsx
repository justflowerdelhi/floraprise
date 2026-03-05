"use client"

import { useEffect,useState } from "react"

export default function AdminMessages(){

  const [messages, setMessages] = useState<any[]>([]);

  useEffect(() => {
    fetch("/api/admin/messages")
      .then((res) => res.json())
      .then((data) => setMessages(data));
  }, []);

  const deleteMessage = async (id: number) => {
    if (!confirm("Delete this message?")) return;

    await fetch(`/api/admin/messages/${id}`, {
      method: "DELETE",
    });

    setMessages(messages.filter((m) => m.id !== id));
  };

  return (
    <div className="max-w-5xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Contact Messages</h1>
      <table className="w-full border">
        <thead>
          <tr className="bg-gray-100">
            <th className="p-2 border">Name</th>
            <th className="p-2 border">Email</th>
            <th className="p-2 border">Subject</th>
            <th className="p-2 border">Message</th>
            <th className="p-2 border">Action</th>
          </tr>
        </thead>
        <tbody>
          {messages.map((msg: any) => (
            <tr key={msg.id}>
              <td className="border p-2">{msg.name}</td>
              <td className="border p-2">{msg.email}</td>
              <td className="border p-2">{msg.subject}</td>
              <td className="border p-2">{msg.message}</td>
              <td className="border p-2">
                <button
                  className="bg-red-500 text-white px-3 py-1 rounded"
                  onClick={() => deleteMessage(msg.id)}
                >
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}