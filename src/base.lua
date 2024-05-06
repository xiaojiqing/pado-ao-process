NODE_PROCESS_ID = "lsVh9GO7pzFXcFEuAfw7l_9WU7KAAqTRkU0kVH0lx2g"
DATA_PROCESS_ID = "daYyE-QRXg2MBrX1E1lUmJ1hMR-GEmyrdUiUnv3dWLY"
 
function replyError(request, errmsg)
  local action = request.Action .. "-Error"
  ao.send({Target = request.From, Action = action, ["Message-Id"] = request.Id, Error = errmsg})
end

function replySuccess(request, data)
  local action = request.Action .. "-Success"
  ao.send({Target = request.From, Action = action, ["Message-Id"] = request.Id, Data = data})
end

