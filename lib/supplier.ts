// lib/supplier.ts
const CAMRAPID_BASE = process.env.CAMRAPID_BASE_URL || "https://partner.camrapidsecure.com/api";
const CAMRAPID_KEY  = process.env.CAMRAPID_API_KEY || "";

export interface TopupRequest {
  game: string;       // e.g. "freefire", "mlbb"
  uid: string;
  serverId?: string;
  productCode: string; // product code ពី CamRapid catalog
  orderRef: string;   // your order number
}

export interface TopupResult {
  success: boolean;
  transactionId?: string;
  status?: string;
  error?: string;
}

export async function sendTopup(req: TopupRequest): Promise<TopupResult> {
  if (!CAMRAPID_KEY) {
    console.warn("[camrapid] No API key — skipping auto topup");
    return { success: false, error: "No API key configured" };
  }

  try {
    const res = await fetch(`${CAMRAPID_BASE}/topup`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${CAMRAPID_KEY}`,
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: JSON.stringify({
        game: req.game,
        user_id: req.uid,
        zone_id: req.serverId,
        product_id: req.productCode,
        order_ref: req.orderRef,
      }),
    });

    const json = await res.json().catch(() => null);

    if (!res.ok || !json?.success) {
      return { success: false, error: json?.message || `HTTP ${res.status}` };
    }

    return {
      success: true,
      transactionId: json.data?.transaction_id,
      status: json.data?.status,
    };
  } catch (err) {
    return { success: false, error: String(err) };
  }
}