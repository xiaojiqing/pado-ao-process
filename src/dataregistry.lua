AllData = AllData or {}

function getInitialDataKey(msg)
  return msg.Id
end

function getExistingDataKey(msg)
  return msg.Tags.DataId
end

Handlers.add(
  "register",
  Handlers.utils.hasMatchingTag("Action", "Register"),
  function (msg)
    if msg.Tags.DataTag == nil then
      replyError(msg, "DataTag is required")
      return
    end

    if msg.Tags.Price == nil then
      replyError(msg, "Price is required")
      return
    end

    if msg.Tags.Nonce == nil then
      replyError(msg, "Nonce is required")
      return
    end

    if msg.Tags.EncMsg == nil then
      replyError(msg, "EncMsg is required")
      return
    end

    local dataKey = getInitialDataKey(msg)
    if AllData[dataKey] ~= nil then
      replyError(msg, "already registered")
      return
    end

    AllData[dataKey] = {}
    AllData[dataKey].id = msg.Id
    AllData[dataKey].dataTag = msg.Tags.DataTag
    AllData[dataKey].price = msg.Tags.Price
    AllData[dataKey].encSks = msg.Data
    AllData[dataKey].nonce = msg.Tags.Nonce
    AllData[dataKey].encMsg = msg.Tags.EncMsg
    AllData[dataKey].from = msg.From
    replySuccess(msg, msg.Id)
  end
)

Handlers.add(
  "getDataById",
  Handlers.utils.hasMatchingTag("Action", "GetDataById"),
  function (msg)
    if msg.Tags.DataId == nil then
      replyError(msg, "DataId is required")
      return
    end

    local dataKey = getExistingDataKey(msg)
    if AllData[dataKey] == nil then
      replyError(msg, "can not data by " .. dataKey)
      return
    end

    local data = AllData[dataKey]
    local encodedData = require("json").encode(data)
    replySuccess(msg, encodedData)
  end
)

Handlers.add(
  "delete",
  Handlers.utils.hasMatchingTag("Action", "Delete"),
  function (msg)
    if msg.Tags.DataId == nil then
      replyError(msg, "DataId is required")
      return
    end

    local dataKey = getExistingDataKey(msg)
    if AllData[dataKey] == nil then
      replyError(msg, "record " .. dataKey .. " not exist")
      return
    end

    if AllData[dataKey].from ~= msg.From then
      replyError(msg, "forbiden to delete")
      return
    end

    AllData[dataKey] = nil
    replySuccess(msg, "deleted")

  end
)

Handlers.add(
  'allData',
  Handlers.utils.hasMatchingTag('Action', 'AllData'),
  function(msg)
    local allData = {}
    for _, data in pairs(AllData) do
      table.insert(allData, data)
    end
    local encoded_data = require('json').encode(allData)
    replySuccess(msg, encoded_data)
  end
)
