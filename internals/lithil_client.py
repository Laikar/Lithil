from typing import List, Callable, AnyStr, Coroutine, Any, TYPE_CHECKING

from internals import CurrencyManager, CommandContainer, Config, DataIO
from discord import Message

from pathlib import Path
import discord
from internals.call import Call


class LithilClient(discord.Client):
    def __init__(self, bot_path: Path, *args, **kwargs):

        super().__init__(**kwargs)
        #initialziation
        self.bot_path = bot_path
        self.config_path = bot_path / "config"
        self.command_path = bot_path / "commands"
        self.data_path = bot_path / "data"
        self.data_manager = DataIO(self.data_path)
        self.command_container: CommandContainer = CommandContainer(self.command_path)
        self.on_message_events: List[Callable[[Message], Coroutine[Any, Any, None]]] = []
        self.on_message_events.append(self.process_message)

        #Config
        self.config: Config = Config(self.config_path)
        self.token = self.config["token"]
        self.bank: CurrencyManager = CurrencyManager(self, self.config["currency"])
        self.command_header: str = self.config["command_header"]

    async def on_ready(self):
        print('Logged on as {0}!'.format(self.user))

    async def on_message(self, message: Message):
        if not message.author.bot:
            for on_message_event in self.on_message_events:
                await on_message_event(message)

            print('Message from {0.author}: {0.content}'.format(message))

    async def on_disconnect(self):
        self.bank.store_standings()

    def should_process(self, message: Message) -> bool:
        return message.content.startswith(self.command_header)

    async def process_message(self, message: Message) -> None:
        if self.should_process(message):
            call = Call(message)
            if call.command in self.command_container.caller_dictionary.keys():
                await self.command_container.call_command(call, self)
