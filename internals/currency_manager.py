from __future__ import annotations

from typing import Dict
from discord import User, Message

import csv


class NotEnoughCurrencyException(Exception):
    pass


class CurrencyManager:
    database_path = r"F:\Lithil\data\papayas.csv"

    def __init__(self, config_dict: Dict):
        self.currency_name = config_dict["name"]
        self.currency_name_plural = config_dict["name_plural"]
        self.money_per_message = config_dict["money_per_message"]
        self._currency_dict: Dict[int, int] = {}

    def get_currency(self, user: User) -> int:
        return self._currency_dict[user.id]

    def set_currency(self, user: User, value: int):
        self._currency_dict[user.id] = value
        self.store_standings()

    def add_currency(self, user: User, value: int):
        self.set_currency(user, self.get_currency(user) + value)

    def remove_currency(self, user: User, value: int):
        if self.get_currency(user) < value:
            raise NotEnoughCurrencyException
        else:
            self.set_currency(user, self.get_currency(user)-value)

    def register_user(self, user: User):
        self._currency_dict[user.id] = 0

    def status_report(self):
        return self._currency_dict

    def store_standings(self) -> None:
        with open(self.database_path, "w+") as file:
            w = csv.DictWriter(file, self._currency_dict.keys())
            w.writeheader()
            w.writerow(self._currency_dict)

    async def on_message(self, message: Message) -> None:
        self.add_currency(message.author, self.money_per_message)


