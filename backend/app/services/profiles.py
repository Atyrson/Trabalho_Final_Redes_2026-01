def multicast_address(profile: str, group_id: int, channel_number: int) -> str:
    if profile == "LAN":
        return f"239.10.{group_id}.{channel_number}"
    if profile == "WAN115K":
        return f"239.20.{group_id}.{channel_number}"
    raise ValueError(f"unknown profile: {profile}")
