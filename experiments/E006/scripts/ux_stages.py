"""E006 local cooperation protocol; pure parsing, no Security or app launch."""
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import stat
import time
import uuid


class Rejected(Exception):
    """Finite classification only; no raw subprocess output or identifiers."""


def now_utc():
    return dt.datetime.now(dt.timezone.utc)


def timestamp(value):
    try:
        parsed = dt.datetime.fromisoformat(value.replace('Z', '+00:00'))
        if parsed.tzinfo is None:
            raise ValueError()
        return parsed.astimezone(dt.timezone.utc)
    except (ValueError, TypeError, AttributeError):
        raise Rejected('invalidTime') from None


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def safe_path(root, relative):
    root = Path(root)
    candidate = root / relative
    if Path(relative).is_absolute() or '..' in Path(relative).parts:
        raise Rejected('unsafePath')
    current = root
    for part in Path(relative).parts:
        current = current / part
        if current.is_symlink():
            raise Rejected('symlinkRejected')
    if root.is_symlink() or not root.is_dir() or root.stat().st_uid != os.getuid():
        raise Rejected('scratchOwnershipRejected')
    if not candidate.resolve().is_relative_to(root.resolve()):
        raise Rejected('unsafePath')
    return candidate


def private_root(root, namespace):
    try:
        if str(uuid.UUID(namespace)) != namespace:
            raise ValueError()
    except (ValueError, AttributeError):
        raise Rejected('namespaceRejected') from None
    root = Path(root)
    if root.name != 'rivet-E006-' + namespace:
        raise Rejected('scratchNameRejected')
    safe_path(root, '.')
    if stat.S_IMODE(root.stat().st_mode) != 0o700:
        raise Rejected('scratchPermissionsRejected')
    return root


def exclusive_json(path, value):
    path = Path(path)
    try:
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    except FileExistsError:
        raise Rejected('receiptAlreadyExists') from None
    with os.fdopen(fd, 'w') as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2, sort_keys=True)
        stream.write('\n')


def read_json(root, relative):
    return json.loads(safe_path(root, relative).read_text())



def load_window(root, namespace, now):
    """Read exclusive setup t0; never derive a new measurement start here."""
    private_root(root, namespace)
    try:
        raw=safe_path(root,'window.json').read_bytes()
        value=json.loads(raw)
    except (OSError,ValueError):
        raise Rejected('setupWindowMissingOrInvalid') from None
    if (value.get('namespace')!=namespace or value.get('kind')!='setup-window' or
            value.get('observationMode')!='human-only' or value.get('synthetic') is not False or
            not isinstance(value.get('humanReadyStatement'),str) or not value['humanReadyStatement'].strip()):
        raise Rejected('setupWindowRejected')
    start=timestamp(value.get('startUTC'))
    cutoff=timestamp(value.get('cutoffUTC'))
    deadline=timestamp(value.get('deadlineUTC'))
    if (start>now or now>=cutoff or cutoff-start!=dt.timedelta(minutes=25) or
            deadline-start!=dt.timedelta(minutes=30)):
        raise Rejected('setupWindowFutureOrExpired')
    return value, hashlib.sha256(raw).hexdigest()

def validate_observation(human, machine, namespace, phase):
    count = human.get('promptCount')
    if (human.get('namespace') != namespace or type(human.get('phase')) is not int or human.get('phase') != phase or
            human.get('observationMode') != 'human-only' or human.get('synthetic', False) is not False or
            human.get('machineReceiptSHA256') != sha256(machine) or
            human.get('wholeStageObserved') is not True or human.get('phaseIdentified') is not True or
            type(count) is not int or count < 0 or human.get('desktopConnected') is True):
        raise Rejected('humanObservationRejected')
    for key in ('actions', 'purposes'):
        values = human.get(key)
        if (not isinstance(values, list) or len(values) != count or
                any(not isinstance(value, str) or not value.strip() for value in values)):
            raise Rejected('humanObservationRejected')


def validate_gate(gate, human, machine, namespace, phase, phase_completed, now):
    if (gate.get('namespace') != namespace or type(gate.get('phase')) is not int or gate.get('phase') != phase or
            gate.get('observationMode') != 'human-only' or gate.get('synthetic', False) is not False or
            gate.get('previousReceiptSHA256') != sha256(machine) or gate.get('humanReady') is not True or
            gate.get('desktopConnected') is True or
            not isinstance(gate.get('humanReadyStatement'), str) or not gate['humanReadyStatement'].strip()):
        raise Rejected('humanReadyRejected')
    ready = timestamp(gate.get('recordedUTC'))
    if ready < phase_completed or ready > now:
        raise Rejected('staleReadyRejected')
    validate_observation(human, machine, namespace, phase - 1)


def public_receipt(raw):
    # Intentionally cannot serialize caller diagnostics, private proof or payload.
    safe = {}
    for key in ('namespace', 'phase', 'startedUTC', 'endedUTC', 'executableSHA256',
                'proofSHA256', 'observationMode', 'synthetic', 'operation',
                'completed', 'absent', 'cleanupComplete', 'recoveryRequired',
                'status', 'promptCount', 'cleanup', 'sourceSHA256'):
        if key in raw:
            safe[key] = raw[key]
    if 'error' in raw:
        allowed = {'missing', 'invalidData', 'comparison', 'accessDenied', 'securityFailure',
                   'interactionUnavailable', 'guardRejected', 'profileRejected', 'probeFailure',
                   'controlledStop', 'cleanupIncomplete'}
        safe['error'] = raw['error'] if raw['error'] in allowed else 'guardRejected'
    if 'fields' in raw:
        names = {'accessToken', 'refreshToken', 'accessTokenExpiresAt',
                 'refreshTokenExpiresAt', 'tokenType', 'grantedScopes'}
        safe['fields'] = {k: v for k, v in raw['fields'].items() if k in names and type(v) is bool}
    return safe


class UXStages:
    def __init__(self, root, manifest, clock=now_utc, pause=time.sleep):
        self.root = private_root(root, manifest['namespace'])
        self.manifest, self.clock, self.pause = manifest, clock, pause

    def wait_ready(self, phase):
        previous = safe_path(self.root, f'receipts/phase-{phase-1}.machine.json')
        previous_data = json.loads(previous.read_text())
        notice = {'namespace': self.manifest['namespace'], 'phase': phase,
                  'previousReceiptSHA256': sha256(previous), 'recordedUTC': self.clock().isoformat(),
                  'state': 'waitingForHumanObservationAndFreshReady', 'observationMode': 'human-only'}
        exclusive_json(safe_path(self.root, f'control/notice-{phase}.json'), notice)
        gate = safe_path(self.root, f'control/gate-{phase}.json')
        while not gate.exists():
            self.guard_time(phase)
            self.pause(.25)
        self.guard_time(phase)
        validate_gate(json.loads(gate.read_text()), read_json(self.root, f'receipts/phase-{phase-1}.human.json'),
                      previous, self.manifest['namespace'], phase,
                      timestamp(previous_data['endedUTC']), self.clock())

    def guard_time(self, phase):
        if safe_path(self.root, 'control/abort.json').exists():
            raise Rejected('humanAbort')
        limit = self.manifest['cutoffUTC'] if phase < 4 else self.manifest['deadlineUTC']
        if self.clock() >= timestamp(limit):
            raise Rejected('measurementDeadline')
