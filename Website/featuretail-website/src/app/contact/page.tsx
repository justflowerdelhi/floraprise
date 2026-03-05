"use client"

import { useState } from "react"
import Footer from "@/components/Footer";

export default function ContactPage(){

  const [form,setForm] = useState({
    name:"",
    email:"",
    subject:"",
    message:""
  })

  const [success,setSuccess] = useState(false)

  const handleSubmit = async (e:any)=>{
    e.preventDefault()

    const res = await fetch("/api/contact",{
      method:"POST",
      headers:{
        "Content-Type":"application/json"
      },
      body:JSON.stringify(form)
    })

    if(res.ok){
      setSuccess(true)
      setForm({
        name:"",
        email:"",
        subject:"",
        message:""
      })
    }
  }

  return(
    <>
      <div className="max-w-6xl mx-auto px-6 py-12">

        <h1 className="text-3xl font-bold text-center mb-10">
          Contact Us
        </h1>

        <div className="grid md:grid-cols-2 gap-10">

          {/* Contact Form */}
          <div className="bg-white border p-6 rounded-lg">

            {success && (
              <p className="text-green-600 mb-4">
                Message sent successfully.
              </p>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">

              <input
                type="text"
                placeholder="Your Name"
                className="w-full border p-2 rounded"
                value={form.name}
                onChange={(e)=>setForm({...form,name:e.target.value})}
                required
              />

              <input
                type="email"
                placeholder="Email"
                className="w-full border p-2 rounded"
                value={form.email}
                onChange={(e)=>setForm({...form,email:e.target.value})}
                required
              />

              <input
                type="text"
                placeholder="Subject"
                className="w-full border p-2 rounded"
                value={form.subject}
                onChange={(e)=>setForm({...form,subject:e.target.value})}
              />

              <textarea
                placeholder="Message"
                rows={5}
                className="w-full border p-2 rounded"
                value={form.message}
                onChange={(e)=>setForm({...form,message:e.target.value})}
                required
              />

              <button className="bg-pink-600 text-white px-6 py-2 rounded">
                Send Message
              </button>

            </form>

          </div>

          {/* Contact Info */}
          <div className="space-y-6">

            <div className="bg-white border p-6 rounded-lg">
              <h2 className="text-xl font-semibold mb-3">
                Customer Support
              </h2>

              <p className="text-gray-600">
                Our team is happy to help with product queries,
                order support, or partnership opportunities.
              </p>
            </div>

            <div className="bg-white border p-6 rounded-lg">

              <h2 className="text-xl font-semibold mb-3">
                Contact Details
              </h2>

              <p className="mb-2">
                📧 Email: support@featuretail.com
              </p>

              <p className="mb-2">
                📞 Phone: +91 9810329755
              </p>

              <p>
                💬 WhatsApp: +91 9810329755
              </p>

            </div>

            <div className="bg-white border p-6 rounded-lg">

              <h2 className="text-xl font-semibold mb-3">
                Business Hours
              </h2>

              <p>
                Monday – Saturday
              </p>

              <p>
                10:00 AM – 6:00 PM
              </p>

            </div>

          </div>

        </div>

        {/* Google Map */}
        <div className="mt-14">
          <h2 className="text-2xl font-semibold text-center mb-6">
            Our Location
          </h2>
          <div className="w-full h-[400px] border rounded-lg overflow-hidden">
            <iframe
              src="https://maps.google.com/maps?q=3A%20Featuretail%2C%202%2F76%2C%20Old%20Rajinder%20Nagar%2C%20New%20Delhi%20110060&t=&z=16&ie=UTF8&iwloc=&output=embed"
              width="100%"
              height="100%"
              loading="lazy"
            />
          </div>
        </div>

        {/* FAQ */}
        <div className="mt-16 max-w-4xl mx-auto">
          <h2 className="text-2xl font-semibold text-center mb-8">
            Frequently Asked Questions
          </h2>
          <div className="space-y-4">
            <details className="bg-white border rounded p-4">
              <summary className="font-semibold cursor-pointer">
                How long does shipping take?
              </summary>
              <p className="mt-2 text-gray-600">
                Most orders are delivered within 3–5 working days across India.
              </p>
            </details>
            <details className="bg-white border rounded p-4">
              <summary className="font-semibold cursor-pointer">
                Do you offer bulk or corporate supply?
              </summary>
              <p className="mt-2 text-gray-600">
                Yes. We supply craft materials, decorations, and gift packaging
                to corporates, institutions, and event planners.
              </p>
            </details>
            <details className="bg-white border rounded p-4">
              <summary className="font-semibold cursor-pointer">
                Where can I buy your products?
              </summary>
              <p className="mt-2 text-gray-600">
                Our products are available on Amazon, Flipkart, Meesho,
                and directly on our website.
              </p>
            </details>
            <details className="bg-white border rounded p-4">
              <summary className="font-semibold cursor-pointer">
                Can I track my order?
              </summary>
              <p className="mt-2 text-gray-600">
                Yes. Once your order ships, you will receive tracking details
                via SMS or email.
              </p>
            </details>
          </div>
        </div>

      </div>
      <Footer />
    </>
  )
}