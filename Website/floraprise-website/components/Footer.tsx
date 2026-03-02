export default function Footer() {
  return (
    <footer className="w-full border-t bg-white">
      <div className="max-w-7xl mx-auto px-6 py-4 text-sm text-gray-600">
        © {new Date().getFullYear()} Floraprise. All rights reserved.
      </div>
    </footer>
  );
}