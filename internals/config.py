from pathlib import Path
from typing import Dict, AnyStr, List

import yaml
import shutil


class Config:

    def __init__(self, config_path: Path):
        self.config_path: Path = config_path
        self.config_file: Path = config_path / "config.yml"
        self.sample_config_file = config_path / "config.yml.sample"
        self.config_dict = self.load_config()

    def load_config(self) -> Dict:
        if not self.config_file.exists():
            self.create_config_from_sample()
        return yaml.load(self.config_file.read_text(), yaml.FullLoader)

    def create_config_from_sample(self):
        shutil.copy(str(self.sample_config_file), str(self.config_file))

    def __getitem__(self, item):
        return self.config_dict[item]

