NODE_PROCESS_ID = NODE_PROCESS_ID or "Vlq4jWP6PLRo0Msjnxp8-vg9HalZv9e8tiz13OTK3gk"
DATA_PROCESS_ID = DATA_PROCESS_ID or "daYyE-QRXg2MBrX1E1lUmJ1hMR-GEmyrdUiUnv3dWLY"
TOKEN_PROCESS_ID = TOKEN_PROCESS_ID or "daYyE-QRXg2MBrX1E1lUmJ1hMR-GEmyrdUiUnv3dWLY"
TOKEN_FOR_COMPUTATION = 2
 
function setProcessID(nodeProcessId, dataProcessId, tokenProcessId)
  NODE_PROCESS_ID = nodeProcessId
  DATA_PROCESS_ID = dataProcessId
  TOKEN_PROCESS_ID = tokenProcessId
end

function setNodeProcess(nodeProcessId)
  NODE_PROCESS_ID = nodeProcessId
end

function setDataProcess(dataProcessId)
  DATA_PROCESS_ID = dataProcessId
end

function setTokenProcess(tokenProcessId)
  TOKEN_PROCESS_ID = tokenProcessId
end

function replyError(request, errmsg)
  local action = request.Action .. "-Error"
  local errstring = errmsg
  if request.Tags.UserData ~= nil then
    local errorMap = { userData = request.Tags.UserData, errorMsg = errmsg}
    errstring = require("json").encode(errorMap)
  elseif type(errmsg) ~= "string" then
    errstring = require("json").encode(errmsg)
  end 
  print("Action: " .. action .. " Error:" .. errstring)
  ao.send({Target = request.From, Action = action, ["Message-Id"] = request.Id, Error = errstring})
end

function replySuccess(request, data)
  local action = request.Action .. "-Success"
  local datastring = data
  if request.Tags.UserData ~= nil then
    local dataMap = {userData = request.Tags.UserData, data = data}
    datastring = require("json").encode(dataMap)
  elseif type(data) ~= "string" then
    datastring = require("json").encode(data)
  end
  print("Action:" .. action .. " Data:" .. datastring)
  ao.send({Target = request.From, Action = action, ["Message-Id"] = request.Id, Data = datastring})
end

