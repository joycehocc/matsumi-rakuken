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
    const list = await env.DATA.list({ prefix: 'submission_' });
    const submissions = await Promise.all(
      list.keys.map(k => env.DATA.get(k.name, 'json'))
    );
    submissions.sort((a, b) => (b.id || 0) - (a.id || 0));
    return new Response(JSON.stringify({ submissions, total: submissions.length }), { headers: corsHeaders });
  } catch (e) {
    return new Response(JSON.stringify({ error: 'Storage error: ' + e.message }), { status: 500, headers: corsHeaders });
  }
}

export async function onRequestDelete({ request, env }) {
  const token = request.headers.get('x-auth-token');
  if (!await verifyToken(token, env)) {
    return new Response(JSON.stringify({ error: '未授权' }), { status: 401, headers: corsHeaders });
  }

  try {
    const list = await env.DATA.list({ prefix: 'submission_' });
    await Promise.all(list.keys.map(k => env.DATA.delete(k.name)));
    await env.DATA.delete('count');
    return new Response(JSON.stringify({ success: true }), { headers: corsHeaders });
  } catch (e) {
    return new Response(JSON.stringify({ error: 'Storage error: ' + e.message }), { status: 500, headers: corsHeaders });
  }
}

export async function onRequestOptions() {
  return new Response(null, { headers: corsHeaders });
}
