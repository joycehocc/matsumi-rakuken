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
    await env.DATA.delete('submission_' + id);
    const list = await env.DATA.list({ prefix: 'submission_' });
    return new Response(JSON.stringify({ success: true, total: list.keys.length }), { headers: corsHeaders });
  } catch (e) {
    return new Response(JSON.stringify({ error: 'Storage error: ' + e.message }), { status: 500, headers: corsHeaders });
  }
}

export async function onRequestOptions() {
  return new Response(null, { headers: corsHeaders });
}
