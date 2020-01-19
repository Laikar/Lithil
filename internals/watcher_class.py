import time
from typing import TYPE_CHECKING, Callable

from discord import Guild, VoiceChannel
from discord.ext import tasks
from discord.ext.commands import Cog
from discord.ext.tasks import Loop

if TYPE_CHECKING:
    from internals import LithilClient


class Watcher(Cog):
    def __init__(self, name: str, tick_rate: int, func: Callable[['LithilClient'], None], client: 'LithilClient'):
        self.name: str = name or func.__name__
        self.tick_rate: int = tick_rate
        self.func: Callable[['LithilClient'], None] = func
        self.watching: bool = False
        self.client: 'LithilClient' = client
        self.client.logger.info("Registered {0}".format(self.name))

        @tasks.loop(seconds=self.tick_rate)
        async def watch():
            self.func(self.client)

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
