when not defined(JS):
  {.error: "nimedscript only works in JS".}

import jsffi

type
  single* = float32
  Sample* = single

  NormalizeFormatMode* = int

  PasteMode* {.pure.} = enum
    ## What to do with the old audio when pasting
    insert  ## Move the old audio to after the pasted audio
    replace ## Forget about the old audio and use the pasted audio instead
    mix     ## Play them both at the same time

  Region* {.pure, importc: "TRegion".} = object
    sampleStart* {.importc: "SampleStart".}, sampleEnd* {.importc: "SampleEnd".}: int
    name* {.importc: "Name".}, info* {.importc: "Info".}: cstring
    time* {.importc: "Time".}: single
    keyNum* {.importc: "KeyNum".}: int

  Sound* {.pure, importc: "TSample".} = object
    length* {.importc: "Length".}, numChans* {.importc: "NumChans".},
      sampleRate* {.importc: "Samplerate".}, regionCount* {.importc: "RegionCount".}: int

  Editor* {.pure, importc: "TEditor".} = object
    sound* {.importc: "Sample".}: Sound

  Input* {.pure, importc: "TInput".} = object
    defaultValue* {.importc: "DefaultValue".}, value* {.importc: "Value".}: float
    valueAsInt* {.importc: "ValueAsInt".}: int
    min* {.importc: "Min".}, max* {.importc: "Max".}: float

  ScriptDialog* {.pure, importc: "TScriptDialog".} = object

var
  CRLF* {.importc, nodecl.}: cstring
    ## \r\n convenience
  editor* {.importc: "Editor", nodecl.}: Editor
    ## Current Edison editor object
  editorSample* {.importc: "EditorSample", nodecl.}: Sound
    ## Sample currently in editor
  scriptPath* {.importc: "ScriptPath", nodecl.}: cstring
    ## Path of current script file

proc createScriptDialog*(title, description: cstring): ScriptDialog {.importc: "CreateScriptDialog".}
  ## Pops up a dialog in the editor with a title `title` and description `description`
  ## and returns it as an object
proc progressMsg*(msg: cstring; pos, total: int) {.importc: "ProgressMsg".}
  ## Shows a progress message `msg` with the progress bar being ``pos / total`` full
proc showMessage*(s: cstring) {.importc: "ShowMessage".}
  ## Shows a message `s` on screen

var
  nfNumChannels* {.importc.}: NormalizeFormatMode
  nfFormat* {.importc.}: NormalizeFormatMode
  nfSamplerate* {.importc.}: NormalizeFormatMode
  nfAll* {.importc.}: NormalizeFormatMode

using
  self: Region

proc newRegion*(): Region {.importcpp: "TRegion(@)", constructor.}
proc copy*(self, source: Region) {.importcpp: "#.Copy(@)".}

using
  self: Sound
  position, channel: int
  x1, x2: int
  vol: single

proc newSound*(): Sound {.importcpp: "TSample(@)", constructor.}
  ## Creates a new sample
proc getSampleAt*(self, position, channel): Sample {.importcpp: "#.GetSampleAt(@)".}
  ## Gets individual sample (frame) of sound sample `self` at `position` in `channel`
proc setSampleAt*(self, position, channel; value: Sample) {.importcpp: "#.SetSampleAt(@)".}
  ## Sets individual sample (frame) of sound sample `self` at `position` in `channel` to `value`

template eachChannel*(self; body) {.dirty.} =
  {.emit: ["var sound = ", self].}
  var sound {.importc, nodecl.}: Sound
  for chan {.noinit.} in 0 ..< sound.numChans:
    var samples {.nodecl.}: distinct int

    template `[]`(sample: type(samples), position): Sample =
      getSampleAt(sound, position, chan)

    template `[]=`(sample: type(samples), position; value: Sample) =
      setSampleAt(sound, position, chan, value)

    body

using self: Sound

proc center*(self, x1, x2) {.importcpp: "#.CenterFromTo(@)".}
  ## Centers audio between sample positions x1 and x2
proc normalize*(self, x1, x2, vol, onlyIfAbove = false): float {.importcpp: "#.NormalizeFromTo(@)".}
  ## Normalizes audio between sample positions x1 and x2
proc amp*(self, x1, x2, vol) {.importcpp: "#.AmpFromTo(@)".}
  ## Amplifies audio between sample positions x1 and x2 by volume vol
proc reverse*(self, x1, x2) {.importcpp: "#.ReverseFromTo(@)".}
  ## Reverses audio between sample positions x1 and x2
proc reversePolarity*(self, x1, x2) {.importcpp: "#.ReversePolarityFromTo(@)".}
  ## Reverses polarity of audio between x1 and x2
proc swapChannels*(self, x1, x2) {.importcpp: "#.SwapChannelsFromTo(@)".}
proc insertSilence*(self, x1, x2) {.importcpp: "#.InsertSilence(@)".}
proc silence*(self, x1, x2) {.importcpp: "#.SilenceFromTo(@)".}
proc noise*(self, x1, x2; mode = 1; vol = 1.0) {.importcpp: "#.NoiseFromTo(@)".}
proc sine*(self, x1, x2; freq, phase: float, vol = 1.0) {.importcpp: "#.SineFromTo(@)".}
proc paste*(self; aSound: Sound; x1, x2: int; mode = PasteMode.insert) {.importcpp: "#.PasteFromTo(@)".}
proc loadFromClipboard*(self) {.importcpp: "#.LoadFromClipboard(@)".}
proc delete*(self, x1, x2; copy = false) {.importcpp: "#.DeleteFromTo(@)".}
proc trim*(self, x1, x2) {.importcpp: "#.TrimFromTo(@)".}

proc msToSamples*(self; time: float): Sample {.importcpp: "#.MsToSamples(@)".}
proc samplesToMs*(self; time: Sample): float {.importcpp: "#.SamplesToMs(@)".}

proc loadFromFile*(self; filename: cstring) {.importcpp: "#.LoadFromFile(@)".}
proc loadFromFile_Ask*(self) {.importcpp: "#.LoadFromFile_Ask(@)".}
proc normalizeFormat*(self; source: Sound; mode: NormalizeFormatMode = nfAll) {.importcpp: "#.NormalizeFormat(@)".}
proc getRegion*(self; index: int): Region {.importcpp: "#.GetRegion(@)".}
proc addRegion*(self; name: cstring, sampleStart: int, sampleEnd = high(int)): int {.importcpp: "#.AddRegion(@)".}
proc deleteRegion*(self; index: int) {.importcpp: "#.DeleteRegion(@)".}

using self: Editor

proc getSelectionInSamples*(self; x1, x2: int): bool {.importcpp: "#.GetSelectionS(@)".}
proc getSelectionInMilliseconds*(self; x1, x2: float): bool {.importcpp: "#.GetSelectionMS(@)".}

using self: ScriptDialog

proc newScriptDialog*(): ScriptDialog {.importcpp: "TScriptDialog(@)", constructor}
proc addInput*(self; name: cstring, value: float): Input {.importcpp: "#.AddInput(@)".}
proc addInputKnob*(self; name: cstring, value, min, max: float): Input {.importcpp: "#.AddInputKnob(@)".}
proc addInputCombo*(self; name, valueList: cstring, value: int): Input {.importcpp: "#.AddInputCombo(@)".}
proc getInput*(self; name: cstring): Input {.importcpp: "#.GetInput(@)".}
proc getInputValue*(self; name: cstring): float {.importcpp: "#.GetInputValue(@)".}
proc getInputValueAsInt*(self; name: cstring): int {.importcpp: "#.GetInputValueAsInt(@)".}
proc execute*(self): bool {.importcpp: "#.Execute(@)".}

proc `[]`*(self; name: cstring): Input {.inline.} = getInput(self, name)
proc `[]`*(self; name: cstring, T: typedesc[float]): T {.inline.} = getInputValue(self, name)
proc `[]`*(self; name: cstring; T: typedesc[int]): T {.inline.} = getInputValueAsInt(self, name)

proc free*(self: Region | Sound | Editor | Input | ScriptDialog) {.importcpp: "#.Free()".}

template `+`*(init: string | cstring, second: untyped): untyped =
  bind toJs, to
  to(toJs(cstring(init)) + toJs(second), cstring)

proc `%`*[T](a, b: T): T {.importcpp: "# % #".}