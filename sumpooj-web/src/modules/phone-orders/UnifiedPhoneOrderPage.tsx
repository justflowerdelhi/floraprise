import React, { useState } from "react";
import { confirmPhoneLocalOrder, createPhoneOrder } from "./phoneOrders.api";
import { createPayment } from "./phoneOrders.api";
import api from '../../api/axios';
import { formatCurrency } from '../../core/i18n';

const UnifiedPhoneOrderPage: React.FC = () => {
  const [savedOrderId, setSavedOrderId] = useState<string | null>(null);
  const [deliveryDate, setDeliveryDate] = useState<string>(new Date().toISOString().split('T')[0]);
  const [deliveryCity, setDeliveryCity] = useState<string>("");

  const ensureOrderCreated = async (): Promise<string> => {
    if (savedOrderId) return savedOrderId;

    // Build items from the order amount
    const items: { description: string; quantity: number; unitPrice: number }[] = [];
    if (typeof amount === 'number' && amount > 0) {
      items.push({
        description: orderDescription || 'Phone Order',
        quantity: 1,
        unitPrice: amount,
      });
    }

    const created = await createPhoneOrder({
      customerName: customerName || undefined,
      phoneNumber: phone || undefined,
      orderType: orderType === 'outstation' ? 'PhoneOutstation' : 'PhoneLocal',
      deliveryDate: deliveryDate || new Date().toISOString(),
      deliveryCity: deliveryCity || 'Unknown',
      deliveryAddress: deliveryAddress || undefined,
      deliveryPincode: zipCode || undefined,
      timeSlot: timeSlot ? normalizeTimeSlot(timeSlot) : undefined,
      budget: typeof amount === 'number' ? amount : undefined,
      specialInstructions: orderDescription || undefined,
      deliveryCharge: typeof deliveryCharge === 'number' ? deliveryCharge : 0,
      items,
    });

    setSavedOrderId(created.id);
    return created.id;
  };

  const safeCreatePayment = async (payload: { amount: number; paymentMode: 'Cash' | 'UPI' | 'Card' | 'BankTransfer' }) => {
    try {
      const orderId = await ensureOrderCreated();
      await createPayment({ ...payload, orderId });
    } catch (err: any) {
      const msg = err?.response?.data?.message || err?.message || 'Unable to create payment.';
      alert(msg);
    }
  };
    // Advance payment modal state
    const [showAdvancePrompt, setShowAdvancePrompt] = useState(false);
    const [advanceAmount, setAdvanceAmount] = useState(0);
    // Full payment modal state
    const [showFullPrompt, setShowFullPrompt] = useState(false);
  const [orderDescription, setOrderDescription] = useState("");
  const [amount, setAmount] = useState<number | "">("");
  const [phone, setPhone] = useState("");
  const [customerName, setCustomerName] = useState("");
  const [lastOrders, setLastOrders] = useState<any[]>([]);
  const [deliveryCharge, setDeliveryCharge] = useState<number | "">("");
  const [paid, setPaid] = useState(0);
  const [orderType, setOrderType] = useState<string>("delivery");
  const [timeSlot, setTimeSlot] = useState<string>("");
  const [recipientName, setRecipientName] = useState("");
  const [recipientPhone, setRecipientPhone] = useState("");
  const [deliveryAddress, setDeliveryAddress] = useState("");
  const [zipCode, setZipCode] = useState("");
  const [paymentMode, setPaymentMode] = useState<'Cash' | 'UPI' | 'Card' | 'BankTransfer'>("Cash");
  const paymentModes: Array<'Cash' | 'UPI' | 'Card' | 'BankTransfer'> = ["Cash", "Card", "UPI", "BankTransfer"];
  const [splitPayments, setSplitPayments] = useState<{mode: 'Cash' | 'UPI' | 'Card' | 'BankTransfer', amount: number}[]>([]);
  const [showSplitPrompt, setShowSplitPrompt] = useState(false);

  const normalizeTimeSlot = (slot: string): string => {
    switch (slot) {
      case 'morning': return '9AM-12PM';
      case 'afternoon': return '12PM-3PM';
      case 'evening': return '3PM-6PM';
      case 'night': return '6PM-9PM';
      default: return slot;
    }
  };

  const repeatOrder = (order: any) => {
    setOrderDescription(order.description);
    setAmount(order.amount);
  };

  const lookupCustomer = async (phoneNumber: string) => {
    if (phoneNumber.length < 8) return;
    const res = await api.get('/customers/by-phone', { params: { phone: phoneNumber } });
    const data = res.data;
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
    <div className="p-3 sm:p-6 flex flex-col lg:grid lg:grid-cols-12 gap-4 lg:gap-6">
      {/* LEFT SIDE — Order Form */}
      <div className="lg:col-span-8 bg-white rounded-xl shadow p-4 sm:p-6 space-y-4 sm:space-y-6">
        {/* ORDER TYPE */}
        <div>
          <h2 className="font-semibold mb-3">Order Type</h2>
          <div className="flex flex-wrap gap-2 sm:gap-3">
            <button
              onClick={() => setOrderType("pickup")}
              className={`px-4 py-2 rounded-lg border text-sm sm:text-base ${
                orderType === "pickup"
                  ? "bg-gray-700 text-white"
                  : "bg-gray-100"
              }`}
            >
              🏬 Pickup
            </button>
            <button
              onClick={() => setOrderType("delivery")}
              className={`px-4 py-2 rounded-lg border text-sm sm:text-base ${
                orderType === "delivery"
                  ? "bg-purple-600 text-white"
                  : "bg-gray-100"
              }`}
            >
              🚚 Local Delivery
            </button>
            <button
              onClick={() => setOrderType("outstation")}
              className={`px-4 py-2 rounded-lg border text-sm sm:text-base ${
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
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4">
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
                  <div className="text-gray-500 text-xs">{formatCurrency(Number(order.amount ?? 0))}</div>
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
          <div className="space-y-3 sm:space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4">
              <input
                placeholder="Recipient Name"
                className="border rounded-lg p-3"
                value={recipientName}
                onChange={(e) => setRecipientName(e.target.value)}
              />
              <input
                placeholder="Recipient Phone"
                className="border rounded-lg p-3"
                value={recipientPhone}
                onChange={(e) => setRecipientPhone(e.target.value)}
              />
            </div>
            <input
              placeholder="Delivery Address"
              className="border rounded-lg p-3 w-full"
              value={deliveryAddress}
              onChange={(e) => setDeliveryAddress(e.target.value)}
            />
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 sm:gap-4">
              <input placeholder="City" className="border rounded-lg p-3" value={deliveryCity} onChange={(e) => setDeliveryCity(e.target.value)} />
              <input placeholder="State" className="border rounded-lg p-3" />
              <input placeholder="ZIP Code *" className="border rounded-lg p-3" value={zipCode} onChange={(e) => setZipCode(e.target.value)} />
            </div>
            <div className="flex flex-wrap gap-2 mt-2">
              <button onClick={() => setDeliveryCharge(50)} className="px-3 py-1 bg-gray-200 rounded text-sm">{formatCurrency(50)}</button>
              <button onClick={() => setDeliveryCharge(100)} className="px-3 py-1 bg-gray-200 rounded text-sm">{formatCurrency(100)}</button>
              <button onClick={() => setDeliveryCharge(150)} className="px-3 py-1 bg-gray-200 rounded text-sm">{formatCurrency(150)}</button>
            </div>
          </div>
        )}
        {/* DELIVERY DATE */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4">
          <input type="date" className="border rounded-lg p-3" value={deliveryDate} onChange={(e) => setDeliveryDate(e.target.value)} />
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
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4">
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
        <div className="flex flex-wrap gap-2 mt-2">
          <button onClick={() => setDeliveryCharge(50)} className="px-3 py-1 bg-gray-200 rounded text-sm">{formatCurrency(50)}</button>
          <button onClick={() => setDeliveryCharge(100)} className="px-3 py-1 bg-gray-200 rounded text-sm">{formatCurrency(100)}</button>
          <button onClick={() => setDeliveryCharge(150)} className="px-3 py-1 bg-gray-200 rounded text-sm">{formatCurrency(150)}</button>
        </div>
      </div>
      {/* RIGHT SIDE — Summary & Payment */}
      <div className="lg:col-span-4 bg-white rounded-xl shadow p-4 sm:p-6">
        <h2 className="font-semibold mb-4">Order Summary</h2>
        <div className="space-y-4">
          <div className="flex justify-between text-gray-600">
            <span>Order Amount</span>
            <span className="font-medium">{formatCurrency(Number(amount || 0))}</span>
          </div>
          <div className="flex justify-between text-gray-600">
            <span>Delivery Charge</span>
            <span className="font-medium">{formatCurrency(Number(deliveryCharge || 0))}</span>
          </div>
          <div className="border-t pt-3 flex justify-between text-xl font-bold text-purple-700">
            <span>Total</span>
            <span>{formatCurrency(total)}</span>
          </div>
        </div>
        {/* PAYMENT BUTTONS */}
        <div className="mt-6 space-y-3">
          <button
            onClick={() => setShowAdvancePrompt(true)}
            className="w-full py-3 rounded-lg bg-yellow-500 text-white text-lg"
          >
            🏦 Advance Payment
          </button>
          <button
            onClick={() => setShowFullPrompt(true)}
            className="w-full py-3 rounded-lg bg-green-500 text-white text-lg"
          >
            💵 Full Payment
          </button>
          <button
            onClick={() => setShowSplitPrompt(true)}
            className="w-full py-3 rounded-lg bg-orange-400 text-white text-lg"
          >
            🔀 Split Payment
          </button>
        </div>
        {/* Advance Payment Prompt */}
        {showAdvancePrompt && (
          <div className="mt-4 p-4 bg-white border rounded-lg">
            <div className="mb-2 font-semibold">Advance Payment</div>
            <div className="space-y-2">
              <input
                type="number"
                placeholder="Advance Amount"
                className="border rounded p-2 w-full"
                value={advanceAmount}
                onChange={e => setAdvanceAmount(Number(e.target.value))}
              />
              <select
                className="border rounded p-2 w-full"
                value={paymentMode}
                onChange={e => setPaymentMode(e.target.value as 'Cash' | 'UPI' | 'Card' | 'BankTransfer')}
              >
                {paymentModes.map(mode => (
                  <option key={mode} value={mode}>{mode}</option>
                ))}
              </select>
              <button
                className="mt-2 w-full py-2 rounded bg-yellow-500 text-white"
                onClick={async () => {
                  setPaid(advanceAmount);
                  setShowAdvancePrompt(false);
                  await safeCreatePayment({
                    amount: advanceAmount,
                    paymentMode
                  });
                }}
              >
                Confirm Advance Payment
              </button>
              <button
                className="mt-2 w-full py-2 rounded bg-gray-300 text-black"
                onClick={() => setShowAdvancePrompt(false)}
              >
                Cancel
              </button>
            </div>
          </div>
        )}
        {/* Full Payment Prompt */}
        {showFullPrompt && (
          <div className="mt-4 p-4 bg-white border rounded-lg">
            <div className="mb-2 font-semibold">Full Payment</div>
            <div className="space-y-2">
              <input
                type="number"
                placeholder="Full Payment Amount"
                className="border rounded p-2 w-full"
                value={total}
                readOnly
              />
              <select
                className="border rounded p-2 w-full"
                value={paymentMode}
                onChange={e => setPaymentMode(e.target.value as 'Cash' | 'UPI' | 'Card' | 'BankTransfer')}
              >
                {paymentModes.map(mode => (
                  <option key={mode} value={mode}>{mode}</option>
                ))}
              </select>
              <button
                className="mt-2 w-full py-2 rounded bg-green-500 text-white"
                onClick={async () => {
                  setPaid(total);
                  setShowFullPrompt(false);
                  await safeCreatePayment({
                    amount: total,
                    paymentMode
                  });
                }}
              >
                Confirm Full Payment
              </button>
              <button
                className="mt-2 w-full py-2 rounded bg-gray-300 text-black"
                onClick={() => setShowFullPrompt(false)}
              >
                Cancel
              </button>
            </div>
          </div>
        )}
        {/* Split Payment Prompt */}
        {showSplitPrompt && (
          <div className="mt-4 p-4 bg-white border rounded-lg">
            <div className="mb-2 font-semibold">Split Payment</div>
            <div className="space-y-2">
              <div className="flex flex-col sm:flex-row gap-2">
                <input
                  type="number"
                  placeholder="Amount 1"
                  className="border rounded p-2 w-full"
                  onChange={e => {
                    const val = Number(e.target.value);
                    setSplitPayments(payments => [{...payments[0], amount: val, mode: payments[0]?.mode || "Cash"}, payments[1] || {mode: "Card", amount: 0}]);
                  }}
                />
                <select
                  className="border rounded p-2 w-full sm:w-auto"
                  value={splitPayments[0]?.mode || "Cash"}
                  onChange={e => {
                    setSplitPayments(payments => [{...payments[0], mode: e.target.value as 'Cash' | 'UPI' | 'Card' | 'BankTransfer', amount: payments[0]?.amount || 0}, payments[1] || {mode: "Card", amount: 0}]);
                  }}
                >
                  {paymentModes.map(mode => (
                    <option key={mode} value={mode}>{mode}</option>
                  ))}
                </select>
              </div>
              <div className="flex flex-col sm:flex-row gap-2">
                <input
                  type="number"
                  placeholder="Amount 2"
                  className="border rounded p-2 w-full"
                  onChange={e => {
                    const val = Number(e.target.value);
                    setSplitPayments(payments => [payments[0] || {mode: "Cash", amount: 0}, {...payments[1], amount: val, mode: payments[1]?.mode || "Card"}]);
                  }}
                />
                <select
                  className="border rounded p-2 w-full sm:w-auto"
                  value={splitPayments[1]?.mode || "Card"}
                  onChange={e => {
                    setSplitPayments(payments => [payments[0] || {mode: "Cash", amount: 0}, {...payments[1], mode: e.target.value as 'Cash' | 'UPI' | 'Card' | 'BankTransfer', amount: payments[1]?.amount || 0}]);
                  }}
                >
                  {paymentModes.map(mode => (
                    <option key={mode} value={mode}>{mode}</option>
                  ))}
                </select>
              </div>
              <button
                className="mt-2 w-full py-2 rounded bg-purple-600 text-white"
                onClick={async () => {
                  const totalPaid = (splitPayments[0]?.amount || 0) + (splitPayments[1]?.amount || 0);
                  setPaid(totalPaid);
                  setShowSplitPrompt(false);
                  // Send both payments to backend
                  if (splitPayments[0]?.amount) {
                    await safeCreatePayment({
                      amount: splitPayments[0].amount,
                      paymentMode: splitPayments[0].mode
                    });
                  }
                  if (splitPayments[1]?.amount) {
                    await safeCreatePayment({
                      amount: splitPayments[1].amount,
                      paymentMode: splitPayments[1].mode
                    });
                  }
                }}
              >
                Confirm Split Payment
              </button>
              <button
                className="mt-2 w-full py-2 rounded bg-gray-300 text-black"
                onClick={() => setShowSplitPrompt(false)}
              >
                Cancel
              </button>
            </div>
          </div>
        )}
        {/* PAYMENT INFO */}
        <div className="mt-6 text-sm space-y-1">
          <div className="flex justify-between">
            <span>Paid</span>
            <span>{formatCurrency(paid)}</span>
          </div>
          <div className="flex justify-between">
            <span>Balance</span>
            <span>{formatCurrency(balance)}</span>
          </div>
        </div>
        {/* CHECKOUT */}
        <button
          className="mt-6 w-full py-4 rounded-xl bg-purple-600 text-white text-lg"
          disabled={balance > 0}
          onClick={async () => {
            if (balance > 0) {
              alert("Please complete payment before finishing the order.");
              return;
            }
            try {
              const orderId = await ensureOrderCreated();
              await confirmPhoneLocalOrder(orderId);
              alert("Order completed successfully!");
              // Optionally reset form or redirect
            } catch (err: any) {
              const msg = err?.response?.data?.message || "Order completion failed. Please try again.";
              alert(msg);
            }
          }}
        >
          Complete Order {formatCurrency(total)}
        </button>
      </div>
    </div>
  );
};

export default UnifiedPhoneOrderPage;