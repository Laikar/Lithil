from pathlib import Path

from .channel_manager import ChannelManager
from .call import Call
from .watcher_class import Watcher
from .data_io import DataIO
from .config import Config
from .currency_manager import CurrencyManager
from .command_class import Command
from .command_container import CommandContainer
from .lithil_client import LithilClient

bot_path = Path(__file__).parent.parent
client = LithilClient(bot_path)
command_container = client.command_container


def watcher(func=None, *, tick_rate,log: bool = False, name=None):
    def decorator(_func):
        client.watchers.append(Watcher(name, tick_rate, _func, client, log))
        return _func

    if func is None:
        return decorator
    else:
        return decorator(func)


from .watchers import *
