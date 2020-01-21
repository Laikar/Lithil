from __future__ import annotations
import asyncio
import logging
import signal
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import List, Callable, Coroutine, Any

import discord
from discord import Message, TextChannel

from internals import CurrencyManager, CommandContainer, Config, DataIO, Call, Watcher


class LithilClient(discord.Client):
    def __init__(self, bot_path: Path, *args, **kwargs):

        super().__init__(**kwargs)
        # Path setting
        self.bot_path = bot_path
        self.config_path = bot_path / "config"
        self.command_path = bot_path / "commands"
        self.data_path = bot_path / "data"
        self.log_file = bot_path / "lithil.log"

        # EventLists
        self.on_message_events: List[Callable[[Message], Coroutine[Any, Any, None]]] = []
        self.on_ready_events: List[Callable[[], Coroutine[Any, Any, None]]] = []
        self.on_close_events: List[Callable[[], Coroutine[Any, Any, None]]] = []
        self.watchers: List[Watcher] = []

        # Logging

        self.logger = logging.getLogger('discord')
        self.logger.setLevel(logging.INFO)
        self.logging_file_handler = logging.FileHandler(filename=str(self.log_file.absolute()), encoding='utf-8',
                                                        mode='w')
        self.logging_file_handler.setFormatter(logging.Formatter('%(asctime)s:%(levelname)s:%(name)s: %(message)s'))
        self.logger.addHandler(self.logging_file_handler)

        # Config
        self.data_manager = DataIO(self.data_path)
        self.config: Config = Config(self.config_path)
        self.token = self.config["token"]
        self.bank: CurrencyManager = CurrencyManager(self, self.config["currency"])
        self.log_channel: TextChannel = None
        self.command_container: CommandContainer = CommandContainer(self.config['commands'], self.command_path, self)

        self.watching_voice_channels = False
        self.process_pool = ThreadPoolExecutor(5)
        try:
            self.loop.add_signal_handler(signal.SIGTERM, lambda: asyncio.ensure_future(self.stop_bot()))
        except NotImplementedError:
            pass

    async def on_ready(self):
        self.logger.info("Logged on as {0}".format(self.user))
        self.log_channel = self.get_channel(self.config["log_channel"])
        self.logger.info("Log channel is {0} with ID {1}".format(self.log_channel.name, self.log_channel.id))
        for event in self.on_ready_events:
            await event()
        async for message in self.log_channel.history(limit=200):
            message: 'Message'
            if message.author is self.user:
                await message.delete()
        await self.log_channel.send("Lithil On")
        for watcher in self.watchers:
            watcher.start_watching()

    async def on_message(self, message: Message):
        if not message.author.bot:
            self.logger.info('Message from {0.author}: {0.content}'.format(message))
            for on_message_event in self.on_message_events:
                await on_message_event(message)

    def run_bot(self):
        async def runner():
            try:
                await self.start(self.token)
            finally:
                await self.stop_bot()

        future = asyncio.ensure_future(runner(), loop=self.loop)
        future.add_done_callback(self.loop.stop)
        try:
            self.loop.run_forever()
        except KeyboardInterrupt:
            self.logger.info('Received signal to terminate bot and event loop.')
        finally:
            future.remove_done_callback(self.loop.stop)

    async def stop_bot(self):
        self.logger.info(msg="Apagando")
        await self.log_channel.send("Lithil Off")
        for event in self.on_close_events:
            event()
        self.watching_voice_channels = False
        await self.logout()
        self.loop.stop()

    # TODO Añadir decorators para convertir las funciones en eventos automáticamente
