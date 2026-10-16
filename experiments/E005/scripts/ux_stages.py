"""Bounded, immutable UX checkpoints. Human observations are separate evidence."""
import datetime
import hashlib
import json
from pathlib import Path
import time


def utc_now():
    return datetime.datetime.now(datetime.timezone.utc)


def exclusive_json(path, value):
    with Path(path).open('x') as stream:
        stream.write(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


class UXStages:
    def __init__(self, namespace, evidence, control, deadline, human_only=False):
        self.human_only = human_only
        self.observation_mode = "human-only" if human_only else "native-desktop"
        self.namespace = namespace
        self.evidence, self.control = Path(evidence), Path(control)
        self.deadline = deadline
        self.evidence.mkdir(parents=True, exist_ok=False)
        self.control.mkdir(parents=True, exist_ok=False)
        self.receipts = {}

    def complete(self, phase, payload):
        value = {'namespace': self.namespace, 'phase': phase, 'promptCount': None,
                 'observationMode': self.observation_mode, 'desktopConnectionRequired': not self.human_only,
                 'promptObservation': 'Human sidecar required', **payload}
        path = self.evidence / f'phase-{phase}.machine.json'
        exclusive_json(path, value)
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        self.receipts[phase] = {'file': path.name, 'sha256': digest}
        return digest

    def wait_ready(self, phase):
        previous = self.receipts[phase - 1]
        exclusive_json(self.control / f'notice-{phase}.json', {
            'namespace': self.namespace, 'phase': phase, 'previousReceiptSHA256': previous['sha256'],
            'recordedUTC': utc_now().isoformat(), 'state': 'awaitingPreviousObservationAndThisPhaseReady'})
        gate = self.control / f'gate-{phase}.json'
        print(f'UX phase {phase}: paused for previous observation and fresh ready', flush=True)
        while not gate.exists():
            if utc_now() >= self.deadline:
                raise RuntimeError('uxPhaseDeadlineReached')
            if (self.control / 'abort.json').exists():
                raise RuntimeError('uxHumanAbort')
            time.sleep(0.25)
        if utc_now() >= self.deadline:
            raise RuntimeError('uxPhaseDeadlineReached')
        if (self.control / 'abort.json').exists():
            raise RuntimeError('uxHumanAbort')
        if hashlib.sha256((self.evidence / previous['file']).read_bytes()).hexdigest() != previous['sha256']:
            raise RuntimeError('uxMachineReceiptChanged')
        value = json.loads(gate.read_text())
        mode = value.get('observationMode', 'native-desktop')
        connection_valid = (mode == 'human-only' and (value.get('desktopConnected') is False or value.get('desktopConnected') is None)) if self.human_only else (mode == 'native-desktop' and value.get('desktopConnected') is True)
        if (value.get('namespace') != self.namespace or value.get('phase') != phase or
                value.get('previousReceiptSHA256') != previous['sha256'] or
                value.get('humanReady') is not True or not connection_valid or
                not value.get('humanReadyStatement')):
            raise RuntimeError('uxGateMismatchOrNotReady')
        path = self.evidence / f'phase-{phase - 1}.human.json'
        if not path.exists():
            raise RuntimeError('uxPreviousHumanObservationMissing')
        human = json.loads(path.read_text())
        count = human.get('promptCount')
        if human.get('observationMode', 'native-desktop') != self.observation_mode:
            raise RuntimeError('uxHumanObservationModeMismatch')
        if (human.get('namespace') != self.namespace or human.get('phase') != phase - 1 or
                human.get('machineReceiptSHA256') != previous['sha256'] or
                human.get('observedWholeStage') is not True or human.get('phaseIdentified') is not True or
                type(count) is not int or count < 0 or not isinstance(human.get('actions'), list) or
                not isinstance(human.get('purposes'), list) or
                len(human['actions']) != count or len(human['purposes']) != count or
                any(not isinstance(item, str) or not item.strip() for item in human['actions'] + human['purposes'])):
            raise RuntimeError('uxPreviousHumanObservationIncompleteOrMismatch')
        print(f'UX phase {phase}: ready accepted', flush=True)
        return value
