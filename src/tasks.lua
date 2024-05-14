CompletedTasks = CompletedTasks or {}
PendingTasks = PendingTasks or {}
FreeAllowances = FreeAllowances or {}
LockedAllowances = LockedAllowances or {}

CreditNotice = CreditNotice or {}
DebitNotice = DebitNotice or {}

DebitActions = DebitActions or {}
-- (key, value) => (submitter, [taskKey])
UnfinishedTasks = UnfinishedTasks or {}

function removeUnfinishedTask(spender, taskKey)
  local index = indexOf(UnfinishedTasks[spender], taskKey)
  print("remove unfinished task " .. spender .. " " .. taskKey .. " " .. index)
  table.remove(UnfinishedTasks[spender], index)
  if #UnfinishedTasks[spender] == 0 then
    UnfinishedTasks[spender] = nil
  end
end

local bint = require('.bint')(256)

function getDebitActionKey(sender, recipient, quantity)
  return recipient
end

function GetInitialTaskKey(msg)
  return msg.Id
end

function getExistingTaskKey(msg)
  return msg.Tags.TaskId
end

function getTaskList(tasks)
  local result = {}
  for _, task in pairs(tasks) do
    table.insert(result, task)
  end
  return result
end

function convertToMap(list)
  local m = {}
  for index, item in ipairs(list) do
    m[item] = index
  end
  return m
end

function count(map)
  local num = 0
  for _, _ in pairs(map) do
    num = num + 1
  end
  return num
end

function calculateRequiredTokens(computeNodeCount, dataPrice)
  local computationCost = bint(COMPUTATION_PRICE)
  local totalCost = bint.__mul(computationCost, computeNodeCount)
  totalCost = tostring(bint.__add(totalCost, dataPrice))
  return totalCost
end

Handlers.add(
  "creditNotice",
  Handlers.utils.hasMatchingTag("Action", "Credit-Notice"),
  function (msg)
    local sender = msg.Sender
    local quantity = msg.Quantity

    local creditNotice = "Receive " .. quantity .. " tokens from " .. sender
    CreditNotice[sender] = CreditNotice[sender] or {}
    table.insert(CreditNotice[sender], creditNotice)

    FreeAllowances[sender] = FreeAllowances[sender] or "0"
    FreeAllowances[sender] = tostring(bint.__add(FreeAllowances[sender], quantity))
  end
)

Handlers.add(
  "debitNotice",
  Handlers.utils.hasMatchingTag("Action", "Debit-Notice"),
  function (msg)
    local recipient = msg.Recipient
    local quantity = msg.Quantity
    local debitActionKey = getDebitActionKey(ao.id, recipient, quantity)

    local debitNotice =  "Send " .. quantity .. " token to ".. recipient .. " " .. DebitActions[debitActionKey]
    DebitNotice[recipient] = DebitNotice[recipient] or {}
    table.insert(DebitNotice[recipient], debitNotice)
    
    -- print("report result " .. quantity .. " tokens")
    LockedAllowances[recipient] = tostring(bint.__sub(LockedAllowances[recipient], quantity))
  end
) 

Handlers.add(
  "allowance",
  Handlers.utils.hasMatchingTag("Action", "Allowance"),
  function (msg)
    local freeAllowance = "0"
    local lockedAllowance = "0"
    if FreeAllowances[msg.From] ~= nil then
      freeAllowance = FreeAllowances[msg.From]
    end

    if LockedAllowances[msg.From] ~= nil then
      lockedAllowance = LockedAllowances[msg.From]
    end

    local allowance = {free = freeAllowance, locked = lockedAllowance}
    replySuccess(msg, allowance)
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

    if FreeAllowances[msg.From] == nil then
      replyError(msg, "Please transfer sufficient token to " .. ao.id)
      return
    end
    local computeNodes = require("json").decode(msg.Tags.ComputeNodes)
    local computeNodeCount = #computeNodes

    local taskKey = GetInitialTaskKey(msg)
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
    PendingTasks[taskKey].msg = msg

    UnfinishedTasks[msg.From] = UnfinishedTasks[msg.From] or {}
    table.insert(UnfinishedTasks[msg.From], taskKey)

    ao.send({Target = NODE_PROCESS_ID, Tags = {Action = "GetComputeNodes", ComputeNodes = msg.Tags.ComputeNodes, UserData = taskKey}}) 
    ao.send({Target = DATA_PROCESS_ID, Tags = {Action = "GetDataById", DataId = msg.Tags.DataId, UserData = taskKey}})

    replySuccess(msg, taskKey)
  end
)

Handlers.add(
  "getComputeNodesSuccess",
  Handlers.utils.hasMatchingTag("Action", "GetComputeNodes-Success"),
  function (msg)
    local dataMap = require("json").decode(msg.Data)
    local dataMap2 = require("json").decode(msg.Data)
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
      FreeAllowances[spender] = FreeAllowances[spender] or "0"
      if bint.__le(theTask.requiredTokens, FreeAllowances[spender]) then
        FreeAllowances[spender] = tostring(bint.__sub(FreeAllowances[spender], theTask.requiredTokens))
        LockedAllowances[spender] = LockedAllowances[spender] or "0"
        LockedAllowances[spender] = tostring(bint.__add(LockedAllowances[spender], theTask.requiredTokens))

        PendingTasks[taskKey].msg = nil
        replySuccess(originMsg, "submit success")
      else
        local verificationError = "Insufficient Balance"
        PendingTasks[taskKey].verificationError = verificationError
        PendingTasks[taskKey].msg = nil
        CompletedTasks[taskKey] = PendingTasks[taskKey]
        PendingTasks[taskKey] = nil
        removeUnfinishedTask(spender, taskKey)

        replyError(originMsg, verificationError)
      end
    end
  end
)

Handlers.add(
  "getComputeNodesError",
  Handlers.utils.hasMatchingTag("Action", "GetComputeNodes-Error"),
  function (msg)
    local errorMap = require("json").decode(msg.Tags.Error)
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
      removeUnfinishedTask(spender, taskKey)

      replyError(originMsg, verificationError)
    end
  end
)

Handlers.add(
  "getDataByIdSuccess",
  Handlers.utils.hasMatchingTag("Action", "GetDataById-Success"),
  function (msg)
    local dataMap = require("json").decode(msg.Data)
    local taskKey = dataMap.userData
    local data = dataMap.data
    local dataPrice = require("json").decode(data.price)
    local originMsg = PendingTasks[taskKey].msg
    local computeNodeCount = PendingTasks[taskKey].computeNodeCount
    local spender = PendingTasks[taskKey].from

    PendingTasks[taskKey].dataPrice = dataPrice.price
    PendingTasks[taskKey].priceSymbol = dataPrice.symbol
    PendingTasks[taskKey].requiredTokens = calculateRequiredTokens(computeNodeCount, dataPrice.price)
    PendingTasks[taskKey].dataVerified = true
    PendingTasks[taskKey].dataProvider = data.from

    local theTask = PendingTasks[taskKey]
    if theTask.nodeVerified and theTask.dataVerified then
      FreeAllowances[spender] = FreeAllowances[spender] or "0"
      if bint.__le(theTask.requiredTokens, FreeAllowances[spender]) then
        FreeAllowances[spender] = tostring(bint.__sub(FreeAllowances[spender], theTask.requiredTokens))
        LockedAllowances[spender] = LockedAllowances[spender] or "0"
        LockedAllowances[spender] = tostring(bint.__add(LockedAllowances[spender], theTask.requiredTokens))

        PendingTasks[taskKey].msg = nil
        replySuccess(originMsg, "submit success")
      else
        local verificationError = "Insufficient Balance"
        PendingTasks[taskKey].verificationError = verificationError
        PendingTasks[taskKey].msg = nil
        CompletedTasks[taskKey] = PendingTasks[taskKey]
        PendingTasks[taskKey] = nil
        removeUnfinishedTask(spender, taskKey)

        replyError(originMsg, verificationError)
      end
    end
  end
)

Handlers.add(
  "getDataByIdError",
  Handlers.utils.hasMatchingTag("Action", "GetDataById-Error"),
  function (msg)
    local errorMap = require("json").decode(msg.Tags.Error)
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
      removeUnfinishedTask(spender, taskKey)

      replyError(originMsg, verificationError)
    end
  end
)
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
    PendingTasks[taskKey].computeNodeMap[msg.Tags.NodeName] = nil
    local notReportedCount =  count(PendingTasks[taskKey].computeNodeMap)
    if notReportedCount == 0 then
      local theTask = PendingTasks[taskKey]
      for _, recipient in pairs(theTask.tokenRecipients) do
          local debitActionKey = getDebitActionKey(ao.id, recipient, tostring(COMPUTATION_PRICE))
          DebitActions[debitActionKey] = "ReportResult" 
          ao.send({Target = TOKEN_PROCESS_ID, Tags = {Action = "Transfer", Recipient = recipient, Quantity = tostring(COMPUTATION_PRICE)}})
      end

      local debitActionKey = getDebitActionKey(ao.id, theTask.dataProvider, tostring(theTask.dataPrice))
      DebitActions[debitActionKey] = "ReportResult" 
      ao.send({Target = TOKEN_PROCESS_ID, Tags = {Action = "Transfer", Recipient = theTask.dataProvider, Quantity = tostring(theTask.dataPrice)}})
      CompletedTasks[taskKey] = PendingTasks[taskKey]
      CompletedTasks[taskKey].computeNodeMap = nil
      PendingTasks[taskKey] = nil
      removeUnfinishedTask(theTask.from, taskKey)
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
    replySuccess(msg, CompletedTasks)
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
