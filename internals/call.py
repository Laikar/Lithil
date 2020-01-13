from __future__ import annotations

from typing import List, Dict, AnyStr, TYPE_CHECKING


from discord import Message, Guild, Member, TextChannel


class Call:
    def __init__(self, message: Message, header: str = "_"):
        beheaded = message.content.replace(header, "", 1)
        split = beheaded.split(" ")
        self.command: AnyStr = split[0]
        self.args: List[AnyStr] = split[1:]
        self.caller: Member = message.author
        self.targets: List[Member] = message.mentions
        self.channel: TextChannel = message.channel
        self.raw_content: AnyStr = message.content
        self.beheaded_content = beheaded.replace(self.command, "", 1)
        self.message: Message = message
        self.server: Guild = message.guild
