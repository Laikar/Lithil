import asyncio
import signal
from pathlib import Path

import internals

current_path = Path(__file__).parent
print(current_path.absolute())
lithil_client: internals.LithilClient = internals.LithilClient(current_path)
loop = lithil_client.loop


async def runner():
    try:
        await lithil_client.start(lithil_client.token)
    finally:
        await lithil_client.close()


future = asyncio.ensure_future(runner(), loop=loop)
future.add_done_callback(lithil_client.loop.stop)
try:
    loop.run_forever()
except KeyboardInterrupt:
    print('Received signal to terminate bot and event loop.')
finally:
    future.remove_done_callback(lithil_client.loop.stop)
