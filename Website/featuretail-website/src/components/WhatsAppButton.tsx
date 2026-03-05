"use client";

export default function WhatsAppButton() {
  const phoneNumber = "919810392755"; // Replace with your real number

  return (
    <a
      href={`https://wa.me/${phoneNumber}`}
      target="_blank"
      rel="noopener noreferrer"
      className="fixed bottom-5 right-5 bg-green-500 hover:bg-green-600 text-white px-4 py-3 rounded-full shadow-lg flex items-center space-x-2 z-50"
    >
      <span>💬</span>
      <span className="hidden md:inline">Chat with us</span>
    </a>
  );
}
