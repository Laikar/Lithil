from __future__ import annotations

from typing import Dict, TYPE_CHECKING, List
from discord import User, Message, Guild, Member, Emoji, TextChannel

if TYPE_CHECKING:
    from internals import LithilClient
from internals import ChannelManager

import csv


class NotEnoughCurrencyException(Exception):
    pass


class CurrencyManager:

    def __init__(self, client: 'LithilClient', config_dict: Dict):
        # Variable Initialization
        self.client = client
        self.currency_name = config_dict["name"]
        self.currency_name_plural = config_dict["name_plural"]
        self.money_per_message = config_dict["money_per_message"]
        self.money_per_minute_on_voice = config_dict["money_per_minute_on_voice"]
        self.data_file = self.client.data_path / (self.currency_name + ".csv")
        self.ranking_messages: List['Message'] = []
        self.ranking_channels: List['TextChannel'] = []
        self._currency_dict: Dict[int, int] = {}
        self.ranking_update_pending: bool = False
        self.ranking_channel_ids: List[int] = []

        for channel_id in config_dict['ranking_channels']:
            self.ranking_channel_ids.append(channel_id)
        self.load_standings()
        # Register events
        self.client.on_ready_events.append(self.on_ready)
        self.client.on_message_events.append(self.on_message)
        self.client.on_close_events.append(self.on_close)

    def get_currency(self, user: User) -> int:
        try:
            return self._currency_dict[user.id]
        except KeyError:
            self._currency_dict[user.id] = 0
            return 0

    def set_currency(self, user: User, value: int, store: bool = True):
        self._currency_dict[user.id] = value
        if store:
            self.store_standings()
        self.ranking_update_pending = True

    def add_currency(self, user: User, value: int, store: bool = True):
        self.set_currency(user, self.get_currency(user) + value, store, )

    def remove_currency(self, user: User, value: int, store: bool = True):
        if self.get_currency(user) < value:
            raise NotEnoughCurrencyException
        else:
            self.set_currency(user, self.get_currency(user) - value, store, )

    def get_currency_as_dict(self):
        return self._currency_dict

    def store_standings(self) -> None:
        self.client.data_manager.store_dict_as_csv(self.data_file, self._currency_dict)

    def load_standings(self):
        self._currency_dict = self.client.data_manager.read_csv_as_dict(self.data_file)

    async def update_rankings(self):
        for message in self.ranking_messages:
            await message.edit(content=self.get_ranking_message())
        self.ranking_update_pending = False

    def sort_users_by_ranking(self, users: List[User]) -> List[User]:
        def sorter(user: User):
            return self.get_currency(user)
        users.sort(reverse=True, key=sorter)

    def get_ranking_message(self) -> str:
        out: str = "__**Ranking de gente con mas papayas:**__\n"
        user_ids = self.get_currency_as_dict().keys()
        users: List[User] = []
        for user_id in user_ids:
            users.append(self.client.get_user(user_id))
        self.sort_users_by_ranking(users)
        for i in range(len(users)):
            out += "{0} - {1} {2} {3}\n" \
                .format(i + 1,
                        users[i].mention,
                        self.get_currency(users[i]),
                        self.currency_name_plural)
        return out

    async def make_ranking_channel(self, channel: TextChannel = None):
        ranking_message = self.get_ranking_message()
        ranking_channel = await ChannelManager.make_info_channel(channel, ranking_message)
        self.ranking_messages.append(ranking_channel)

    # region Events
    async def on_close(self):
        self.store_standings()

    async def on_message(self, message: Message) -> None:
        self.add_currency(message.author, self.money_per_message)

    async def on_ready(self):
        for channel_id in self.ranking_channel_ids:
            channel = self.client.get_channel(channel_id)
            self.ranking_channels.append(channel)
            await self.make_ranking_channel(channel)


    # endregion
