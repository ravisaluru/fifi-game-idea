// Smoke-tests the online rooms backend end to end (create → join → start →
// score → finish → leave, plus join-error cases and idea submission).
//
//   npm run dev:worker          # in one terminal
//   node scripts/smoke-online.mjs [http://localhost:8787]
//
// Needs Node 22+ (global WebSocket). Exits 0 on success.

const base = process.argv[2] || 'http://localhost:8787';
const wsBase = base.replace(/^http/, 'ws');

const fail = (msg) => { console.error(`✗ ${msg}`); process.exit(1); };
const ok = (msg) => console.log(`✓ ${msg}`);

function connect(code) {
  const ws = new WebSocket(`${wsBase}/api/rooms/${code}/ws`);
  const inbox = [];
  const waiters = [];
  ws.addEventListener('message', (ev) => {
    const msg = JSON.parse(ev.data);
    const i = waiters.findIndex((w) => w.pred(msg));
    if (i >= 0) waiters.splice(i, 1)[0].resolve(msg);
    else inbox.push(msg);
  });
  const next = (pred, label) => {
    const i = inbox.findIndex(pred);
    if (i >= 0) return Promise.resolve(inbox.splice(i, 1)[0]);
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error(`timeout waiting for ${label}`)), 8000);
      waiters.push({ pred, resolve: (m) => { clearTimeout(timer); resolve(m); } });
    });
  };
  const open = new Promise((resolve, reject) => {
    ws.addEventListener('open', resolve);
    ws.addEventListener('error', () => reject(new Error('socket error')));
  });
  return { ws, next, open, send: (o) => ws.send(JSON.stringify(o)) };
}

const code = 'TEST';

// Make sure any leftover room from a previous run is gone.
{
  const c = connect(code);
  await c.open;
  c.send({ t: 'remove' });
  c.ws.close();
  await new Promise((r) => setTimeout(r, 300));
}

// Host creates the room.
const host = connect(code);
await host.open;
host.send({ t: 'create', playerId: 'h1', name: 'Fifi', worldId: 'tiger' });
let msg = await host.next((m) => m.t === 'room', 'create snapshot');
if (msg.room.hostId !== 'h1' || msg.room.status !== 'lobby') fail('create: bad room');
ok('host created room');

// Duplicate create is rejected.
host.send({ t: 'create', playerId: 'h2', name: 'X', worldId: 'tiger' });
msg = await host.next((m) => m.t === 'error', 'exists error');
if (msg.code !== 'exists') fail(`expected exists, got ${msg.code}`);
ok('duplicate create rejected');

// Guest joins; both sides see 2 players.
const guest = connect(code);
await guest.open;
guest.send({ t: 'join', playerId: 'g1', name: 'Buddy' });
msg = await guest.next((m) => m.t === 'room' && m.room.players && m.room.players.g1, 'join snapshot');
ok('guest joined');
await host.next((m) => m.t === 'room' && m.room.players && m.room.players.g1, 'host sees guest');
ok('host saw guest arrive');

// Unknown room rejects join.
{
  const c = connect('ZZZZ');
  await c.open;
  c.send({ t: 'join', playerId: 'x', name: 'X' });
  msg = await c.next((m) => m.t === 'error', 'not_found error');
  if (msg.code !== 'not_found') fail(`expected not_found, got ${msg.code}`);
  c.ws.close();
  ok('joining a missing room rejected');
}

// Host starts the match; guest is told.
host.send({ t: 'start', worldId: 'bubble' });
msg = await guest.next((m) => m.t === 'room' && m.room.status === 'playing', 'start snapshot');
if (msg.room.worldId !== 'bubble') fail('start: worldId not updated');
ok('match started, guest notified');

// Joining a started game is rejected.
{
  const c = connect(code);
  await c.open;
  c.send({ t: 'join', playerId: 'late', name: 'Late' });
  msg = await c.next((m) => m.t === 'error', 'started error');
  if (msg.code !== 'started') fail(`expected started, got ${msg.code}`);
  c.ws.close();
  ok('late join rejected');
}

// Scores propagate; finishing propagates.
guest.send({ t: 'score', playerId: 'g1', score: 42, progress: 0.5 });
msg = await host.next((m) => m.t === 'room' && m.room.players.g1.score === 42, 'score snapshot');
if (msg.room.players.g1.progress !== 0.5) fail('score: progress not updated');
ok('score propagated to host');
guest.send({ t: 'finished', playerId: 'g1' });
await host.next((m) => m.t === 'room' && m.room.players.g1.status === 'finished', 'finished snapshot');
ok('finish propagated to host');

// Guest socket dropping removes the player (onDisconnect parity).
guest.ws.close();
await host.next((m) => m.t === 'room' && m.room.players && !m.room.players.g1, 'guest cleanup');
ok('guest disconnect removed player');

// Host socket dropping tears the room down.
host.ws.close();
await new Promise((r) => setTimeout(r, 300));
{
  const c = connect(code);
  await c.open;
  c.send({ t: 'join', playerId: 'x', name: 'X' });
  msg = await c.next((m) => m.t === 'error', 'room gone');
  if (msg.code !== 'not_found') fail(`expected not_found after host left, got ${msg.code}`);
  c.ws.close();
  ok('host disconnect tore room down');
}

// Ideas endpoint accepts a POST and refuses unauthenticated reads.
let res = await fetch(`${base}/api/ideas`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ emoji: '🚀', name: 'Rocket Race', idea: 'fly to the moon', by: 'Fifi' }),
});
if (!res.ok) fail(`idea POST failed: ${res.status}`);
ok('idea submitted');
res = await fetch(`${base}/api/ideas`);
if (res.status !== 403) fail(`idea GET should be 403, got ${res.status}`);
ok('idea list locked without key');

console.log('\nAll online smoke tests passed 🎉');
process.exit(0);
