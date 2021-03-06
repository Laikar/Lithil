from discord import TextChannel

from internals import Call, LithilClient, Command


class Currency(Command):
    @classmethod
    async def action(cls, call: Call, client: LithilClient) -> str:
        if call.args[0] == "list":
            currency_dict = client.bank.get_currency_as_dict()
            out = "Current standings:\n"
            for key, value in currency_dict.items():
                out += " %s : %s Papayas\n" % (
                    call.server.get_member(key),
                    value)

            return out
        elif call.args[0] == "me":
            return "{} Tienes {} {}".format(call.author.mention, client.bank.get_currency(call.author),
                                            client.bank.currency_name_plural)
        elif call.args[0] == "store":
            client.bank.store_standings()
            return "storing..."
        elif call.args[0] == "ranking":

            if len(client.bank.ranking_channels) != 0:
                out = "Puedes consultar el ranking en los siguientes canales"
                for channel in client.bank.ranking_channels:
                    channel: TextChannel
                    out += "{}, ".format(channel.mention)
            else:
                out = client.bank.get_ranking_message()
            return out

    callers = ["currency"]
