from __future__ import annotations

from typing import Dict, TYPE_CHECKING
from discord import User, Message, Guild, Member
if TYPE_CHECKING:
    from internals import LithilClient

import csv


class NotEnoughCurrencyException(Exception):
    pass


class CurrencyManager:

    def __init__(self, client: LithilClient, config_dict: Dict):
        self.client = client
        self.currency_name = config_dict["name"]
        self.currency_name_plural = config_dict["name_plural"]
        self.money_per_message = config_dict["money_per_message"]
        self.money_per_minute_on_voice = config_dict["money_per_minute_on_voice"]
        self._currency_dict: Dict[int, int] = {}
        self.data_file = self.client.data_path / (self.currency_name + ".csv")
        self._currency_dict = self.client.data_manager.read_csv_as_dict(self.data_file)
        self.client.on_message_events.append(self.on_message)

    def get_currency(self, user: User) -> int:
        try:
            return self._currency_dict[user.id]
        except KeyError:
            self._currency_dict[user.id] = 0
            return 0

    def set_currency(self, user: User, value: int):
        self._currency_dict[user.id] = value
        self.store_standings()

    def add_currency(self, user: User, value: int):
        self.set_currency(user, self.get_currency(user) + value)

    def remove_currency(self, user: User, value: int):
        if self.get_currency(user) < value:
            raise NotEnoughCurrencyException
        else:
            self.set_currency(user, self.get_currency(user) - value)

    def register_user(self, user: User):
        self.set_currency(user, 0)

    def get_currency_as_dict(self):
        return self._currency_dict

    def store_standings(self) -> None:
        self.client.data_manager.store_dict_as_csv(self.data_file, self._currency_dict)

    async def on_message(self, message: Message) -> None:
        self.add_currency(message.author, self.money_per_message)
