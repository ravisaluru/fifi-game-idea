// multiplayer.js — realtime online rooms on Firebase Realtime Database.
//
// This mirrors the original Flutter MultiplayerService schema exactly, so any
// existing database rules/data keep working:
//
//   rooms/{CODE}: {
//     hostId, worldId, status: 'lobby' | 'playing', createdAt,
//     players/{id}: { name, isAi, score, progress, status }
//   }
//
// Player status: waiting | ready | playing | finished.
import { getDb } from './firebase.js';

// Unambiguous alphabet (no O/0/I/1) — same as the Dart service.
const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

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

// ── Create a new room ────────────────────────────────────────────────────────
export async function createRoom(hostId, hostName, gameId) {
  const { db, api } = await getDb();
  let code;
  // Retry until we get an unused code (extremely rare collision).
  for (;;) {
    code = generateRoomCode();
    const snap = await api.get(api.ref(db, `rooms/${code}`));
    if (!snap.exists()) break;
  }
  const roomRef = api.ref(db, `rooms/${code}`);
  await api.set(roomRef, {
    hostId,
    worldId: gameId,
    status: 'lobby',
    createdAt: api.serverTimestamp(),
    players: { [hostId]: playerPayload(hostName) },
  });
  // Clean the room up when the host drops off.
  api.onDisconnect(roomRef).remove();
  return code;
}

// ── Join an existing room ────────────────────────────────────────────────────
export async function joinRoom(code, playerId, playerName) {
  const { db, api } = await getDb();
  const snap = await api.get(api.ref(db, `rooms/${code}`));
  if (!snap.exists()) throw new Error(`Room ${code} not found`);
  const data = snap.val();
  if (data.status !== 'lobby') throw new Error('Game already started');
  const players = data.players || {};
  if (Object.keys(players).length >= 4) throw new Error('Room is full');

  const meRef = api.ref(db, `rooms/${code}/players/${playerId}`);
  await api.set(meRef, playerPayload(playerName));
  api.onDisconnect(meRef).remove();
  return data;
}

// ── Watch room changes ───────────────────────────────────────────────────────
// cb receives the room object ({} when the room is gone). Returns unsubscribe.
export async function watchRoom(code, cb) {
  const { db, api } = await getDb();
  return api.onValue(api.ref(db, `rooms/${code}`), (snap) => {
    cb(snap.exists() ? snap.val() : {});
  });
}

// ── Game actions ─────────────────────────────────────────────────────────────
export async function startGame(code, gameId) {
  const { db, api } = await getDb();
  await api.update(api.ref(db, `rooms/${code}`), { status: 'playing', worldId: gameId });
}

export async function updateScore(code, playerId, score, progress) {
  const { db, api } = await getDb();
  const updates = { [`players/${playerId}/score`]: score, [`players/${playerId}/status`]: 'playing' };
  if (progress != null) updates[`players/${playerId}/progress`] = progress;
  await api.update(api.ref(db, `rooms/${code}`), updates);
}

export async function markFinished(code, playerId) {
  const { db, api } = await getDb();
  await api.set(api.ref(db, `rooms/${code}/players/${playerId}/status`), 'finished');
}

export async function leaveRoom(code, playerId) {
  const { db, api } = await getDb();
  await api.remove(api.ref(db, `rooms/${code}/players/${playerId}`));
}

// Host backed out of the lobby — take the whole room down.
export async function removeRoom(code) {
  const { db, api } = await getDb();
  await api.remove(api.ref(db, `rooms/${code}`));
}

// ── Suggest-a-Game ideas ─────────────────────────────────────────────────────
// Ideas always save locally; when Firebase is configured they're also sent to
// `ideas/` so the game makers actually receive them.
export async function submitIdea(entry) {
  const { db, api } = await getDb();
  await api.set(api.push(api.ref(db, 'ideas')), { ...entry, at: api.serverTimestamp() });
}
