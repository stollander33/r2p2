"""
Start services for the current configuration
"""
import time
from typing import List

import typer

from controller import log
from controller.app import Application, Configuration
from controller import (
    BACKUP_DIR,
    DATA_DIR,
    LOGS_FOLDER,
    PROJECT_DIR,
    SUBMODULES_DIR,
    log,
    print_and_exit,
)

@Application.app.command(help="Start API to work with R2D2")
def api(
    force: bool = typer.Option(
        False,
        "--force",
        "-f",
        help="Force API restart",
        show_default=False,
    ),
) -> None:


    log.info(F"Start API in {SUBMODULES_DIR}")
