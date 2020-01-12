from internals import Call
from discord import Client, TextChannel

from abc import ABC, abstractmethod


class Command(ABC):
    @classmethod
    async def called(cls, call: Call, client: Client):
        with cls.output_channel(call).typing():
            cls.log(call, client)
            reply = await cls.action(call=call, client=client)
        await cls.respond(reply, call)

    @classmethod
    @abstractmethod
    async def action(cls, call: Call, client: Client) -> str:
        return "La respuesta de este comando no esta bien hecha"

    @classmethod
    async def respond(cls, reply, call: Call):
        await cls.output_channel(call).send(reply)

    async def delete(self, call: Call, client: Client):
        await call.message.delete(delay=10)

    help = "Bano es medio tonto y se ha olvidado de añadir ayuda para este comando, quejate a el"
    callers = [""]

    @classmethod
    def output_channel(cls, call: Call) -> TextChannel:
        return call.channel

    @classmethod
    def log(cls, call: Call, client: Client):
        print("Call for command %s made by %s" % (call.command, call.caller))
