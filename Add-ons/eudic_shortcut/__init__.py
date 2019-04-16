import time
from functools import partial
from subprocess import check_call as _call, CalledProcessError

from aqt import mw
from aqt.reviewer import Reviewer
from aqt.utils import showInfo
from anki.hooks import wrap
from aqt.qt import Qt


config = mw.addonManager.getConfig(__name__)
ENTRY_FIELD = config['ENTRY_FIELD']
ENTRY_FIELDS = ENTRY_FIELD.split(',') if ENTRY_FIELD else []
EUDIC_BUNDLE_ID = config['EUDIC_BUNDLE_ID']
EUDIC_PROCESS_NAME = config['EUDIC_PROCESS_NAME']


def look_up_in_eudic(self):
    if self.mw.state != "review":
        return
    if self.state != "answer":
        return
    call = partial(_call, shell=True)
    try:
        call('pgrep -i %s' % EUDIC_PROCESS_NAME)
    except CalledProcessError:
        # Have to open twice. May be eudic's bug
        call("open -b '%s'" % EUDIC_BUNDLE_ID)
        call("open -b '%s'" % EUDIC_BUNDLE_ID)
    note = self.card.note()
    entries = [note[k] for k in ENTRY_FIELDS if k in note]
    if not entries:
        return showInfo('Please set ENTRY_FIELD in Config.')
    scpt = 'tell application id "%s" to show dic with word "%s"' % (EUDIC_BUNDLE_ID, entries[0])
    call("osascript -e '%s'" % scpt)


def shortcutKeys(self):
    return [
        ("e", self.mw.onEditCurrent),
        (" ", self.onEnterKey),
        (Qt.Key_Return, self.onEnterKey),
        (Qt.Key_Enter, self.onEnterKey),
        ("r", self.replayAudio),
        (Qt.Key_F5, self.replayAudio),
        ("Ctrl+1", lambda: self.setFlag(1)),
        ("Ctrl+2", lambda: self.setFlag(2)),
        ("Ctrl+3", lambda: self.setFlag(3)),
        ("Ctrl+4", lambda: self.setFlag(4)),
        ("*", self.onMark),
        ("=", self.onBuryNote),
        ("-", self.onBuryCard),
        ("!", self.onSuspend),
        ("@", self.onSuspendCard),
        ("Ctrl+Delete", self.onDelete),
        ("v", self.onReplayRecorded),
        ("Shift+v", self.onRecordVoice),
        ("o", self.onOptions),
        ("1", lambda: self._answerCard(1)),
        ("2", lambda: self._answerCard(2)),
        ("3", lambda: self._answerCard(3)),
        ("4", lambda: self._answerCard(4)),
        ("l", lambda: look_up_in_eudic(self)),
    ]


Reviewer._shortcutKeys = wrap(Reviewer._shortcutKeys, shortcutKeys)
