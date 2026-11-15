/** Exact server credential validation; never trust a decoded role claim alone. */
export async function serverOnly(
  req: Request,
  serviceKey: string | undefined,
  handler: () => Promise<Response>,
): Promise<Response> {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405, headers: { Allow: 'POST' } });
  }
  if (!serviceKey) return new Response('Server configuration unavailable', { status: 503 });
  const token = req.headers.get('authorization')?.match(/^Bearer ([^\s]+)$/i)?.[1];
  if (!token) return new Response('Unauthorized', { status: 401 });
  const encode = new TextEncoder();
  const [actual, expected] = await Promise.all([
    crypto.subtle.digest('SHA-256', encode.encode(token)),
    crypto.subtle.digest('SHA-256', encode.encode(serviceKey)),
  ]);
  const a = new Uint8Array(actual), b = new Uint8Array(expected);
  let difference = 0;
  for (let i = 0; i < a.length; i++) difference |= a[i] ^ b[i];
  if (difference !== 0) return new Response('Unauthorized', { status: 401 });
  return handler();
}
