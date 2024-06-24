AllData = AllData or {}
PendingData = PendingData or {}
PriceSymbols = PriceSymbols or {}

local json = require("json")

function initDataRegistryEnvironment()
  if indexOf(PriceSymbols, "AOCRED") == 0 then
    table.insert(PriceSymbols, "AOCRED")
  end

  if indexOf(PriceSymbols, "wAR") == 0 then
    table.insert(PriceSymbols, "wAR")
  end
end

function isPriceSymbolSupported(symbol)
  return indexOf(PriceSymbols, symbol) > 0
end

initDataRegistryEnvironment()

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
    else
      local dataPrice = json.decode(msg.Tags.Price)
      if dataPrice.price == nil then
        replyError(msg, "price is missing")
        return
      elseif dataPrice.symbol == nil then
        replyError(msg, "symbol is missing")
        return
      elseif not isPriceSymbolSupported(dataPrice.symbol) then
        replyError(msg, "incorrect price symbol")
        return
      end
    end

    local dataKey = getInitialDataKey(msg)
    if AllData[dataKey] ~= nil then
      replyError(msg, "already registered")
      return
    end

    local policy = json.decode(msg.Data).policy
    local computeNodes = policy.names
    local indices = policy.indices
    if #computeNodes ~= #indices then
      replyError(msg, "the length of names and indices in policy is inconsistent")
      return
    end

    PendingData[dataKey] = {}
    PendingData[dataKey].id = msg.Id
    PendingData[dataKey].dataTag = msg.Tags.DataTag
    PendingData[dataKey].price = msg.Tags.Price
    PendingData[dataKey].data = msg.Data
    PendingData[dataKey].from = msg.From
    PendingData[dataKey].computeNodes = computeNodes
    PendingData[dataKey].isValid = true
    PendingData[dataKey].registeredTimestamp = msg.Timestamp

    local computeNodeStr = json.encode(computeNodes)

    ao.send({Target = NODE_PROCESS_ID, Tags = {Action = "GetComputeNodes", ComputeNodes = computeNodeStr, UserData = dataKey}}) 
    replySuccess(msg, msg.Id)
  end
)

Handlers.add(
  "getComputeNodesSuccess",
  Handlers.utils.hasMatchingTag("Action", "GetComputeNodes-Success"),
  function (msg)
    local dataMap = json.decode(msg.Data)
    local dataKey = dataMap.userData
    AllData[dataKey] = PendingData[dataKey]
    PendingData[dataKey] = nil
  end
)

Handlers.add(
  "getComputeNodesError",
  Handlers.utils.hasMatchingTag("Action", "GetComputeNodes-Error"),
  function (msg)
    local errorMap = json.decode(msg.Tags.Error)
    local dataKey = errorMap.userData
    PendingData[dataKey] = nil
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
      replyError(msg, "can not find data by " .. dataKey)
      return
    end

    local data = AllData[dataKey]
    replySuccess(msg, data)
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
    local dataStatus = "Valid"

    if msg.Tags.DataStatus ~= nil then
      local msgDataStatus = msg.Tags.DataStatus
      if not (msgDataStatus == "Valid" or msgDataStatus == "Invalid" or msgDataStatus == "All") then
        replyError(msg, "DataStatus is incorrect")
        return
      end
      dataStatus = msgDataStatus
    end

    local allData = {}
    if dataStatus == "All" then
      for _, data in pairs(AllData) do
        table.insert(allData, data)
      end
    else
      local isValid = true
      if dataStatus == "Invalid" then
        isValid = false
      end

      for _, data in pairs(AllData) do
        if data.isValid == isValid then
          table.insert(allData, data)
        end
      end
    end
    replySuccess(msg, allData)
  end
)

Handlers.add(
  "deleteNodeNotice",
  Handlers.utils.hasMatchingTag("Action", "DeleteNodeNotice"),
  function(msg)
    local nodeName = msg.Tags.Name
    for nodeKey, data in pairs(AllData) do
      if data.isValid then
        if indexOf(data.computeNodes, nodeName) ~= 0 then
          AllData[nodeKey].isValid = false
        end
      end
    end
  end
)
