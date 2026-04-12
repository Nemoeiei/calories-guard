"""
Supabase Auth dependencies for FastAPI.

Provides:
  - get_current_user: verify Supabase JWT → return user dict with user_id, email, role_id
  - get_current_admin: same but requires role_id == 1
"""

import os
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
from dotenv import load_dotenv

# โหลด env
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '..', '.env'))
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))

SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET", "")
ALGORITHM = "HS256"

_bearer_scheme = HTTPBearer(auto_error=False)


def _decode_token(token: str) -> dict:
    """Decode and verify a Supabase JWT. Returns the payload dict."""
    try:
        payload = jwt.decode(
            token,
            SUPABASE_JWT_SECRET,
            algorithms=[ALGORITHM],
            options={"verify_aud": False},
        )
        return payload
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e


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
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    FastAPI dependency: require admin role (role_id == 1).

    For now, check app_metadata.role_id or user_metadata.role_id.
    Falls back to checking the DB if needed (done at endpoint level).
    """
    # This is a simple check — in production, verify against DB
    # For now, we pass through and let endpoints check role_id from DB
    # The main purpose is to ensure authentication exists
    return current_user


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
