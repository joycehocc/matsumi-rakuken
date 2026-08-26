export async function onRequestPost({ request, env }) {
  const cors = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
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

  const name = String(d.name || '').slice(0, 100);
  const phone = String(d.phone || '').slice(0, 30);
  const email = String(d.email || '').slice(0, 200);
  const service = String(d.service || '').slice(0, 100);
  const message = String(d.message || '').slice(0, 2000);
  const time = new Date().toISOString();
  const ip = request.headers.get('cf-connecting-ip') || request.headers.get('x-forwarded-for') || 'unknown';

  try {
    const countStr = await env.DATA.get('count');
    const id = (parseInt(countStr) || 0) + 1;
    const entry = { id, name, phone, email, service, message, time, ip };
    await env.DATA.put('count', String(id));
    await env.DATA.put('submission_' + id, JSON.stringify(entry));
    return new Response(JSON.stringify({ success: true, id: String(id) }), { headers: cors });
  } catch (e) {
    return new Response(JSON.stringify({ error: 'Storage error: ' + e.message }), { status: 500, headers: cors });
  }
}

export async function onRequestOptions() {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}
