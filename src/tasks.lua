TOKEN_PROCESS_ID = TOKEN_PROCESS_ID or {}
COMPUTATION_PRICE = COMPUTATION_PRICE or {}
REPORT_TIMEOUT = REPORT_TIMEOUT or 60 * 1000

CompletedTasks = CompletedTasks or {}
PendingTasks = PendingTasks or {}
FreeAllowances = FreeAllowances or {}
LockedAllowances = LockedAllowances or {}

CreditNotice = CreditNotice or {}
DebitNotice = DebitNotice or {}
TransferErrorNotice = TransferErrorNotice or {}

function initTaskEnvironment()
  local aocred = "AOCRED"
  local war = "wAR"

  if TOKEN_PROCESS_ID[aocred] == nil then
    TOKEN_PROCESS_ID[aocred] = "Sa0iBLPNyJQrwpTTG-tWLQU-1QeUAJA73DdxGGiKoJc"
  end
  if TOKEN_PROCESS_ID[war] == nil then
    TOKEN_PROCESS_ID[war] = "xU9zFkq3X2ZQ6olwNVvr1vUWIjc3kXTWr7xKQD6dh10"
  end

  if COMPUTATION_PRICE[aocred] == nil then
    COMPUTATION_PRICE[aocred] = 1
  end
  if COMPUTATION_PRICE[war] == nil then
    COMPUTATION_PRICE[war] = 2000000
  end
end
function getPriceSymbolByProcess(processId)
  for symbol, process in pairs(TOKEN_PROCESS_ID) do
    if process == processId then
      return symbol
    end
  end
  return nil
end
function getTokenProcessId(priceSymbol)
  return TOKEN_PROCESS_ID[priceSymbol]
end

initTaskEnvironment()

local bint = require('.bint')(256)
local json = require("json")

function getInitialTaskKey(msg)
  return msg.Id
end

function getExistingTaskKey(msg)
  return msg.Tags.TaskId
end

function getAllowanceKey(address, priceSymbol)
  return address .. ":" .. priceSymbol
end

function getTaskList(tasks)
  local result = {}
  for _, task in pairs(tasks) do
    table.insert(result, task)
  end
  return result
end

function calculateRequiredTokens(computeNodeCount, dataPrice, priceSymbol)
  local computationCost = bint(COMPUTATION_PRICE[priceSymbol])
  local totalCost = bint.__mul(computationCost, computeNodeCount)
  totalCost = tostring(bint.__add(totalCost, dataPrice))
  return totalCost
end

function checkReportTimeout(now)
  for taskId, task in pairs(PendingTasks) do
    if task.nodeVerified and task.dataVerified then
      if now - task.startTimestamp > REPORT_TIMEOUT then
        if task.reportCount >= task.threshold then
          completeTask(taskId)
        else
          local allowanceKey = getAllowanceKey(task.from, task.priceSymbol)
          LockedAllowances[allowanceKey] = tostring(bint.__sub(LockedAllowances[allowanceKey], task.requiredTokens))
          FreeAllowances[allowanceKey] = tostring(bint.__add(FreeAllowances[allowanceKey], task.requiredTokens))
          
          local verificationError = "not enough compute nodes report result"
          PendingTasks[taskId].verificationError = verificationError
          PendingTasks[taskId].msg = nil
          CompletedTasks[taskId] = PendingTasks[taskId]
          PendingTasks[taskId] = nil
        end
      end
    end
  end
end

Handlers.add(
  "computationPrice",
  Handlers.utils.hasMatchingTag("Action", "ComputationPrice"),
  function (msg)
    if msg.Tags.PriceSymbol == nil then
      replyError(msg, "PriceSymbol is required")
      return
    elseif COMPUTATION_PRICE[msg.Tags.PriceSymbol] == nil then
      replyError(msg, msg.Tags.PriceSymbol .. " is not supported")
      return
    end
    replySuccess(msg, tostring(COMPUTATION_PRICE[msg.Tags.PriceSymbol]))
  end
)

Handlers.add(
  "reportTimeout",
  Handlers.utils.hasMatchingTag("Action", "ReportTimeout"),
  function (msg)
    replySuccess(msg, tostring(REPORT_TIMEOUT))
  end
)

Handlers.add(
  "CheckReportTimeout",
  Handlers.utils.hasMatchingTag("Action", "CheckReportTimeout"),
  function (msg)
    checkReportTimeout(msg.Timestamp)
    replySuccess(msg, "checked")
  end
)

Handlers.add(
  "creditNotice",
  Handlers.utils.hasMatchingTag("Action", "Credit-Notice"),
  function (msg)
    local priceSymbol = getPriceSymbolByProcess(msg.From)
    local sender = msg.Sender
    local allowanceKey = getAllowanceKey(sender, priceSymbol)
    local quantity = msg.Quantity

    local creditNotice = {}
    creditNotice["quantity"] = quantity
    creditNotice["timestamp"] = msg.Timestamp
    creditNotice["symbol"] = priceSymbol
    CreditNotice[sender] = CreditNotice[sender] or {}
    table.insert(CreditNotice[sender], creditNotice)

    FreeAllowances[allowanceKey] = FreeAllowances[allowanceKey] or "0"
    FreeAllowances[allowanceKey] = tostring(bint.__add(FreeAllowances[allowanceKey], quantity))
  end
)

Handlers.add(
  "debitNotice",
  Handlers.utils.hasMatchingTag("Action", "Debit-Notice"),
  function (msg)
    local priceSymbol = getPriceSymbolByProcess(msg.From)
    local recipient = msg.Recipient
    local quantity = msg.Quantity

    local debitNotice =  {}
    debitNotice["quantity"] = quantity
    debitNotice["timestamp"] = msg.Timestamp 
    debitNotice["symbol"] = priceSymbol
    DebitNotice[recipient] = DebitNotice[recipient] or {}
    table.insert(DebitNotice[recipient], debitNotice)
    
    -- print("report result " .. quantity .. " tokens")
  end
) 

Handlers.add(
  "notice",
  Handlers.utils.hasMatchingTag("Action", "Notice"),
  function (msg)
    local target = msg.From
    if msg.Address ~= nil then
      target = msg.Address
    end

    local notice = {}
    notice["credit"] = {}
    notice["debit"] = {}
    if CreditNotice[target] ~= nil then
      notice["credit"] = CreditNotice[target]
    end

    if DebitNotice[target] ~= nil then
      notice["debit"] = DebitNotice[target]
    end

    replySuccess(msg, notice)
  end
)

Handlers.add(
  "transferError",
  Handlers.utils.hasMatchingTag("Action", "Transfer-Error"),
  function (msg)
    table.insert(TransferErrorNotice, msg.Error)
  end
)

Handlers.add(
  "allowance",
  Handlers.utils.hasMatchingTag("Action", "Allowance"),
  function (msg)
    if msg.Tags.PriceSymbol == nil then
      replyError(msg, "PriceSymbol is required")
      return 
    end
    
    local allowanceKey = getAllowanceKey(msg.From, msg.Tags.PriceSymbol)

    local freeAllowance = "0"
    local lockedAllowance = "0"
    if FreeAllowances[allowanceKey] ~= nil then
      freeAllowance = FreeAllowances[allowanceKey]
    end

    if LockedAllowances[allowanceKey] ~= nil then
      lockedAllowance = LockedAllowances[allowanceKey]
    end

    local allowance = {free = freeAllowance, locked = lockedAllowance}
    replySuccess(msg, allowance)
  end
)

Handlers.add(
  "withdraw",
  Handlers.utils.hasMatchingTag("Action", "Withdraw"),
  function (msg)
    if msg.Tags.PriceSymbol == nil then
      replyError(msg, "PriceSymbol is required")
      return 
    end
    
    local allowanceKey = getAllowanceKey(msg.From, msg.Tags.PriceSymbol)

    if msg.Tags.Quantity == nil then
      replyError(msg, "Quantity is required")
      return
    end
    local tokenProcessId = getTokenProcessId(msg.Tags.PriceSymbol)

    local freeAllowance = FreeAllowances[allowanceKey] or "0"
    if bint.__le(msg.Tags.Quantity, freeAllowance) then
      FreeAllowances[allowanceKey] = tostring(bint.__sub(FreeAllowances[allowanceKey], msg.Tags.Quantity))
      ao.send({Target = tokenProcessId, Action = "Transfer", Recipient = msg.From, Quantity = msg.Tags.Quantity})
      replySuccess(msg, "withdraw " .. msg.Tags.Quantity .. " " .. msg.Tags.PriceSymbol .. " successfully")
    else
      replyError(msg, "insuffice free allowance")
    end
  end
)

Handlers.add(
  "submit",
  Handlers.utils.hasMatchingTag("Action", "Submit"),
  function (msg)
    if msg.Tags.TaskType == nil then
      replyError(msg, "TaskType is required")
      return
    end

    if msg.Tags.DataId == nil then
      replyError(msg, "DataId is required")
      return
    end

    if msg.Data == nil then
      replyError(msg, "Data is required")
      return
    end

    if msg.Tags.ComputeLimit == nil then
      replyError(msg, "ComputeLimit is required")
      return
    end

    if msg.Tags.MemoryLimit == nil then
      replyError(msg, "MemoryLimit is required")
      return
    end
    
    if msg.Tags.ComputeNodes == nil then
      replyError(msg, "ComputeNodes is required")
      return
    end

    -- if FreeAllowances[msg.From] == nil then
    --   replyError(msg, "Please transfer sufficient token to " .. ao.id)
    --   return
    -- end
    local computeNodes = json.decode(msg.Tags.ComputeNodes)
    local computeNodeCount = #computeNodes

    local taskKey = getInitialTaskKey(msg)
    PendingTasks[taskKey] = {}
    PendingTasks[taskKey].id = msg.Id
    PendingTasks[taskKey].type = msg.Tags.TaskType
    PendingTasks[taskKey].inputData = msg.Data
    PendingTasks[taskKey].computeLimit = msg.Tags.ComputeLimit
    PendingTasks[taskKey].memoryLimit = msg.Tags.MemoryLimit
    PendingTasks[taskKey].computeNodes = msg.Tags.ComputeNodes
    PendingTasks[taskKey].computeNodeCount = computeNodeCount
    PendingTasks[taskKey].from = msg.From
    PendingTasks[taskKey].nodeVerified = false
    PendingTasks[taskKey].dataVerified = false
    PendingTasks[taskKey].startTimestamp = msg.Timestamp
    PendingTasks[taskKey].reportCount = 0
    PendingTasks[taskKey].msg = msg

    ao.send({Target = NODE_PROCESS_ID, Tags = {Action = "GetComputeNodes", ComputeNodes = msg.Tags.ComputeNodes, UserData = taskKey}}) 
    ao.send({Target = DATA_PROCESS_ID, Tags = {Action = "GetDataById", DataId = msg.Tags.DataId, UserData = taskKey}})

    replySuccess(msg, taskKey)
    checkReportTimeout(msg.Timestamp)
  end
)

Handlers.add(
  "getComputeNodesSuccess",
  Handlers.utils.hasMatchingTag("Action", "GetComputeNodes-Success"),
  function (msg)
    local dataMap = json.decode(msg.Data)
    local dataMap2 = json.decode(msg.Data)
    local taskKey = dataMap.userData
    local computeNodeMap = dataMap.data
    local tokenRecipients = dataMap2.data

    local originMsg = PendingTasks[taskKey].msg
    local spender = PendingTasks[taskKey].from
    PendingTasks[taskKey].computeNodeMap = computeNodeMap
    PendingTasks[taskKey].tokenRecipients = tokenRecipients
    PendingTasks[taskKey].nodeVerified = true

    local theTask = PendingTasks[taskKey]
    if theTask.nodeVerified and theTask.dataVerified then
      local allowanceKey = getAllowanceKey(theTask.from, theTask.priceSymbol)
      FreeAllowances[allowanceKey] = FreeAllowances[allowanceKey] or "0"
      if bint.__le(theTask.requiredTokens, FreeAllowances[allowanceKey]) then
        FreeAllowances[allowanceKey] = tostring(bint.__sub(FreeAllowances[allowanceKey], theTask.requiredTokens))
        LockedAllowances[allowanceKey] = LockedAllowances[allowanceKey] or "0"
        LockedAllowances[allowanceKey] = tostring(bint.__add(LockedAllowances[allowanceKey], theTask.requiredTokens))

        PendingTasks[taskKey].msg = nil
        replySuccess(originMsg, "submit success")
      else
        local verificationError = "Insufficient Balance"
        PendingTasks[taskKey].verificationError = verificationError
        PendingTasks[taskKey].msg = nil
        CompletedTasks[taskKey] = PendingTasks[taskKey]
        PendingTasks[taskKey] = nil

        replyError(originMsg, verificationError)
      end
    end
  end
)

Handlers.add(
  "getComputeNodesError",
  Handlers.utils.hasMatchingTag("Action", "GetComputeNodes-Error"),
  function (msg)
    local errorMap = json.decode(msg.Tags.Error)
    local taskKey = errorMap.userData
    local errorMsg = errorMap.errorMsg
    if PendingTasks[taskKey] ~= nil then
      local originMsg = PendingTasks[taskKey].msg
      local verificationError = "Verify compute nodes error: " .. errorMsg
      PendingTasks[taskKey].verificationError = verificationError
      PendingTasks[taskKey].msg = nil
      CompletedTasks[taskKey] = PendingTasks[taskKey]
      local spender = PendingTasks[taskKey].from
      PendingTasks[taskKey] = nil

      replyError(originMsg, verificationError)
    end
  end
)

Handlers.add(
  "getDataByIdSuccess",
  Handlers.utils.hasMatchingTag("Action", "GetDataById-Success"),
  function (msg)
    local dataMap = json.decode(msg.Data)
    local taskKey = dataMap.userData
    local data = dataMap.data
    local dataPrice = json.decode(data.price)
    local policy = json.decode(data.data).policy
    local originMsg = PendingTasks[taskKey].msg
    local computeNodeCount = PendingTasks[taskKey].computeNodeCount
    local spender = PendingTasks[taskKey].from

    PendingTasks[taskKey].dataPrice = dataPrice.price
    PendingTasks[taskKey].priceSymbol = dataPrice.symbol
    PendingTasks[taskKey].requiredTokens = calculateRequiredTokens(computeNodeCount, dataPrice.price, dataPrice.symbol)
    PendingTasks[taskKey].dataVerified = true
    PendingTasks[taskKey].dataProvider = data.from
    PendingTasks[taskKey].threshold = policy.t

    local theTask = PendingTasks[taskKey]
    if theTask.nodeVerified and theTask.dataVerified then
      local allowanceKey = getAllowanceKey(theTask.from, theTask.priceSymbol)
      FreeAllowances[allowanceKey] = FreeAllowances[allowanceKey] or "0"
      if bint.__le(theTask.requiredTokens, FreeAllowances[allowanceKey]) then
        FreeAllowances[allowanceKey] = tostring(bint.__sub(FreeAllowances[allowanceKey], theTask.requiredTokens))
        LockedAllowances[allowanceKey] = LockedAllowances[allowanceKey] or "0"
        LockedAllowances[allowanceKey] = tostring(bint.__add(LockedAllowances[allowanceKey], theTask.requiredTokens))

        PendingTasks[taskKey].msg = nil
        replySuccess(originMsg, "submit success")
      else
        local verificationError = "Insufficient Balance"
        PendingTasks[taskKey].verificationError = verificationError
        PendingTasks[taskKey].msg = nil
        CompletedTasks[taskKey] = PendingTasks[taskKey]
        PendingTasks[taskKey] = nil

        replyError(originMsg, verificationError)
      end
    end
  end
)

Handlers.add(
  "getDataByIdError",
  Handlers.utils.hasMatchingTag("Action", "GetDataById-Error"),
  function (msg)
    local errorMap = json.decode(msg.Tags.Error)
    local taskKey = errorMap.userData
    local errorMsg = errorMap.errorMsg
    if PendingTasks[taskKey] ~= nil then
      local originMsg = PendingTasks[taskKey].msg
      local verificationError = "Verify data error: " .. errorMsg
      PendingTasks[taskKey].verificationError = verificationError
      PendingTasks[taskKey].msg = nil
      CompletedTasks[taskKey] = PendingTasks[taskKey]
      local spender = PendingTasks[taskKey].from
      PendingTasks[taskKey] = nil

      replyError(originMsg, verificationError)
    end
  end
)
function completeTask(taskKey)
  local theTask = PendingTasks[taskKey]
  local allowanceKey = getAllowanceKey(theTask.from, theTask.priceSymbol)
  local tokenProcessId = getTokenProcessId(theTask.priceSymbol)
  local transferedTokens = tostring(0)
  for nodeName, _ in pairs(theTask.result) do
      local recipient = theTask.tokenRecipients[nodeName]

      LockedAllowances[allowanceKey] = tostring(bint.__sub(LockedAllowances[allowanceKey], tostring(COMPUTATION_PRICE[theTask.priceSymbol])))
      ao.send({Target = tokenProcessId, Tags = {Action = "Transfer", Recipient = recipient, Quantity = tostring(COMPUTATION_PRICE[theTask.priceSymbol])}})
      transferedTokens = tostring(bint.__add(transferedTokens, tostring(COMPUTATION_PRICE[theTask.priceSymbol])))
  end

  LockedAllowances[allowanceKey] = tostring(bint.__sub(LockedAllowances[allowanceKey], tostring(theTask.dataPrice)))
  ao.send({Target = tokenProcessId, Tags = {Action = "Transfer", Recipient = theTask.dataProvider, Quantity = tostring(theTask.dataPrice)}})
  transferedTokens = tostring(bint.__add(transferedTokens, tostring(theTask.dataPrice)))

  if transferedTokens ~= theTask.requiredTokens then
    local returnedTokens = tostring(bint.__sub(theTask.requiredTokens, transferedTokens))
    LockedAllowances[allowanceKey] = tostring(bint.__sub(LockedAllowances[allowanceKey], returnedTokens))
    FreeAllowances[allowanceKey] = tostring(bint.__add(FreeAllowances[allowanceKey], returnedTokens))
  end

  local endTimestamp = 0
  for _, timestamp in pairs(theTask.reportedTimestamp) do
    if timestamp > endTimestamp then
      endTimestamp = timestamp
    end
  end

  CompletedTasks[taskKey] = PendingTasks[taskKey]
  CompletedTasks[taskKey].computeNodeMap = nil
  CompletedTasks[taskKey].transferedToken = transferedTokens
  CompletedTasks[taskKey].endTimestamp = endTimestamp
  PendingTasks[taskKey] = nil
end

Handlers.add(
  "getPendingTasks",
  Handlers.utils.hasMatchingTag("Action", "GetPendingTasks"),
  function (msg)
    local pendingTasks = {}
    for taskId, task in pairs(PendingTasks) do
      if task.nodeVerified and task.dataVerified then
        table.insert(pendingTasks, task)
      end
      --print(taskId .. " node:" .. tostring(task.nodeVerified) .. " data: " .. tostring(task.dataVerified))
    end
    replySuccess(msg, pendingTasks)
  end
)

Handlers.add(
  "reportResult",
  Handlers.utils.hasMatchingTag("Action", "ReportResult"),
  function (msg)
    if msg.Tags.TaskId == nil then
      replyError(msg, "TaskId is required")
      return
    end

    if msg.Tags.NodeName == nil then
      replyError(msg, "NodeName is required")
      return
    end

    if msg.Data == nil then
      replyError(msg, "Data is required")
      return
    end

    local taskKey = getExistingTaskKey(msg)
    local pendingTask = PendingTasks[taskKey]
    if pendingTask == nil then
      replyError(msg, "PendingTask " .. taskKey .. " not exist")
      return
    end

    local requiredFrom = pendingTask.computeNodeMap[msg.Tags.NodeName]
    if requiredFrom == nil then
      replyError(msg, "NodeName[" .. msg.Tags.NodeName .. "] not in ComputeNodes")
      return
    elseif requiredFrom ~= msg.From then
      replyError(msg, msg.Tags.NodeName .. " should reported by " .. requiredFrom)
      return
    end
    PendingTasks[taskKey].result = PendingTasks[taskKey].result or {}
    PendingTasks[taskKey].result[msg.Tags.NodeName] = msg.Data

    PendingTasks[taskKey].reportedTimestamp = PendingTasks[taskKey].reportedTimestamp or {}
    PendingTasks[taskKey].reportedTimestamp[msg.Tags.NodeName] = msg.Timestamp

    PendingTasks[taskKey].computeNodeMap[msg.Tags.NodeName] = nil
    PendingTasks[taskKey].reportCount = PendingTasks[taskKey].reportCount + 1
    if PendingTasks[taskKey].reportCount == PendingTasks[taskKey].computeNodeCount then
      completeTask(taskKey)
    end
    replySuccess(msg, taskKey)
  end
)

Handlers.add(
  "getCompletedTaskById",
  Handlers.utils.hasMatchingTag("Action", "GetCompletedTaskById"),
  function (msg)
    if msg.Tags.TaskId == nil then
      replyError(msg, "TaskId is required")
      return
    end

    local taskKey = getExistingTaskKey(msg)
    local task = CompletedTasks[taskKey]
    if task == nil then
      replyError(msg, "CompletedTask " .. taskKey .. " not exist")
      return
    end

    replySuccess(msg, task)
  end
)

Handlers.add(
  "getCompletedTasks",
  Handlers.utils.hasMatchingTag("Action", "GetCompletedTasks"),
  function (msg)
    replySuccess(msg, getTaskList(CompletedTasks))
  end
)

Handlers.add(
  "getAllTasks",
  Handlers.utils.hasMatchingTag("Action", "GetAllTasks"),
  function (msg)
    local allTasks = {}
    allTasks.pendingTasks = getTaskList(PendingTasks)
    allTasks.completedTasks = getTaskList(CompletedTasks)

    replySuccess(msg, allTasks)
  end
)
