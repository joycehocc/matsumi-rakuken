import { verifyToken } from './login.js';

export async function onRequestGet({ request, env }) {
  const token = request.headers.get('x-auth-token');
  if (!await verifyToken(token, env)) {
    return new Response(JSON.stringify({ error: '未授权' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json; charset=utf-8' },
    });
  }

  try {
    const result = await env.DB.prepare('SELECT * FROM submissions ORDER BY id DESC').all();
    const rows = result.results || [];

    const header = '编号,姓名,电话,邮箱,意向服务,留言内容,提交时间\n';
    const csvRows = rows.map(s => {
      const msg = (s.message || '').replace(/\n/g, ' ');
      let timeStr = s.time || '';
      try {
        const dt = new Date(s.time);
        timeStr = dt.getFullYear() + '-' +
          String(dt.getMonth() + 1).padStart(2, '0') + '-' +
          String(dt.getDate()).padStart(2, '0') + ' ' +
          String(dt.getHours()).padStart(2, '0') + ':' +
          String(dt.getMinutes()).padStart(2, '0') + ':' +
          String(dt.getSeconds()).padStart(2, '0');
      } catch (e) {}
      const values = [s.id, s.name, s.phone, s.email, s.service, msg, timeStr];
      return values.map(v => '"' + String(v || '').replace(/"/g, '""') + '"').join(',');
    });

    const csv = '\uFEFF' + header + csvRows.join('\n');
    return new Response(csv, {
      headers: {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': 'attachment; filename=submissions.csv',
      },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: 'Database error: ' + e.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json; charset=utf-8' },
    });
  }
}

export async function onRequestOptions() {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, X-Auth-Token',
    },
  });
}
