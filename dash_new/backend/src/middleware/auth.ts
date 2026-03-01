import type { Request, Response, NextFunction } from 'express';

import { adminAppCheck, adminAuth } from '../firebase.js';
import { config, isProd } from '../config.js';
import { log } from '../logger.js';
import type { AuthContext } from '../types.js';

export type AuthenticatedRequest = Request & {
  auth?: AuthContext;
};

function getBearerToken(req: Request): string | null {
  const header = req.header('authorization') ?? req.header('Authorization');
  if (!header) return null;
  const [scheme, token] = header.split(' ');
  if (!scheme || !token) return null;
  if (scheme.toLowerCase() !== 'bearer') return null;
  return token.trim();
}

export async function verifyFirebaseAuth(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
  const idToken = getBearerToken(req);
  if (!idToken) {
    res.status(401).json({ error: 'missing_auth_token' });
    return;
  }

  try {
    const decoded = await adminAuth.verifyIdToken(idToken, isProd);
    req.auth = {
      uid: decoded.uid,
      appCheckVerified: false,
    };
    next();
  } catch {
    log('warn', { event: 'auth.verify_failed', route: req.path, ip: req.ip });
    res.status(401).json({ error: 'invalid_auth_token' });
  }
}

export async function verifyAppCheckIfPresent(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
  const appCheckToken = req.header('X-Firebase-AppCheck') ?? req.header('x-firebase-appcheck');

  if (!appCheckToken) {
    if (isProd) {
      log('warn', {
        event: 'app_check.missing',
        uid: req.auth?.uid,
        route: req.path,
        ip: req.ip,
      });
      res.status(401).json({ error: 'missing_app_check_token' });
      return;
    }
    next();
    return;
  }

  try {
    await adminAppCheck.verifyToken(appCheckToken);
    if (req.auth) {
      req.auth.appCheckVerified = true;
    }
    next();
  } catch {
    log('warn', {
      event: 'app_check.verify_failed',
      uid: req.auth?.uid,
      route: req.path,
      ip: req.ip,
      details: { env: config.env },
    });
    res.status(401).json({ error: 'invalid_app_check_token' });
  }
}
