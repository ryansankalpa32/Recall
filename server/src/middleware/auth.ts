import { Request, Response, NextFunction } from "express";
import { auth } from "../config/firebase";

/**
 * Express request with the authenticated user's UID attached.
 *
 * Populated by `authenticateUser` middleware after verifying the
 * Firebase ID token sent in the `Authorization: Bearer <token>` header.
 */
export interface AuthRequest extends Request {
  uid?: string;
}

/**
 * Verifies the Firebase ID token from the Authorization header and
 * attaches the decoded `uid` to the request object.
 *
 * The Flutter client obtains an ID token via
 * `FirebaseAuth.instance.currentUser!.getIdToken()` — this works with
 * both anonymous and full sign-in methods.
 */
export async function authenticateUser(
  req: AuthRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res
      .status(401)
      .json({ error: "Missing or invalid Authorization header" });
    return;
  }

  const token = authHeader.split("Bearer ")[1];
  try {
    const decoded = await auth.verifyIdToken(token);
    req.uid = decoded.uid;
    next();
  } catch (error) {
    console.error("[Auth] Token verification failed:", error);
    res.status(401).json({ error: "Invalid or expired token" });
  }
}
