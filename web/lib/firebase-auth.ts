import {
  signInWithPopup,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  updateProfile,
  signOut,
  AuthProvider,
  UserCredential,
} from 'firebase/auth';
import { auth, googleProvider, githubProvider } from './firebase';
import { API_BASE } from './api';

export type SocialProvider = 'google' | 'github';

/** Sign in with Google or GitHub via Firebase popup */
export async function signInWithProvider(provider: SocialProvider): Promise<{
  user_id: string;
  token: string;
  refresh_token: string;
  user_profile: { user_id: string; email: string; name: string; role: string };
}> {
  const fbProvider: AuthProvider =
    provider === 'google' ? googleProvider : githubProvider;

  const cred: UserCredential = await signInWithPopup(auth, fbProvider);
  const idToken = await cred.user.getIdToken();

  // Exchange Firebase ID token for JanArogya JWT
  const res = await fetch(`${API_BASE}/auth/firebase`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id_token: idToken }),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error((err as { detail?: string }).detail ?? 'Authentication failed');
  }

  return res.json();
}

/** Sign in with email + password through Firebase then exchange for JWT */
export async function signInWithEmail(email: string, password: string): Promise<{
  user_id: string;
  token: string;
  refresh_token: string;
  user_profile: { user_id: string; email: string; name: string; role: string };
}> {
  const cred = await signInWithEmailAndPassword(auth, email, password);
  const idToken = await cred.user.getIdToken();

  const res = await fetch(`${API_BASE}/auth/firebase`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id_token: idToken }),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error((err as { detail?: string }).detail ?? 'Authentication failed');
  }

  return res.json();
}

/** Register with email + password through Firebase */
export async function registerWithEmail(name: string, email: string, password: string): Promise<{
  user_id: string;
  token: string;
  refresh_token: string;
  user_profile: { user_id: string; email: string; name: string; role: string };
}> {
  const cred = await createUserWithEmailAndPassword(auth, email, password);
  await updateProfile(cred.user, { displayName: name });
  const idToken = await cred.user.getIdToken();

  const res = await fetch(`${API_BASE}/auth/firebase`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id_token: idToken }),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error((err as { detail?: string }).detail ?? 'Registration failed');
  }

  return res.json();
}

/** Sign out from Firebase */
export async function firebaseSignOut(): Promise<void> {
  await signOut(auth);
}
