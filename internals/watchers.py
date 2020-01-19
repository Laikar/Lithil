from typing import TYPE_CHECKING

from discord import Guild, VoiceChannel

if TYPE_CHECKING:
    from internals import LithilClient
from internals import watcher


@watcher(tick_rate=60)
def voice_channel_watcher(client: 'LithilClient'):
    for server in client.guilds:
        server: Guild
        for voice_channel in server.voice_channels:
            voice_channel: VoiceChannel
            if len(voice_channel.members) > 1:
                for member in voice_channel.members:
                    client.bank.add_currency(member, client.bank.money_per_minute_on_voice)
