export async function onRequestPost({ request, env }) {
  const cors = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, X-Auth-Token',
    'Content-Type': 'application/json; charset=utf-8',
  };

  if (request.method === 'OPTIONS') {
    return new Response(null, { headers: cors });
  }

  let d;
  try {
    d = await request.json();
  } catch (e) {
    return new Response(JSON.stringify({ error: 'Invalid data' }), { status: 400, headers: cors });
  }

  const adminPassword = env.ADMIN_PASSWORD || 'matsumi2026';
  if (d.password !== adminPassword) {
    return new Response(JSON.stringify({ error: '密码错误' }), { status: 401, headers: cors });
  }

  const token = await generateToken(adminPassword, env);
  return new Response(JSON.stringify({ success: true, token }), { headers: cors });
}

export async function onRequestOptions() {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, X-Auth-Token',
    },
  });
}

export async function verifyToken(token, env) {
  if (!token) return false;
  const adminPassword = env.ADMIN_PASSWORD || 'matsumi2026';
  const expectedToken = await generateToken(adminPassword, env);
  return token === expectedToken;
}

async function generateToken(password, env) {
  const secret = env.ADMIN_SECRET || 'matsumi-rakuken-2026';
  const encoder = new TextEncoder();
  const data = encoder.encode(password + secret);
  const hash = await crypto.subtle.digest('SHA-256', data);
  return [...new Uint8Array(hash)].map(b => b.toString(16).padStart(2, '0')).join('');
}
