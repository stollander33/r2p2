"""
This module will test all the combinations of the create command.
Other tests that will create projects will assume the command fully working
and will only use the specific configuration needed by the test itself
"""

import os
from pathlib import Path
from typing import List

import pytest

from controller.templating import Templating
from tests import Capture, TemporaryRemovePath, exec_command, init_project


def test_create(capfd: Capture) -> None:

    exec_command(
        capfd,
        "create first",
        "Missing option",
    )

    exec_command(
        capfd,
        "create first --auth xyz",
        "Invalid value for",
    )

    exec_command(
        capfd,
        "create first --auth postgres",
        "Missing option",
    )

    exec_command(
        capfd,
        "create first --auth postgres --frontend xyz",
        "Invalid value for",
    )

    exec_command(
        capfd,
        "create first --auth postgres --frontend angular",
        "Current folder is not empty, cannot create a new project here.",
        "Found: ",
        "Use --current to force the creation here",
    )

    with open("data/logs/rapydo-controller.log") as f:
        logs = f.read().splitlines()
        assert logs[-1].endswith("Use --current to force the creation here")

    # Please note that --current is required because data folder is already created
    # to be able to tests logs

    # Expected at least two characters for project name
    exec_command(
        capfd,
        "create a --auth postgres --frontend angular --current",
        "Wrong project name, expected at least two characters",
    )

    exec_command(
        capfd,
        "create test_celery --auth postgres --frontend angular --current",
        "Wrong project name, found invalid characters: _",
    )

    exec_command(
        capfd,
        "create test-celery --auth postgres --frontend angular --current",
        "Wrong project name, found invalid characters: -",
    )

    exec_command(
        capfd,
        "create testCelery --auth postgres --frontend angular --current",
        "Wrong project name, found invalid characters: C",
    )

    # Numbers are not allowed as first characters
    exec_command(
        capfd,
        "create 2testcelery --auth postgres --frontend angular --current",
        "Wrong project name, found invalid characters: 2",
    )

    # Numbers are allowed if not leading
    exec_command(
        capfd,
        "create test_Celery-2 --auth postgres --frontend angular --current",
        # Invalid characters in output are ordered
        "Wrong project name, found invalid characters: -C_",
    )

    exec_command(
        capfd,
        "create first --auth postgres --frontend angular --no-auto --current",
        "mkdir -p projects",
    )

    exec_command(
        capfd,
        "create first --auth postgres --frontend no --env X --current",
        "Invalid env X, expected: K1=V1",
    )
    exec_command(
        capfd,
        "create first --auth postgres --frontend no --env X, --current",
        "Invalid env X,, expected: K1=V1",
    )
    exec_command(
        capfd,
        "create first --auth postgres --frontend no --env X=a,Y=b --current",
        "Invalid env X=a,Y=b, expected: K1=V1",
    )

    templating = Templating()
    with TemporaryRemovePath(Path(templating.template_dir)):
        exec_command(
            capfd,
            "create firsts --auth postgres --frontend no --current",
            "Template folder not found",
        )

    exec_command(
        capfd,
        "create celery --auth postgres --frontend angular --current",
        "You selected a reserved name, invalid project name: celery",
    )

    exec_command(
        capfd,
        "create first --auth postgres --frontend angular --current --service invalid",
        "Invalid value for",
    )

    create_command = "create first --auth postgres --frontend angular"
    create_command += " --service rabbit --service neo4j --add-optionals --current"
    create_command += " --origin-url https://your_remote_git/your_project.git"
    exec_command(
        capfd,
        create_command,
        "Project first successfully created",
    )

    pconf = "projects/first/project_configuration.yaml"
    os.remove(pconf)
    exec_command(
        capfd,
        "create first --auth postgres --frontend angular --current --no-auto",
        "Project folder already exists: projects/first/confs",
        f"{pconf}",
    )

    create_command = "create first --auth postgres --frontend angular"
    create_command += " --service rabbit --env RABBITMQ_PASSWORD=invalid£password"
    create_command += " --current --force"
    exec_command(
        capfd,
        create_command,
        "Project folder already exists: projects/first/confs",
        "Project first successfully created",
    )

    create_command = "create first --auth postgres --frontend angular"
    create_command += " --service rabbit --service neo4j"
    create_command += " --current --force"
    exec_command(
        capfd,
        create_command,
        "Project folder already exists: projects/first/confs",
        "Project first successfully created",
    )

    # this is the last version that is created
    create_command = "create first --auth postgres --frontend angular"
    create_command += " --service rabbit --service neo4j"
    create_command += " --current --force"
    create_command += " --env CUSTOMVAR1=mycustomvalue --env CUSTOMVAR2=mycustomvalue"
    exec_command(
        capfd,
        create_command,
        "Project folder already exists: projects/first/confs",
        f"A backup of {pconf} is saved as {pconf}.bak",
        "Project first successfully created",
    )

    exec_command(
        capfd,
        "create first --auth postgres --frontend angular --current",
        "Project folder already exists: projects/first/confs",
        f"Project file already exists: {pconf}",
        "Project first successfully created",
    )

    exec_command(
        capfd,
        "create first --auth postgres --frontend angular --no-auto --current",
        "Project folder already exists: projects/first/confs",
        f"Project file already exists: {pconf}",
        "Project first successfully created",
    )

    # Delete a raw file in no-auto mode (i.e. manual creation)
    favicon = "projects/first/frontend/assets/favicon/favicon.ico"
    os.remove(favicon)
    exec_command(
        capfd,
        "create first --auth postgres --frontend angular --no-auto --current",
        f"File is missing: {favicon}",
    )
    # here a single and valid project is created (not initialized)
    exec_command(
        capfd,
        "create first --auth postgres --frontend angular --current",
        "Project folder already exists: projects/first/confs",
        f"Project file already exists: {pconf}",
        "Project first successfully created",
    )

    # Test projects with no-authentication
    exec_command(
        capfd,
        "create noauth --auth no --frontend no --current",
        "Project noauth successfully created",
    )

    # Test extended projects

    # base project is --auth postgres --frontend angular
    # the ext one is --auth neo4j --frontend angular
    exec_command(
        capfd,
        "create base --auth neo4j --frontend no --current",
        "Project folder already exists: projects",
        "Project base successfully created",
    )

    exec_command(
        capfd,
        "create new --extend new --auth neo4j --frontend no --current",
        "A project cannot extend itself",
    )
    exec_command(
        capfd,
        "create new --extend doesnotexist --auth neo4j --frontend no --current",
        "Invalid extend value: project doesnotexist not found",
    )

    create_command = "create ext --extend base"
    create_command += " --auth neo4j --frontend angular"
    create_command += " --current --service rabbit"
    exec_command(
        capfd,
        create_command,
        "Project folder already exists: projects",
        "Project ext successfully created",
    )

    init_project(capfd, "-p ext", "--force")
    exec_command(
        capfd,
        "-p ext check -i main --no-git --no-builds",
        "Checks completed",
    )

    # Test Services Activation

    os.remove(".projectrc")

    """
    Convert this to a test with parametrize fixture

    @pytest.mark.parametrize("services, [
        (postgres,),
        (neo4j,),
        ...
    ])

    """
    # Test services activation from create --service
    services = [
        "postgres",
        "neo4j",
        "rabbit",
        "redis",
        "celery",
        "ftp",
    ]
    opt = "--frontend no --current --force"
    for service in services:

        if service == "postgres":
            auth = "postgres"
            serv_opt = ""
        elif service == "neo4j":
            auth = "neo4j"
            serv_opt = ""
        else:
            auth = "postgres"
            serv_opt = f"--service {service}"

        exec_command(
            capfd,
            f"create testservices {opt} --auth {auth} {serv_opt}",
            "Project testservices successfully created",
        )
        if service == "postgres":
            active_services = ["backend", "postgres"]
        elif service == "neo4j":
            active_services = ["backend", "neo4j"]
        elif service == "celery":
            active_services = [
                "backend",
                "celery",
                "celerybeat",
                "flower",
                "postgres",
                "redis",
            ]
        elif service == "rabbit":
            active_services = ["backend", "postgres", "rabbit"]
        elif service == "redis":
            active_services = ["backend", "postgres", "redis"]
        elif service == "ftp":
            active_services = ["backend", "ftp", "postgres"]
        else:  # pragma: no cover
            pytest.fail(f"Unrecognized service {service}")

        services_list = ", ".join(sorted(active_services))
        exec_command(
            capfd,
            "-p testservices check -i main --no-git --no-builds",
            f"Enabled services: {services_list}",
        )

    # Test Celery Activation

    opt = "--frontend no --current --force --auth neo4j"
    project_configuration = "projects/testcelery/project_configuration.yaml"

    def verify_celery_configuration(
        services_list: List[str], broker: str, backend: str
    ) -> None:

        services = "--service celery"
        if services_list:
            for service in services_list:
                services += f" --service {service}"

        exec_command(
            capfd,
            f"create testcelery {opt} {services}",
            "Project testcelery successfully created",
        )

        with open(project_configuration) as f:
            lines = f.readlines()
        assert next(x.strip() for x in lines if "CELERY_BROKER" in x).endswith(broker)
        assert next(x.strip() for x in lines if "CELERY_BACKEND" in x).endswith(backend)

    verify_celery_configuration([], "REDIS", "REDIS")
    verify_celery_configuration(["rabbit"], "RABBIT", "RABBIT")
    verify_celery_configuration(["redis"], "REDIS", "REDIS")
    verify_celery_configuration(["rabbit", "redis"], "RABBIT", "REDIS")
