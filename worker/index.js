// worker/index.js — Cloudflare Worker: serves the built game (static assets)
// and hosts online multiplayer on Durable Objects (free plan, SQLite-backed).
//
// One `Room` object per 4-letter code, reached over WebSocket at
// /api/rooms/{CODE}/ws. The room state mirrors the original Firebase schema:
//
//   { hostId, worldId, status: 'lobby' | 'playing', createdAt,
//     players: { [id]: { name, isAi, score, progress, status } } }
//
// The server broadcasts the full room snapshot to every socket after each
// change (like Firebase's onValue), and a closing socket removes its player —
// or the whole room when it's the host — like Firebase's onDisconnect.

const ROOM_TTL_MS = 6 * 60 * 60 * 1000; // stale rooms expire after 6 hours
const MAX_PLAYERS = 4;
const ROOM_CODE = /^[A-HJ-NP-Z2-9]{4}$/; // same unambiguous alphabet as the client

const freshPlayer = (name) => ({
  name: String(name || 'Player').slice(0, 40),
  isAi: false,
  score: 0,
  progress: 0,
  status: 'waiting',
});

export class Room {
  constructor(state) {
    this.state = state;
  }

  async fetch(request) {
    if (request.headers.get('Upgrade') !== 'websocket') {
      return new Response('Expected a WebSocket', { status: 426 });
    }
    const pair = new WebSocketPair();
    this.state.acceptWebSocket(pair[1]); // hibernation API — no duration billed while idle
    return new Response(null, { status: 101, webSocket: pair[0] });
  }

  async webSocketMessage(ws, raw) {
    let msg;
    try { msg = JSON.parse(raw); } catch { return; }
    const storage = this.state.storage;
    const room = await storage.get('room');
    const reply = (obj) => { try { ws.send(JSON.stringify(obj)); } catch {} };

    switch (msg.t) {
      case 'create': {
        if (room) return reply({ t: 'error', code: 'exists' });
        const created = {
          hostId: msg.playerId,
          worldId: msg.worldId,
          status: 'lobby',
          createdAt: Date.now(),
          players: { [msg.playerId]: freshPlayer(msg.name) },
        };
        ws.serializeAttachment({ playerId: msg.playerId, isHost: true });
        await storage.put('room', created);
        await storage.setAlarm(Date.now() + ROOM_TTL_MS);
        return this.broadcast(created);
      }
      case 'join': {
        if (!room) return reply({ t: 'error', code: 'not_found' });
        if (room.status !== 'lobby') return reply({ t: 'error', code: 'started' });
        if (Object.keys(room.players).length >= MAX_PLAYERS) return reply({ t: 'error', code: 'full' });
        room.players[msg.playerId] = freshPlayer(msg.name);
        ws.serializeAttachment({ playerId: msg.playerId, isHost: false });
        await storage.put('room', room);
        return this.broadcast(room);
      }
      case 'watch': {
        // Re-attach an existing player's socket (e.g. after a reload).
        ws.serializeAttachment({ playerId: msg.playerId, isHost: !!room && room.hostId === msg.playerId });
        return reply({ t: 'room', room: room || {} });
      }
      case 'start': {
        if (!room) return;
        room.status = 'playing';
        room.worldId = msg.worldId;
        await storage.put('room', room);
        return this.broadcast(room);
      }
      case 'score': {
        const p = room && room.players && room.players[msg.playerId];
        if (!p) return;
        p.score = msg.score;
        p.status = 'playing';
        if (msg.progress != null) p.progress = msg.progress;
        await storage.put('room', room);
        return this.broadcast(room);
      }
      case 'finished': {
        const p = room && room.players && room.players[msg.playerId];
        if (!p) return;
        p.status = 'finished';
        await storage.put('room', room);
        return this.broadcast(room);
      }
      case 'leave': {
        if (!room || !room.players || !room.players[msg.playerId]) return;
        delete room.players[msg.playerId];
        await storage.put('room', room);
        return this.broadcast(room);
      }
      case 'remove':
        return this.teardown();
    }
  }

  async webSocketClose(ws) {
    let att = null;
    try { att = ws.deserializeAttachment(); } catch {}
    if (!att) return; // socket never created/joined — nothing to clean up
    const room = await this.state.storage.get('room');
    if (!room) return;
    if (att.isHost) return this.teardown();
    if (room.players && room.players[att.playerId]) {
      delete room.players[att.playerId];
      await this.state.storage.put('room', room);
      this.broadcast(room);
    }
  }

  async webSocketError(ws) {
    return this.webSocketClose(ws);
  }

  async alarm() {
    return this.teardown();
  }

  broadcast(room) {
    const data = JSON.stringify({ t: 'room', room: room || {} });
    for (const ws of this.state.getWebSockets()) {
      try { ws.send(data); } catch {}
    }
  }

  async teardown() {
    await this.state.storage.deleteAll();
    await this.state.storage.deleteAlarm();
    const gone = JSON.stringify({ t: 'room', room: {} });
    for (const ws of this.state.getWebSockets()) {
      try { ws.send(gone); ws.close(1000, 'room closed'); } catch {}
    }
  }
}

// Suggest-a-Game ideas land in one singleton object's storage. Reading them
// back requires the IDEAS_READ_KEY secret (`wrangler secret put IDEAS_READ_KEY`)
// since entries can include kids' first names.
export class Ideas {
  constructor(state, env) {
    this.state = state;
    this.env = env;
  }

  async fetch(request) {
    if (request.method === 'POST') {
      let entry;
      try { entry = await request.json(); } catch { return new Response('Bad JSON', { status: 400 }); }
      const key = `idea:${Date.now()}:${crypto.randomUUID()}`;
      await this.state.storage.put(key, {
        emoji: String(entry.emoji || '').slice(0, 8),
        name: String(entry.name || '').slice(0, 60),
        idea: String(entry.idea || '').slice(0, 1000),
        by: String(entry.by || '').slice(0, 40),
        at: Date.now(),
      });
      return Response.json({ ok: true });
    }
    if (request.method === 'GET') {
      const auth = request.headers.get('Authorization') || '';
      if (!this.env.IDEAS_READ_KEY || auth !== `Bearer ${this.env.IDEAS_READ_KEY}`) {
        return new Response('Forbidden', { status: 403 });
      }
      const map = await this.state.storage.list({ prefix: 'idea:' });
      return Response.json([...map.values()]);
    }
    return new Response('Method not allowed', { status: 405 });
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const parts = url.pathname.split('/').filter(Boolean);
    if (parts[0] === 'api') {
      if (parts[1] === 'rooms' && parts[2]) {
        const code = parts[2].toUpperCase();
        if (!ROOM_CODE.test(code)) return new Response('Bad room code', { status: 400 });
        return env.ROOMS.get(env.ROOMS.idFromName(code)).fetch(request);
      }
      if (parts[1] === 'ideas') {
        return env.IDEAS.get(env.IDEAS.idFromName('all')).fetch(request);
      }
      return new Response('Not found', { status: 404 });
    }
    return env.ASSETS.fetch(request);
  },
};
