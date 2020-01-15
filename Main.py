from pathlib import Path

import internals

current_path = Path(__file__).parent
print(current_path.absolute())
lithil_client: internals.LithilClient = internals.LithilClient(current_path)
lithil_client.run(lithil_client.token)

