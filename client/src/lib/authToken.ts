const STORAGE_KEY = "vast-optimizer-token";

export function getOptimizerToken(): string {
  if (typeof window === "undefined") {
    return "";
  }
  return window.localStorage.getItem(STORAGE_KEY) ?? "";
}

export function setOptimizerToken(token: string): void {
  if (typeof window === "undefined") {
    return;
  }
  if (token.trim().length === 0) {
    window.localStorage.removeItem(STORAGE_KEY);
    return;
  }
  window.localStorage.setItem(STORAGE_KEY, token.trim());
}

export function authHeaders(): HeadersInit {
  const token = getOptimizerToken();
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  return headers;
}
