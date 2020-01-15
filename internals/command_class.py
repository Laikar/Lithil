from typing import List

from enum import Enum
from internals import Call
from discord import Client, TextChannel, Member, Role

from abc import ABC, abstractmethod


class Command(ABC):
    class ExecutionType(Enum):
        PERMISSIVE = 0
        RESTRICTIVE = 1

    help = "Bano es medio tonto y se ha olvidado de añadir ayuda para este comando, quejate a el"
    permission_denied_message = "{} no puedes ejecutar este comando"
    callers = [""]
    should_delete_caller = False
    execution_type: ExecutionType = ExecutionType.PERMISSIVE
    allowed_users: List[Member] = []
    restricted_users: List[Member] = []

    @classmethod
    async def called(cls, call: Call, client: Client):
        cls.log(call, client)
        with cls.output_channel(call).typing():
            if cls.caller_can_execute(call, client):
                reply = await cls.action(call, client)
            else:
                reply = cls.get_denied_message(call, client)
        await cls.respond(reply, call)
        if cls.should_delete_caller:
            await cls.delete(call, client)

    @classmethod
    @abstractmethod
    async def action(cls, call: Call, client: Client) -> str:
        return "La respuesta de este comando no esta bien hecha"

    @classmethod
    def get_help_str(cls, call: Call, client: Client) -> str:
        return cls.help

    @classmethod
    def get_denied_message(cls, call: Call, client: Client) -> str:
        return cls.permission_denied_message.format(call.author.mention)

    @classmethod
    async def respond(cls, reply, call: Call):
        await cls.output_channel(call).send(reply)

    @classmethod
    async def delete(cls, call: Call, client: Client):
        await call.message.delete(delay=1)

    @classmethod
    def output_channel(cls, call: Call) -> TextChannel:
        return call.channel

    @classmethod
    def log(cls, call: Call, client: Client):
        print("Call for command %s made by %s" % (call.command, call.author))

    @classmethod
    def caller_can_execute(cls, call: Call, client: Client):
        if cls.execution_type == cls.ExecutionType.PERMISSIVE:
            return call.author not in cls.restricted_users
        elif cls.execution_type == cls.ExecutionType.RESTRICTIVE:
            return call.author in cls.allowed_users

