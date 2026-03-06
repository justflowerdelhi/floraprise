import Footer from "@/components/Footer";

async function getProducts() {
  const res = await fetch("http://localhost:3000/api/products", {
    cache: "no-store",
  });

  return res.json();
}

export default async function ShopPage() {
  const products = await getProducts();

  return (
    <>
      <section className="max-w-7xl mx-auto px-4 py-8">

        <h1 className="text-3xl font-bold mb-8">
          Shop Craft Supplies
        </h1>

        {products.length === 0 ? (
          <div className="text-center py-20 text-gray-500">
            Products coming soon.
          </div>
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
            {products.map((p:any) => (
              <div key={p.id} className="border rounded-lg p-4">
                <div className="aspect-square bg-gray-100 rounded mb-3"></div>

                <h3 className="text-sm font-medium">{p.name}</h3>

                <p className="text-pink-600 font-semibold">
                  ₹{p.price}
                </p>

                <button className="mt-3 w-full bg-pink-600 text-white py-2 rounded">
                  Add to Cart
                </button>
              </div>
            ))}
          </div>
        )}

      </section>

      <Footer />
    </>
  );
}