import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  try {
    const { calApiKey } = await req.json();
    if (!calApiKey) throw new Error("calApiKey obrigatório");

    // Cal.com v2 API — chaves cal_live_ / cal_test_
    const res = await fetch(
      "https://api.cal.com/v2/bookings?status=upcoming&take=100",
      {
        headers: {
          "Authorization": `Bearer ${calApiKey}`,
          "cal-api-version": "2024-08-13",
          "Content-Type": "application/json",
        },
      }
    );

    const raw = await res.text();
    if (!res.ok) throw new Error(`Cal.com ${res.status}: ${raw}`);

    const data = JSON.parse(raw);
    // v2 retorna { status: "success", data: { bookings: [...] } }
    const bookings = data?.data?.bookings || data?.data || [];

    return new Response(JSON.stringify({ bookings }), {
      headers: { ...CORS, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...CORS, "Content-Type": "application/json" },
    });
  }
});
