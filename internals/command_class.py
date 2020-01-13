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
        if cls.should_delete_caller:
            await cls.delete(call, client)

    @classmethod
    @abstractmethod
    async def action(cls, call: Call, client: Client) -> str:
        return "La respuesta de este comando no esta bien hecha"

    @classmethod
    @abstractmethod
    def get_help_str(cls, call: Call, client: Client) -> str:
        pass

    @classmethod
    async def respond(cls, reply, call: Call):
        await cls.output_channel(call).send(reply)

    @classmethod
    async def delete(cls, call: Call, client: Client):
        await call.message.delete(delay=1)

    help = "Bano es medio tonto y se ha olvidado de añadir ayuda para este comando, quejate a el"
    callers = [""]
    should_delete_caller = False

    @classmethod
    def output_channel(cls, call: Call) -> TextChannel:
        return call.channel

    @classmethod
    def log(cls, call: Call, client: Client):
        print("Call for command %s made by %s" % (call.command, call.author))
