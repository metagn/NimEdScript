import ../src/nimedscript

proc amp(value: float) =
  var x1, x2 = 0
  discard editor.getSelectionInSamples(x1, x2)

  for n in x1..x2:
    let x = n - x1
    if x % 10000 == 0:
      progressMsg("Processing", x, x2 - x1)
    eachChannel(editorSample):
      samples[n] = Sample(samples[n].float * value)

let form = createScriptDialog("Amp", "Simple amplification.")
try:
  let volume = form.addInputKnob("Volume", 1, 0, 2)
  if form.execute():
    amp(volume.value)
finally:
  form.free()