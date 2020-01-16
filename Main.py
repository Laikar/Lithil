from pathlib import Path
import internals

current_path = Path(__file__).parent
lithil_client: internals.LithilClient = internals.LithilClient(current_path)
lithil_client.run_bot()
