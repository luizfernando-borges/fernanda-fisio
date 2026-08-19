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

    // Busca upcoming + accepted bookings
    const res = await fetch(
      `https://api.cal.com/v1/bookings?apiKey=${calApiKey}&status=upcoming&take=100`
    );
    if (!res.ok) {
      const err = await res.text();
      throw new Error(`Cal.com ${res.status}: ${err}`);
    }
    const data = await res.json();

    return new Response(JSON.stringify(data), {
      headers: { ...CORS, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { ...CORS, "Content-Type": "application/json" },
    });
  }
});
