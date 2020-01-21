import time
from asyncio import iscoroutinefunction
from typing import TYPE_CHECKING, Callable

from discord import Guild, VoiceChannel
from discord.ext import tasks
from discord.ext.commands import Cog
from discord.ext.tasks import Loop

if TYPE_CHECKING:
    from internals import LithilClient


class Watcher(Cog):
    def __init__(self, name: str, tick_rate: int, func: Callable[['LithilClient'], None], client: 'LithilClient',
                 log: bool = False):
        self.name: str = name or func.__name__
        self.tick_rate: int = tick_rate
        self.func: Callable[['LithilClient'], None] = func
        self.watching: bool = False
        self.client: 'LithilClient' = client
        self.client.logger.info("Registered {0}".format(self.name))
        self.log_activation: bool = log

        if iscoroutinefunction(func):
            @tasks.loop(seconds=self.tick_rate)
            async def watch():
                log_msg = await self.func(self.client)
                if self.log_activation:
                    self.client.logger.info(log_msg)
        else:
            @tasks.loop(seconds=self.tick_rate)
            async def watch():
                log_msg = self.func(self.client)
                if self.log_activation:
                    self.client.logger.info(log_msg)

        @watch.before_loop
        async def before_watch():
            self.client.logger.info("{0} Started".format(self.name))

        @watch.after_loop
        async def after_watch():
            self.client.logger.info("{0} Stopped".format(self.name))

        self.watch: Loop = watch

    def start_watching(self):
        self.watch.start()

    def stop_watching(self):
        self.watch.stop()
