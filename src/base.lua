function indexOf(list, item)
  for index, value in ipairs(list) do
    if value == item then
      return index
    end
  end
  return nil
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
  --print("Action: " .. action .. " Error:" .. errstring)
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
  --print("Action:" .. action .. " Data:" .. datastring)
  ao.send({Target = request.From, Action = action, ["Message-Id"] = request.Id, Data = datastring})
end

