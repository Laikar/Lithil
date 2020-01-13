import csv
from pathlib import Path
from typing import Dict, Any, AnyStr


class DataIO:
    def __init__(self, data_path: Path):
        if not data_path.exists():
            data_path.mkdir()

    @classmethod
    def store_dict_as_csv(cls, file: Path, data: Dict[AnyStr, Any]):
        if not file.exists():
            file.touch()
        with file.open("w+") as file_io:
            fieldnames = ['key', 'value']
            w = csv.DictWriter(file_io, fieldnames=fieldnames)
            w.writeheader()
            for key, value in data.items():
                w.writerow({'key': key, 'value': value})

    @classmethod
    def read_csv_as_dict(cls, file : Path):
        out = {}
        with file.open("r+") as openfile:
            csv_reader = csv.DictReader(openfile)
            for row in csv_reader:
                out[int(row["key"])] = int(row["value"])
        return out

