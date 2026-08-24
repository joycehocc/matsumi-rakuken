import { verifyToken } from '../login.js';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, X-Auth-Token',
  'Content-Type': 'application/json; charset=utf-8',
};

export async function onRequestGet({ request, env }) {
  const token = request.headers.get('x-auth-token');
  if (!await verifyToken(token, env)) {
    return new Response(JSON.stringify({ error: '未授权' }), { status: 401, headers: corsHeaders });
  }

  try {
    const result = await env.DB.prepare('SELECT * FROM submissions ORDER BY id DESC').all();
    return new Response(JSON.stringify({ submissions: result.results || [], total: (result.results || []).length }), { headers: corsHeaders });
  } catch (e) {
    return new Response(JSON.stringify({ error: 'Database error: ' + e.message }), { status: 500, headers: corsHeaders });
  }
}

export async function onRequestDelete({ request, env }) {
  const token = request.headers.get('x-auth-token');
  if (!await verifyToken(token, env)) {
    return new Response(JSON.stringify({ error: '未授权' }), { status: 401, headers: corsHeaders });
  }

  try {
    await env.DB.prepare('DELETE FROM submissions').run();
    return new Response(JSON.stringify({ success: true }), { headers: corsHeaders });
  } catch (e) {
    return new Response(JSON.stringify({ error: 'Database error: ' + e.message }), { status: 500, headers: corsHeaders });
  }
}

export async function onRequestOptions() {
  return new Response(null, { headers: corsHeaders });
}
