export default function LoginPage() {
return ( <section className="min-h-screen flex items-center justify-center bg-gray-50"> <div className="bg-white p-10 rounded-xl shadow-md w-full max-w-md">

    <h1 className="text-2xl font-semibold mb-6 text-center">
      Floraprise Login
    </h1>

    <input
      type="email"
      placeholder="Email"
      className="w-full border rounded-lg px-4 py-3 mb-4"
    />

    <input
      type="password"
      placeholder="Password"
      className="w-full border rounded-lg px-4 py-3 mb-6"
    />

    <button className="w-full bg-green-700 text-white py-3 rounded-lg hover:bg-green-800">
      Login
    </button>

    <p className="text-sm text-gray-500 text-center mt-4">
      Access your Floraprise dashboard
    </p>

  </div>
</section>

);
}
