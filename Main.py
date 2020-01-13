import asyncio
from pathlib import Path

import internals

lithil_client: internals.LithilClient = internals.LithilClient(Path())
lithil_client.run(lithil_client.token)