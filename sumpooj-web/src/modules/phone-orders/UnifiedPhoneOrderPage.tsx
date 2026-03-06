import React, { useState } from "react";

const UnifiedPhoneOrderPage: React.FC = () => {
  const [orderDescription, setOrderDescription] = useState("");
  const [amount, setAmount] = useState<number | "">("");
  const [phone, setPhone] = useState("");
  const [customerName, setCustomerName] = useState("");
  const [lastOrders, setLastOrders] = useState<any[]>([]);
  const [deliveryCharge, setDeliveryCharge] = useState<number | "">("");
  const [paid, setPaid] = useState(0);
  const [orderType, setOrderType] = useState<string>("delivery");
  const [timeSlot, setTimeSlot] = useState<string>("");

  const repeatOrder = (order: any) => {
    setOrderDescription(order.description);
    setAmount(order.amount);
  };

  const lookupCustomer = async (phoneNumber: string) => {
    if (phoneNumber.length < 8) return;
    const res = await fetch(`/api/customers/by-phone?phone=${phoneNumber}`);
    const data = await res.json();
    if (data) {
      setCustomerName(data.name);
      setLastOrders(data.orders || []);
    } else {
      setLastOrders([]);
    }
  };

  const total = (amount || 0) + (deliveryCharge || 0);
  const balance = total - paid;

  return (
    <div className="p-6 grid grid-cols-12 gap-6">
      {/* LEFT SIDE */}
      <div className="col-span-8 bg-white rounded-xl shadow p-6 space-y-6">
        {/* ORDER TYPE */}
        <div>
          <h2 className="font-semibold mb-3">Order Type</h2>
          <div className="flex gap-3">
            <button
              onClick={() => setOrderType("pickup")}
              className={`px-5 py-2 rounded-lg border ${
                orderType === "pickup"
                  ? "bg-gray-700 text-white"
                  : "bg-gray-100"
              }`}
            >
              🏬 Pickup
            </button>
            <button
              onClick={() => setOrderType("delivery")}
              className={`px-5 py-2 rounded-lg border ${
                orderType === "delivery"
                  ? "bg-purple-600 text-white"
                  : "bg-gray-100"
              }`}
            >
              🚚 Local Delivery
            </button>
            <button
              onClick={() => setOrderType("outstation")}
              className={`px-5 py-2 rounded-lg border ${
                orderType === "outstation"
                  ? "bg-orange-500 text-white"
                  : "bg-gray-100"
              }`}
            >
              🌎 Outstation
            </button>
          </div>
        </div>
        {/* CUSTOMER */}
        <div className="grid grid-cols-2 gap-4">
          <input
            placeholder="Customer Phone"
            value={phone}
            onChange={(e) => {
              const value = e.target.value;
              setPhone(value);
              lookupCustomer(value);
            }}
            className="border rounded-lg p-3"
          />
          <input
            placeholder="Customer Name"
            value={customerName}
            onChange={(e) => setCustomerName(e.target.value)}
            className="border rounded-lg p-3"
          />
        </div>

        {lastOrders.length > 0 && (
          <div className="bg-gray-50 border rounded-lg p-3 mt-3">
            <div className="text-sm font-semibold mb-2">
              Last Orders
            </div>
            {lastOrders.map((order: any) => (
              <div
                key={order.id}
                className="flex justify-between items-center text-sm py-2 border-b last:border-0"
              >
                <div>
                  <div>{order.description}</div>
                  <div className="text-gray-500 text-xs">₹{order.amount}</div>
                </div>
                <button
                  onClick={() => repeatOrder(order)}
                  className="px-3 py-1 bg-purple-600 text-white rounded text-xs"
                >
                  Repeat
                </button>
              </div>
            ))}
          </div>
        )}
        {/* DELIVERY DETAILS */}
        {orderType !== "pickup" && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <input
                placeholder="Recipient Name"
                className="border rounded-lg p-3"
              />
              <input
                placeholder="Recipient Phone"
                className="border rounded-lg p-3"
              />
            </div>
            <input
              placeholder="Delivery Address"
              className="border rounded-lg p-3 w-full"
            />
            <div className="grid grid-cols-3 gap-4">
              <input placeholder="City" className="border rounded-lg p-3" />
              <input placeholder="State" className="border rounded-lg p-3" />
              <input placeholder="ZIP Code" className="border rounded-lg p-3" />
            </div>
            <div className="flex gap-2 mt-2">
              <button
                onClick={() => setDeliveryCharge(50)}
                className="px-3 py-1 bg-gray-200 rounded"
              >
                ₹50
              </button>
              <button
                onClick={() => setDeliveryCharge(100)}
                className="px-3 py-1 bg-gray-200 rounded"
              >
                ₹100
              </button>
              <button
                onClick={() => setDeliveryCharge(150)}
                className="px-3 py-1 bg-gray-200 rounded"
              >
                ₹150
              </button>
            </div>
          </div>
        )}
        {/* DELIVERY DATE */}
        <div className="grid grid-cols-2 gap-4">
          <input type="date" className="border rounded-lg p-3" />
          <select
            value={timeSlot}
            onChange={(e) => setTimeSlot(e.target.value)}
            className="border rounded-lg p-3"
          >
            <option value="">Delivery Time Slot</option>
            <option value="morning">🌅 Morning (9–12)</option>
            <option value="afternoon">☀️ Afternoon (12–3)</option>
            <option value="evening">🌇 Evening (3–6)</option>
            <option value="night">🌙 Night (6–9)</option>
          </select>
        </div>

        {timeSlot && (
          <div className="mt-2">
            <span className="inline-block px-4 py-2 rounded-full bg-purple-100 text-purple-700 font-semibold text-sm">
              Delivery Slot: {(() => {
                switch (timeSlot) {
                  case "morning": return "🌅 Morning (9–12)";
                  case "afternoon": return "☀️ Afternoon (12–3)";
                  case "evening": return "🌇 Evening (3–6 PM)";
                  case "night": return "🌙 Night (6–9)";
                  default: return "";
                }
              })()}
            </span>
          </div>
        )}
        {/* CARD MESSAGE */}
        <textarea
          placeholder="Card Message"
          className="border rounded-lg p-3 w-full"
        />
        {/* PRODUCT */}
        <input
          placeholder="What did the customer order?"
          value={orderDescription}
          onChange={(e) => setOrderDescription(e.target.value)}
          className="border rounded-lg p-3 w-full"
        />
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="text-sm text-gray-600">Order Amount</label>
            <input
              type="number"
              placeholder="Order Amount"
              value={amount}
              onChange={(e) => setAmount(e.target.value === "" ? "" : Number(e.target.value))}
              className="border rounded-lg p-3 w-full"
            />
          </div>
          <div>
            <label className="text-sm text-gray-600">Delivery Charge</label>
            <input
              type="number"
              placeholder="Delivery Charge"
              value={deliveryCharge}
              onChange={(e) => setDeliveryCharge(e.target.value === "" ? "" : Number(e.target.value))}
              className="border rounded-lg p-3 w-full"
            />
          </div>
        </div>
        <div className="flex gap-2 mt-2">
          <button onClick={() => setDeliveryCharge(50)} className="px-3 py-1 bg-gray-200 rounded">₹50</button>
          <button onClick={() => setDeliveryCharge(100)} className="px-3 py-1 bg-gray-200 rounded">₹100</button>
          <button onClick={() => setDeliveryCharge(150)} className="px-3 py-1 bg-gray-200 rounded">₹150</button>
        </div>
      </div>
      {/* RIGHT SIDE */}
      <div className="col-span-4 bg-white rounded-xl shadow p-6">
        <h2 className="font-semibold mb-4">Order Summary</h2>
        <div className="space-y-4">
          <div className="flex justify-between text-gray-600">
            <span>Order Amount</span>
            <span className="font-medium">₹{amount}</span>
          </div>
          <div className="flex justify-between text-gray-600">
            <span>Delivery Charge</span>
            <span className="font-medium">₹{deliveryCharge}</span>
          </div>
          <div className="border-t pt-3 flex justify-between text-xl font-bold text-purple-700">
            <span>Total</span>
            <span>₹{total}</span>
          </div>
        </div>
        {/* PAYMENT BUTTONS */}
        <div className="mt-6 space-y-3">
          <button
            onClick={() => setPaid(total)}
            className="w-full py-3 rounded-lg bg-green-500 text-white text-lg"
          >
            💵 Cash
          </button>
          <button
            onClick={() => setPaid(total)}
            className="w-full py-3 rounded-lg bg-blue-500 text-white text-lg"
          >
            💳 Card
          </button>
          <button
            className="w-full py-3 rounded-lg bg-orange-400 text-white text-lg"
          >
            🔀 Split Payment
          </button>
        </div>
        {/* PAYMENT INFO */}
        <div className="mt-6 text-sm space-y-1">
          <div className="flex justify-between">
            <span>Paid</span>
            <span>₹{paid}</span>
          </div>
          <div className="flex justify-between">
            <span>Balance</span>
            <span>₹{balance}</span>
          </div>
        </div>
        {/* CHECKOUT */}
        <button
          className="mt-6 w-full py-4 rounded-xl bg-purple-600 text-white text-lg"
        >
          Complete Order ₹{total}
        </button>
      </div>
    </div>
  );
};

export default UnifiedPhoneOrderPage;