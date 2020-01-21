from typing import TYPE_CHECKING, AnyStr

from discord import Guild, VoiceChannel, Member

if TYPE_CHECKING:
    from internals import LithilClient
from internals import watcher


@watcher(tick_rate=60)
def voice_channel_watcher(client: 'LithilClient') -> AnyStr:
    output = "Voice Channel Watcher watched: "
    for server in client.guilds:
        server: Guild
        for voice_channel in server.voice_channels:
            voice_channel: VoiceChannel
            if len(voice_channel.members) > 1:
                for member in voice_channel.members:
                    member: Member
                    output += "{}, ".format(member.display_name)
                    client.bank.add_currency(member, client.bank.money_per_minute_on_voice)
    return output


@watcher(tick_rate=10, log=True)
async def ranking_updater(client: 'LithilClient') -> AnyStr:
    if client.bank.ranking_update_pending:
        await client.bank.update_rankings()
        out = "Updated rankings"
    else:
        out = "No rankings to update"
    return out
