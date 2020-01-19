from typing import TYPE_CHECKING, AnyStr

from internals import Command

if TYPE_CHECKING:
    from internals import LithilClient, Call


class Help(Command):

    @classmethod
    async def action(cls, call: 'Call', client: 'LithilClient') -> str:
        out: AnyStr = ""
        if len(call.args) == 0:
            out = """Lista de comandos:\n"""
            for key, value in client.command_container.command_dictionary.items():
                additional_names = ""
                if len(value.callers) != 1:
                    cmd_name = "*{}*".format(value.name)
                    additional_names = "**__, __**".join(value.callers)
                    additional_names = "(__**{}**__)".format(additional_names)
                else:
                    cmd_name = "__**{}**__".format(value.callers[0])

                out += "{0}{1}, ".format(cmd_name, additional_names)
        elif len(call.args) == 1 and call.args[0] in client.command_container.caller_dictionary.keys():
            out = client.command_container.caller_dictionary[call.args[0]].help
        else:

            out = "No tengo ningun comando con ese nombre, si deberia, quejate a bano"
        return out
    callers = ['help']
    help = """Este comando te ayuda a entender otros comandos"""
