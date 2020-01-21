from typing import AnyStr, List

from discord import TextChannel, Message


class ChannelManager:

    @staticmethod
    async def purge_channel(channel: TextChannel):
        await channel.purge()

    @staticmethod
    async def make_info_channel(channel: TextChannel, content: AnyStr) -> Message:
        with channel.typing():
            await ChannelManager.purge_channel(channel)
            message: Message = await channel.send("WIP")
            await message.edit(content=content)
        return message

    @staticmethod
    async def make_info_channel_multiple_messages(channel: TextChannel, contents: List[AnyStr]) -> List[Message]:
        with channel.typing():
            messages: List[Message]
            ChannelManager.purge_channel(channel)
            for content in contents:
                message: Message = await channel.send("WIP")
                await message.edit(content=content)
                messages.append(message)
        return messages
