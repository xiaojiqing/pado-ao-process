NODE_PROCESS_ID = "Vlq4jWP6PLRo0Msjnxp8-vg9HalZv9e8tiz13OTK3gk"
DATA_PROCESS_ID = "daYyE-QRXg2MBrX1E1lUmJ1hMR-GEmyrdUiUnv3dWLY"
 
function replyError(request, errmsg)
  local action = request.Action .. "-Error"
  ao.send({Target = request.From, Action = action, ["Message-Id"] = request.Id, Error = errmsg})
end

function replySuccess(request, data)
  local action = request.Action .. "-Success"
  ao.send({Target = request.From, Action = action, ["Message-Id"] = request.Id, Data = data})
end

