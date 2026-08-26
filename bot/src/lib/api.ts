/**
 * Thin wrapper over the PawZHub Web API. All requests go to the Vercel
 * deployment; admin-only endpoints send the bot's ADMIN_TOKEN.
 */

const WEB_API_URL = (process.env.WEB_API_URL || 'https://getpawzhub.vercel.app').replace(/\/$/, '');
const ADMIN_TOKEN = process.env.WEB_ADMIN_TOKEN || '';

type ApiResult<T> = { ok: true; data: T } | { ok: false; error: string; status: number };

async function call<T>(path: string, init: RequestInit = {}): Promise<ApiResult<T>> {
  const url = `${WEB_API_URL}${path}`;
  try {
    const res = await fetch(url, {
      ...init,
      headers: {
        'Content-Type': 'application/json',
        ...(init.headers || {}),
      },
    });
    const text = await res.text();
    let data: any = null;
    try { data = text ? JSON.parse(text) : null; } catch { data = text; }
    if (!res.ok) {
      return { ok: false, error: data?.error || `HTTP ${res.status}`, status: res.status };
    }
    return { ok: true, data: data as T };
  } catch (err: any) {
    return { ok: false, error: err?.message || 'Network error', status: 0 };
  }
}

async function callAdmin<T>(path: string, init: RequestInit = {}): Promise<ApiResult<T>> {
  return call<T>(path, {
    ...init,
    headers: {
      Authorization: `Bearer ${ADMIN_TOKEN}`,
      ...(init.headers || {}),
    },
  });
}

// ---- Public endpoints ----

export type VerifyResult = {
  valid: boolean;
  message?: string;
  tier?: string;
  type?: string;
  features?: string[];
  source?: string;
  hwid?: string | null;
  issued?: number;
  expires?: number | null;
  remainingHours?: number;
  expiry?: number | null;
};

export async function verifyKey(
  key: string,
  hwid?: string,
  userId?: string
): Promise<ApiResult<VerifyResult>> {
  return call<VerifyResult>('/api/verifykey', {
    method: 'POST',
    body: JSON.stringify({ key, hwid, userId }),
  });
}

// ---- Admin endpoints ----

export type AdminStats = {
  totalCheckpointTokens: number;
  usedCheckpointTokens: number;
  totalHWIDBindings: number;
  totalHWIDResets: number;
  blacklistedUsers: number;
  totalUsageLogs: number;
  backend?: string;
  recentActivity?: any[];
};

export async function getStats(): Promise<ApiResult<AdminStats>> {
  return callAdmin<AdminStats>('/api/admin?action=stats');
}

export type BlacklistedUser = {
  userId: string;
  reason: string;
  addedAt: number;
  addedBy: string;
};

export async function getBlacklist(): Promise<ApiResult<{ blacklist: BlacklistedUser[] }>> {
  return callAdmin<{ blacklist: BlacklistedUser[] }>('/api/admin?action=blacklist');
}

export async function addBlacklist(
  userId: string,
  reason: string,
  addedBy: string
): Promise<ApiResult<{ success: boolean; message: string }>> {
  return callAdmin('/api/admin?action=blacklist', {
    method: 'POST',
    body: JSON.stringify({ userId, reason, addedBy }),
  });
}

export async function removeBlacklist(
  userId: string
): Promise<ApiResult<{ success: boolean; message: string }>> {
  return callAdmin(
    `/api/admin?action=blacklist&userId=${encodeURIComponent(userId)}`,
    { method: 'DELETE' }
  );
}

export type GeneratedKey = {
  key: string;
  plan: string;
  userId: string;
  email?: string | null;
  roblox?: string | null;
  issued: number;
  expires: number;
  issuedDate: string;
  expiresDate: string;
};

export type GeneratedKeysResponse = {
  success: boolean;
  count: number;
  plan: string;
  keys: GeneratedKey[];
};

export async function generateKeys(
  plan: 'trial' | 'monthly' | 'lifetime',
  count: number,
  email?: string,
  roblox?: string
): Promise<ApiResult<GeneratedKeysResponse>> {
  return callAdmin<GeneratedKeysResponse>(
    '/api/admin?action=generate-key',
    {
      method: 'POST',
      body: JSON.stringify({ plan, count, email, roblox }),
    }
  );
}

export async function inspectKey(
  key: string
): Promise<ApiResult<any>> {
  return callAdmin('/api/admin?action=verify-key', {
    method: 'POST',
    body: JSON.stringify({ key }),
  });
}
