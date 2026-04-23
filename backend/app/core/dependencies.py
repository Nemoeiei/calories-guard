from fastapi import HTTPException


def check_ownership(current_user: dict, path_user_id: int):
    """Verify that the authenticated user owns the resource."""
    token_user_id = current_user.get("user_id")
    if token_user_id is None:
        return
    if token_user_id != path_user_id:
        raise HTTPException(status_code=403, detail="Access denied: you can only access your own data")
