// firebase.js — lazy Firebase bootstrap for online play.
//
// Configuration comes from Vite env vars (see .env.example). Just like the old
// Flutter app, online play degrades gracefully: when Firebase isn't configured
// the rest of the game (solo + robots) works fully without it, and the
// multiplayer screen explains that online rooms are off.
//
// The Firebase SDK is imported dynamically so it's split into its own chunk
// and only downloaded when someone actually opens online play.

const env = import.meta.env;

export const firebaseConfig = env.VITE_FIREBASE_DATABASE_URL
  ? {
      apiKey: env.VITE_FIREBASE_API_KEY,
      authDomain: env.VITE_FIREBASE_AUTH_DOMAIN,
      databaseURL: env.VITE_FIREBASE_DATABASE_URL,
      projectId: env.VITE_FIREBASE_PROJECT_ID,
      appId: env.VITE_FIREBASE_APP_ID,
    }
  : null;

export const onlineAvailable = !!firebaseConfig;

let dbPromise = null;

// Resolves to { db, api } where api is the firebase/database module.
export function getDb() {
  if (!onlineAvailable) return Promise.reject(new Error('Online play is not configured'));
  if (!dbPromise) {
    dbPromise = Promise.all([
      import('firebase/app'),
      import('firebase/database'),
    ]).then(([{ initializeApp }, api]) => {
      const app = initializeApp(firebaseConfig);
      return { db: api.getDatabase(app), api };
    });
  }
  return dbPromise;
}
