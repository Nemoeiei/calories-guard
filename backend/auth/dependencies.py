"""
Supabase Auth dependencies for FastAPI.

Provides:
  - get_current_user: verify Supabase JWT → return user dict with user_id, email, role_id
  - get_current_admin: same but requires role_id == 1
"""

import os
import requests as _requests
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError, jwk
from dotenv import load_dotenv

# โหลด env
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '..', '.env'))
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))

SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET", "")
SUPABASE_URL = os.getenv("SUPABASE_PROJECT_URL") or os.getenv("SUPABASE_URL", "")
_JWKS_CACHE: list = []

_bearer_scheme = HTTPBearer(auto_error=False)


def _get_jwks() -> list:
    global _JWKS_CACHE
    if _JWKS_CACHE:
        return _JWKS_CACHE
    if not SUPABASE_URL:
        print("AUTH: SUPABASE_URL not set, cannot fetch JWKS")
        return []
    try:
        resp = _requests.get(f"{SUPABASE_URL}/auth/v1/.well-known/jwks.json", timeout=5)
        if resp.status_code == 200:
            _JWKS_CACHE = resp.json().get("keys", [])
            print(f"AUTH: JWKS loaded, {len(_JWKS_CACHE)} key(s)")
        else:
            print(f"AUTH: JWKS fetch failed: {resp.status_code}")
    except Exception as e:
        print(f"AUTH: JWKS fetch error: {e}")
    return _JWKS_CACHE


def _decode_token(token: str) -> dict:
    """Decode and verify a Supabase JWT. Supports both HS256 (legacy) and ES256 (ECC P-256)."""
    # Try HS256 with shared secret first (legacy)
    if SUPABASE_JWT_SECRET:
        try:
            return jwt.decode(
                token,
                SUPABASE_JWT_SECRET,
                algorithms=["HS256"],
                options={"verify_aud": False},
            )
        except JWTError:
            pass

    # Try ES256 via JWKS (new ECC P-256 key)
    header = jwt.get_unverified_header(token)
    kid = header.get("kid")
    keys = _get_jwks()
    for key_data in keys:
        if kid and key_data.get("kid") != kid:
            continue
        try:
            public_key = jwk.construct(key_data)
            return jwt.decode(
                token,
                public_key,
                algorithms=["ES256", "RS256"],
                options={"verify_aud": False},
            )
        except JWTError:
            continue

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired token",
        headers={"WWW-Authenticate": "Bearer"},
    )


def _get_user_id_from_payload(payload: dict) -> Optional[int]:
    """
    Map Supabase auth user (UUID in 'sub') to our DB user_id.
    Supabase JWT contains 'sub' (UUID) and optionally 'email'.
    We store the mapping in app_metadata or look up by email.

    For now: check if 'user_id' is in app_metadata, otherwise
    the endpoint must resolve it from the email.
    """
    # Try app_metadata.user_id first (set during registration)
    app_meta = payload.get("app_metadata", {})
    if "user_id" in app_meta:
        return int(app_meta["user_id"])

    # Try user_metadata.user_id
    user_meta = payload.get("user_metadata", {})
    if "user_id" in user_meta:
        return int(user_meta["user_id"])

    return None


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_scheme),
) -> dict:
    """
    FastAPI dependency: verify Bearer token → return user info dict.

    Returns:
        {
            "sub": "uuid-...",           # Supabase auth UUID
            "email": "user@example.com",
            "user_id": 123,              # Our DB user_id (if available in metadata)
            "role": "authenticated",
        }

    Raises 401 if no token or invalid token.
    """
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    payload = _decode_token(credentials.credentials)

    user_id = _get_user_id_from_payload(payload)

    return {
        "sub": payload.get("sub"),
        "email": payload.get("email"),
        "user_id": user_id,
        "role": payload.get("role", "authenticated"),
    }


async def get_current_admin(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_scheme),
) -> dict:
    """
    FastAPI dependency: require admin role (role_id == 1).

    Verifies the JWT and checks app_metadata.role_id == 1.
    Raises 401 if no/invalid token, 403 if not an admin.
    """
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    payload = _decode_token(credentials.credentials)
    app_meta = payload.get("app_metadata") or {}
    role_id = app_meta.get("role_id")
    if role_id != 1:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required",
        )

    return {
        "sub": payload.get("sub"),
        "email": payload.get("email"),
        "user_id": _get_user_id_from_payload(payload),
        "role_id": role_id,
    }


def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_scheme),
) -> Optional[dict]:
    """
    FastAPI dependency: optionally extract user from token.
    Returns None if no token provided (for public endpoints).
    Raises 401 only if token IS provided but invalid.
    """
    if credentials is None:
        return None

    payload = _decode_token(credentials.credentials)
    user_id = _get_user_id_from_payload(payload)

    return {
        "sub": payload.get("sub"),
        "email": payload.get("email"),
        "user_id": user_id,
        "role": payload.get("role", "authenticated"),
    }
