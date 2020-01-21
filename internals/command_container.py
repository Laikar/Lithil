from __future__ import annotations

import importlib
import inspect
from pathlib import Path
from typing import Dict, List, TYPE_CHECKING, AnyStr

from discord import Message

from internals import Command, Call

if TYPE_CHECKING:
    from internals import LithilClient


class CommandContainer:
    def __init__(self, config: Dict, command_path: Path, client: 'LithilClient'):
        self.client = client
        self.command_headers: List[AnyStr] = []
        self.command_dictionary: Dict[AnyStr, Command] = {}
        self.caller_dictionary: Dict[AnyStr, Command] = {}
        self.restricted_channel_ids: List[int] = config['restricted_channels']
        self.load_commands(command_path)
        for header in config['command_headers']:
            self.command_headers.append(header)

        self.client.on_message_events.append(self.on_message)

    async def call_command(self, call: 'Call', client: 'LithilClient'):
        called_command = self.caller_dictionary[call.command]
        await called_command.called(call, client)

    async def on_message(self, message: 'Message'):
        for header in self.command_headers:
            if message.content.startswith(header):
                call = Call(message, header)
                if call.command in self.caller_dictionary.keys():
                    await self.call_command(call, self.client)
                break

    def load_commands(self, command_path: Path):
        command_directories = [command_path]
        for x in command_path.iterdir():
            if x.is_dir() and not x.name.startswith("__"):
                command_directories.append(x)
        for folder in command_directories:
            command_files: List[Path] = list(folder.glob("*.py"))
            for file in command_files:
                if not file.name.startswith("__"):
                    module_name = ".%s" % file.name.replace(".py", "")
                    if folder is command_path:
                        package_name = command_path.name
                    else:
                        package_name = "%s.%s" % (command_path.name, folder.name)

                    command_module = importlib.import_module(module_name, package_name)
                    commands_in_module = [m[1] for m in inspect.getmembers(command_module, inspect.isclass)
                                          if m[1].__module__ == command_module.__name__ and issubclass(m[1], Command)]
                    for command in commands_in_module:
                        command.name = command.__name__
                        self.command_dictionary[command.name] = command
                        for caller in command.callers:
                            self.caller_dictionary[caller] = command
