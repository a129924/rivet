"""Pure synthetic reproduction; no App, assets, Security or actual clock arm."""
from pathlib import Path
import io, json, sys
from unittest import mock
# Invoke from the feature repository root; test fixture always uses synthetic=True.
sys.path.insert(0, str(Path("experiments/E008/Tests").resolve()))
from test_bootstrap import BootstrapTests
import continuity as c, proof
f = BootstrapTests(); f.setUp()
try:
    f.begin(); original_context = c.Bootstrap; original_exclusive = proof.exclusive
    def fail_final_index(root, relative, value):
        if relative == "index.json": raise OSError("synthetic final index export failure")
        return original_exclusive(root, relative, value)
    failed = False
    with mock.patch.object(c, "Bootstrap", side_effect=lambda root, clock: original_context(root, True, f.clock)), mock.patch.object(proof, "exclusive", side_effect=fail_final_index), mock.patch.object(proof, "LiveBackend") as executor, mock.patch.object(proof, "command") as command, mock.patch.object(proof.subprocess, "Popen") as launch, mock.patch.object(sys, "argv", ["continuity.py", "--live", "--root", str(f.root), "--stop-setup"]), mock.patch("sys.stdout", new_callable=io.StringIO):
        try: c.main()
        except OSError: failed = True
        executor.assert_not_called(); command.assert_not_called(); launch.assert_not_called()
    archive = next(f.out.glob("setup-stop-*"))
    retained = f.root.exists(); indexed = (archive / "pre-cleanup.index.json").exists()
    result = {"synthetic": True, "actualDriver": "--stop-setup", "injectedFinalIndexExportFailure": failed, "privateRootRetained": retained, "durablePreCleanupIndexExists": indexed, "finalIndexExists": (archive / "index.json").exists(), "cleanupMachineExists": (archive / "cleanup.machine.json").exists(), "externalCommandOrAppLaunch": False}
    print(json.dumps(result, sort_keys=True))
    # Safe failure needs retained private recovery or an already durable audit index.
    status = 0 if failed and (retained or indexed) else 1
finally:
    f.doCleanups()
sys.exit(status)
