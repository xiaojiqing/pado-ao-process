AllData = AllData or {}

function getInitialDataKey(msg)
  return msg.Id
end

function getExistingDataKey(msg)
  return msg.DataId
end

Handlers.add(
  "register",
  Handlers.utils.hasMatchingTag("Action", "Register"),
  function (msg)
    if msg.DataTag == nil then
      Handlers.utils.reply("DataTag is required")(msg)
      return
    end

    if msg.Price == nil then
      Handlers.utils.reply("Price is required")(msg)
      return
    end

    if msg.Nonce == nil then
      Handlers.utils.reply("Nonce is required")(msg)
      return
    end

    if msg.EncMsg == nil then
      Handlers.utils.reply("EncMsg is required")(msg)
      return
    end

    local dataKey = getInitialDataKey(msg)
    if AllData[dataKey] ~= nil then
      Handlers.utils.reply("already registered")(msg)
      return
    end

    AllData[dataKey] = {}
    AllData[dataKey].id = msg.Id
    AllData[dataKey].dataTag = msg.DataTag
    AllData[dataKey].price = msg.Price
    AllData[dataKey].encSks = msg.Data
    AllData[dataKey].nonce = msg.Nonce
    AllData[dataKey].encMsg = msg.EncMsg
    AllData[dataKey].from = msg.From
    Handlers.utils.reply(msg.Id)(msg)
  end
)

Handlers.add(
  "getDataById",
  Handlers.utils.hasMatchingTag("Action", "GetDataById"),
  function (msg)
    if msg.DataId == nil then
      Handlers.utils.reply("DataId is required")(msg)
      return
    end

    local dataKey = getExistingDataKey(msg)
    if AllData[dataKey] == nil then
      Handlers.utils.reply("can not data by " .. dataKey)(msg)
      return
    end

    local data = AllData[dataKey]
    local encodedData = require("json").encode(data)
    Handlers.utils.reply(encodedData)(msg)
  end
)

Handlers.add(
  "delete",
  Handlers.utils.hasMatchingTag("Action", "Delete"),
  function (msg)
    if msg.DataId == nil then
      Handlers.utils.reply("DataId is required")(msg)
      return
    end

    local dataKey = getExistingDataKey(msg)
    if AllData[dataKey] == nil then
      Handlers.utils.reply("record " .. dataKey .. " not exist")(msg)
      return
    end

    if AllData[dataKey].from ~= msg.From then
      Handlers.utils.reply("forbiden to delete")(msg)
      return
    end

    AllData[dataKey] = nil
    Handlers.utils.reply("deleted")(msg)

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
    Send({ Target = msg.From, Data = require('json').encode(allData) }) 
  end
)
