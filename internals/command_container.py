from __future__ import annotations

import importlib
import inspect
from pathlib import Path
from typing import Dict

from discord import Client

from internals import Call, Command


class CommandContainer:
    def __init__(self, command_path: Path):
        self.command_dictionary: Dict[str, Command] = {}
        self.caller_dictionary: Dict[str, str] = {}
        dirlist = [command_path]
        for x in command_path.iterdir():
            if x.is_dir() and not x.name.startswith("__"):
                dirlist.append(x)
        for folder in dirlist:
            filelist = list(folder.glob("*.py"))
            for file in filelist:
                if not file.name.startswith("__"):
                    module_name = ".%s" % file.name.replace(".py", "")
                    if folder is command_path:
                        package_name = command_path.name
                    else:
                        package_name = "%s.%s" % (command_path.name, folder.name)

                    command_module = importlib.import_module(module_name, package_name)
                    commands_in_module = [m[1] for m in inspect.getmembers(command_module, inspect.isclass)
                                          if m[1].__module__ == command_module.__name__ and issubclass(m[1], Command)]
                    command: Command
                    for command in commands_in_module:
                        command_name = command.__class__.__name__
                        self.command_dictionary[command_name] = command
                        for caller in command.callers:
                            self.caller_dictionary[caller] = command_name

    async def call_command(self, call: Call, client: Client):
        called_command = self.caller_dictionary[call.command]
        await self.command_dictionary[called_command].called(call, client)
