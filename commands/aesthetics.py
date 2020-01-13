from discord import Client

from internals import Command, Call


class Aesthetics(Command):
    @classmethod
    def get_help_str(cls, call: Call, client: Client) -> str:
        return cls.help

    help = """Este comando convierte un texto en algo 
       :regional_indicator_e: :regional_indicator_s: :regional_indicator_t: :regional_indicator_e: :regional_indicator_t: :regional_indicator_i: :regional_indicator_c: :regional_indicator_o:
       lo uso principalmente para probar que los bots funcionan
       uso: _aesthetic [texto]"""
    callers = ["aesthetic", "asd"]
    should_delete_caller = True

    @classmethod
    async def action(cls, call: Call, client: Client) -> str:
        out: str = ""
        raw = call.beheaded_content
        for char in raw:
            char: str = char.lower()
            if (char in ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's',
                         't', 'u', 'v', 'w', 'x', 'y', 'z']):
                out += ":regional_indicator_%c: " % char
            if char in ['1', '2', '3', '4', '5', '6', '7', '8', '9']:
                numberdict = {'1': ':one:', '2': ':two:', '3': ':three:', '4': ':four:', '5': ':five:', '6': ':sic:',
                              '7': ':seven:', '8': ':eight:', '9': ':nine:'}
                out += "%s " % numberdict[char]
            if char == ' ':
                out += '   '
        return out
