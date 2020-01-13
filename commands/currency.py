import discord

import internals.command_class as command_class
from internals.call import Call
from internals.lithil_client import LithilClient


class Currency(command_class.Command):
    @classmethod
    async def action(cls, call: Call, client: LithilClient):
        if call.args[0] == "list":
            currency_dict = client.bank.get_currency_as_dict()
            out = "Current standings:\n"
            for key, value in currency_dict.items():
                out += " %s : %s Papayas\n" % (
                    call.server.get_member(key),
                    value)

            return out
        if call.args[0] == "me":
            return client.bank.get_currency(call.caller)
        if call.args[0] == "store":
            client.bank.store_standings()
            return "storing..."

    callers = ["currency"]
