import { verifyToken } from '../login.js';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, X-Auth-Token',
  'Content-Type': 'application/json; charset=utf-8',
};

export async function onRequestDelete({ request, env, params }) {
  const token = request.headers.get('x-auth-token');
  if (!await verifyToken(token, env)) {
    return new Response(JSON.stringify({ error: '未授权' }), { status: 401, headers: corsHeaders });
  }

  const id = params.id;
  try {
    await env.DB.prepare('DELETE FROM submissions WHERE id = ?').bind(id).run();
    const count = await env.DB.prepare('SELECT COUNT(*) as total FROM submissions').first();
    return new Response(JSON.stringify({ success: true, total: count.total }), { headers: corsHeaders });
  } catch (e) {
    return new Response(JSON.stringify({ error: 'Database error: ' + e.message }), { status: 500, headers: corsHeaders });
  }
}

export async function onRequestOptions() {
  return new Response(null, { headers: corsHeaders });
}
