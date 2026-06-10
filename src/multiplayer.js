// multiplayer.js — realtime online rooms on Cloudflare Durable Objects.
//
// The worker (worker/index.js) keeps one Room object per 4-letter code and
// mirrors the original Firebase Realtime Database schema:
//
//   { hostId, worldId, status: 'lobby' | 'playing', createdAt,
//     players: { [id]: { name, isAi, score, progress, status } } }
//
// Player status: waiting | ready | playing | finished.
//
// One WebSocket per room code is shared across screens (lobby → game). The
// server broadcasts the full room snapshot after every change, so watchers
// behave like Firebase's onValue; the server removes a player whose socket
// closes (the whole room when it's the host's), standing in for onDisconnect.

// Unambiguous alphabet (no O/0/I/1) — same as the Dart service.
const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

// The rooms backend deploys together with the site, so online play is always
// on. (Override VITE_API_BASE only if the site is served from another host.)
export const onlineAvailable = true;

const API_BASE = import.meta.env.VITE_API_BASE || '';

export function generateRoomCode(rng = Math.random) {
  let code = '';
  for (let i = 0; i < 4; i++) code += CODE_CHARS[Math.floor(rng() * CODE_CHARS.length)];
  return code;
}

export function localPlayerId() {
  try {
    let id = sessionStorage.getItem('fifi_player_id');
    if (!id) {
      id = (crypto.randomUUID ? crypto.randomUUID() : 'p' + Math.random().toString(36).slice(2));
      sessionStorage.setItem('fifi_player_id', id);
    }
    return id;
  } catch (e) {
    return 'p' + Math.random().toString(36).slice(2);
  }
}

export function playerPayload(name) {
  return { name, isAi: false, score: 0, progress: 0, status: 'waiting' };
}

function wsUrl(code) {
  if (API_BASE) return `${API_BASE.replace(/^http/, 'ws')}/api/rooms/${code}/ws`;
  const proto = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  return `${proto}//${window.location.host}/api/rooms/${code}/ws`;
}

// ── Connection registry ──────────────────────────────────────────────────────
// Lives at module level so the lobby screen, the app shell, and the game host
// all share one socket per room.
const conns = new Map();

class RoomConnection {
  constructor(code) {
    this.code = code;
    this.listeners = new Set();
    this.room = null;
    this.waiters = [];
    this.queue = [];
    this.closedByUs = false;
    this.pendingClose = false;
    this.ws = new WebSocket(wsUrl(code));
    this.ws.onopen = () => {
      for (const data of this.queue.splice(0)) this.ws.send(data);
      if (this.pendingClose) this.ws.close();
    };
    this.ws.onmessage = (ev) => this.handle(ev.data);
    this.ws.onclose = () => {
      if (conns.get(this.code) === this) conns.delete(this.code);
      const err = new Error('Connection closed');
      for (const w of this.waiters.splice(0)) w.reject(err);
      // Server closed on us (room torn down / network drop): tell watchers
      // the room is gone, mirroring Firebase's "snapshot no longer exists".
      if (!this.closedByUs) {
        this.room = {};
        for (const cb of this.listeners) cb({});
      }
    };
    this.ws.onerror = () => {};
  }

  handle(data) {
    let msg;
    try { msg = JSON.parse(data); } catch { return; }
    if (msg.t === 'error') {
      const err = new Error(msg.code);
      err.code = msg.code;
      const w = this.waiters.shift();
      if (w) { clearTimeout(w.timer); w.reject(err); }
      return;
    }
    if (msg.t === 'room') {
      this.room = msg.room || {};
      this.waiters = this.waiters.filter((w) => {
        if (!w.match(this.room)) return true;
        clearTimeout(w.timer);
        w.resolve(this.room);
        return false;
      });
      for (const cb of this.listeners) cb(this.room);
    }
  }

  send(obj) {
    const data = JSON.stringify(obj);
    if (this.ws.readyState === WebSocket.OPEN) this.ws.send(data);
    else this.queue.push(data);
  }

  // Sends msg and resolves with the first room snapshot satisfying `match`,
  // or rejects on a server error reply (err.code set) or timeout.
  request(msg, match, timeoutMs = 10000) {
    return new Promise((resolve, reject) => {
      const w = { match, resolve, reject };
      w.timer = setTimeout(() => {
        this.waiters = this.waiters.filter((x) => x !== w);
        reject(new Error('Timed out'));
      }, timeoutMs);
      this.waiters.push(w);
      this.send(msg);
    });
  }

  close() {
    this.closedByUs = true;
    if (conns.get(this.code) === this) conns.delete(this.code);
    if (this.ws.readyState === WebSocket.CONNECTING) this.pendingClose = true;
    else { try { this.ws.close(); } catch (e) { /* already closed */ } }
  }
}

function getConn(code) {
  let conn = conns.get(code);
  if (!conn) {
    conn = new RoomConnection(code);
    conns.set(code, conn);
  }
  return conn;
}

// ── Create a new room ────────────────────────────────────────────────────────
export async function createRoom(hostId, hostName, gameId) {
  // Retry until we get an unused code (extremely rare collision).
  for (;;) {
    const code = generateRoomCode();
    const conn = getConn(code);
    try {
      await conn.request(
        { t: 'create', playerId: hostId, name: hostName, worldId: gameId },
        (room) => room.hostId === hostId,
      );
      return code;
    } catch (e) {
      conn.close();
      if (e.code !== 'exists') throw e;
    }
  }
}

// ── Join an existing room ────────────────────────────────────────────────────
export async function joinRoom(code, playerId, playerName) {
  const conn = getConn(code);
  try {
    return await conn.request(
      { t: 'join', playerId, name: playerName },
      (room) => !!(room.players && room.players[playerId]),
    );
  } catch (e) {
    conn.close();
    throw new Error(
      e.code === 'not_found' ? `Room ${code} not found`
        : e.code === 'started' ? 'Game already started'
          : e.code === 'full' ? 'Room is full'
            : e.message,
    );
  }
}

// ── Watch room changes ───────────────────────────────────────────────────────
// cb receives the room object ({} when the room is gone). Returns unsubscribe.
export async function watchRoom(code, cb) {
  const conn = getConn(code);
  conn.listeners.add(cb);
  if (conn.room) cb(conn.room);
  else conn.send({ t: 'watch', playerId: localPlayerId() });
  return () => conn.listeners.delete(cb);
}

// ── Game actions ─────────────────────────────────────────────────────────────
export async function startGame(code, gameId) {
  getConn(code).send({ t: 'start', worldId: gameId });
}

export async function updateScore(code, playerId, score, progress) {
  getConn(code).send({ t: 'score', playerId, score, progress });
}

export async function markFinished(code, playerId) {
  getConn(code).send({ t: 'finished', playerId });
}

export async function leaveRoom(code, playerId) {
  const conn = conns.get(code);
  if (!conn) return;
  conn.send({ t: 'leave', playerId });
  conn.close();
}

// Host backed out of the lobby — take the whole room down.
export async function removeRoom(code) {
  const conn = conns.get(code);
  if (!conn) return;
  conn.send({ t: 'remove' });
  conn.close();
}

// ── Suggest-a-Game ideas ─────────────────────────────────────────────────────
// Ideas always save locally; they're also sent to the worker so the game
// makers actually receive them.
export async function submitIdea(entry) {
  const res = await fetch(`${API_BASE}/api/ideas`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(entry),
  });
  if (!res.ok) throw new Error(`Idea submit failed: ${res.status}`);
}
